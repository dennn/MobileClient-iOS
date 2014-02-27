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

static NSString * const kBonjourService = @"_gpserver._tcp.";

@interface DENNetworkingNative : DENNetworking <NSStreamDelegate>

// NSStreams
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableArray *queue;

@end

@interface DENNetworkingGCDAsyncSocket : DENNetworking @end

@implementation DENNetworking

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type
{
    if (type == GCDAsyncSocket){
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
- (void)connectWithHost:(NSString *)host andPort:(uint32_t)port {}
- (void)disconnect {}
- (void)writeData:(NSData *)data {}

@end

@implementation DENNetworkingNative

- (instancetype)init
{
    if (self = [super init]) {
        self.connected = DISCONNECTED;
        self.queue = [NSMutableArray new];
    }
    
    return self;
}

- (void)connect
{
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
                    [self writeToOutputStream:dataToSend];
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
                    [self writeToOutputStream:[DENClient createErrorMessageForCode:DESERIALIZATION_ERROR]];
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

- (void)writeToOutputStream:(NSData *)data
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

@end

