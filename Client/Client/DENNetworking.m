//
//  DENNetworking.m
//  Client
//
//  Created by Denis Ogun on 27/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENNetworking.h"
#import "DENClient.h"
#import "NSMutableArray+Queue.h"
#import <GCDAsyncSocket.h>

static NSString * const kBonjourService = @"_gpserver._tcp.";

@interface DENNetworkingNative : DENNetworking <NSStreamDelegate>

// NSStreams
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableArray *queue;

@end

@interface DENNetworkingGCDAsyncSocket : DENNetworking <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation DENNetworking

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type
{
    if (type == Library){
        return [[DENNetworkingGCDAsyncSocket alloc] init];
    } else if (type == Native) {
        return [[DENNetworkingNative alloc] init];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"No known networking type provided"];
    }
    
    return nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        _serviceBrowser = [NSNetServiceBrowser new];
        _serviceBrowser.delegate = self;
        _serviceResolver = [NSNetService new];
        _serviceResolver.delegate = self;
        _connected = DISCONNECTED;
    }
    
    return self;
}

- (void)searchForServices
{
    [self.serviceBrowser searchForServicesOfType:kBonjourService inDomain:@"local"];
}

#pragma mark - NSServiceBrowser Delegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"Starting search");
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"Stopped search");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"Found service %@, resolving..., more coming: %d", aNetService.name, moreComing);
    self.serviceResolver = aNetService;
    self.serviceResolver.delegate = self;
    [self.serviceResolver resolveWithTimeout:5.0];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"Did resolve");
    
    for (NSData *data in sender.addresses) {
        NSLog(@"Service name: %@ , ip: %@ , port %li", [sender name], [sender hostName], (long)[sender port]);
    }
    
    [self connectWithHost:[sender hostName] andPort:(uint32_t)[sender port]];
    [self.serviceResolver stop];
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog(@"Will resolve net service");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Error resolving net service");
    [self.serviceBrowser stop];
}

- (void)connect {}
- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port {}
- (void)disconnect {}
- (void)writeData:(NSData *)data {}

@end

@implementation DENNetworkingNative

- (instancetype)init
{
    if (self = [super init]) {
        self.queue = [NSMutableArray new];
    }
    
    return self;
}

- (void)connect
{
    self.connected = CONNECTING;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.host, self.port, &readStream, &writeStream);
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    self.inputStream.delegate = self;
    self.outputStream.delegate = self;
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
}

- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port
{
    self.host = host;
    self.port = port;
    [self connect];
}

- (void)disconnect
{
    if ([self.delegate respondsToSelector:@selector(willDisconnect)]) {
        [self.delegate willDisconnect];
    }
    
    [self.queue removeAllObjects];
    
    [self.inputStream close];
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.connected = DISCONNECTED;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            self.connected = CONNECTED;
            break;
        }
            
        case NSStreamEventEndEncountered:
        {
            [self disconnect];
            break;
        }
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Error occurred in stream %@", [[aStream streamError] localizedDescription]);
            [self disconnect];
            break;
            
        case NSStreamEventHasBytesAvailable:
        {
            if (aStream == self.inputStream) {
                [self handleDataRead];
            }
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        {
            if (aStream == self.outputStream) {
                if ([self.queue isEmpty] == NO) {
                    NSData *dataToSend = [self.queue dequeue];
                    [self writeData:dataToSend];
                }
            }
            break;
        }
            
        default:
        {
            NSLog(@"Unhandled event");
        }
    }
}

- (void)handleDataRead
{
    uint8_t buffer[1024];
    NSInteger len;
    
    NSMutableString *input = [[NSMutableString alloc] init];
    
    while ([self.inputStream hasBytesAvailable]) {
        len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
        if (len > 0) {
            [input appendString: [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding]];
            if (input != nil) {
                NSError *error;
                NSDictionary *JSONOutput = [NSJSONSerialization JSONObjectWithData:[input dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    [self writeData:[DENClient createErrorMessageForCode:DESERIALIZATION_ERROR]];
                } else {
                    NSNumber *requestType = [JSONOutput objectForKey:@"Request_type"];
                    if ([self.delegate respondsToSelector:@selector(didReadServerRequest:withData:)]) {
                        [self.delegate didReadServerRequest:[requestType integerValue] withData:JSONOutput];
                    }
                }
            }
        }
    }
}

- (void)writeData:(NSData *)data
{
    if ([self.outputStream hasSpaceAvailable]) {
        [self.outputStream write:[data bytes] maxLength:[data length]];
    } else {
        //We need to queue these operations when there is no space available.
        [self.queue enqueue:data];
    }
}

@end

@implementation DENNetworkingGCDAsyncSocket

- (instancetype)init
{
    if (self = [super init]) {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    return self;
}

- (void)connect
{
    NSError *err = nil;
    self.connected = CONNECTING;
    if (![self.socket connectToHost:self.host onPort:self.port error:&err]) {
        NSLog(@"Error connecting to host, %@", err);
        self.connected = DISCONNECTED;
    }
}

- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port
{
    self.host = host;
    self.port = port;
    [self connect];
}

- (void)disconnect
{
    if ([self.delegate respondsToSelector:@selector(willDisconnect)]) {
        [self.delegate willDisconnect];
    }
    
    self.connected = DISCONNECTED;
}

#pragma mark - GCDAsyncSocket

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    self.connected = CONNECTED;
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:2];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ([self.delegate respondsToSelector:@selector(willDisconnect)]) {
        [self.delegate willDisconnect];
    }
    
    self.connected = DISCONNECTED;
}

- (void)writeData:(NSData *)data
{
    [self.socket writeData:data withTimeout:-1 tag:1];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSError *error;
    NSDictionary *JSONOutput = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    NSLog(@"%@", JSONOutput);
    if (error) {
        [self writeData:[DENClient createErrorMessageForCode:DESERIALIZATION_ERROR]];
    } else {
        NSNumber *requestType = [JSONOutput objectForKey:@"Request_type"];
        if ([self.delegate respondsToSelector:@selector(didReadServerRequest:withData:)]) {
            [self.delegate didReadServerRequest:[requestType integerValue] withData:JSONOutput];
        }
    }
}


@end

