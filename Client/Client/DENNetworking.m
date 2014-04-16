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

static const NSUInteger kFileDownloadTag = 63;
static NSString * const kBonjourService = @"_gpserver._tcp.";

@interface DENNetworking () <GCDAsyncSocketDelegate>

// Socket state
@property (nonatomic, assign) ConnectionState connected;
// Socket details
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) uint16_t port;
// NSNetService
@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSNetService *serviceResolver;

@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation DENNetworking

- (instancetype)init
{
    if (self = [super init]) {
        _serviceBrowser = [NSNetServiceBrowser new];
        _serviceBrowser.delegate = self;
        _serviceResolver = [NSNetService new];
        _serviceResolver.delegate = self;
        _connected = DISCONNECTED;
        _downloadingFiles = NO;
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
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
  //  if ([aNetService.name isEqualToString:@"GPServer (deniss-mbp)"] || [aNetService.name isEqualToString:@"GPServer (Deniss-MacBook-Pro.local)"]) {
        self.serviceResolver = aNetService;
        self.serviceResolver.delegate = self;
        [self.serviceResolver resolveWithTimeout:5.0];
  //  }
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{    
    NSLog(@"Service name: %@ , ip: %@ , port %li", [sender name], [sender hostName], (long)[sender port]);
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
    if ([self.delegate respondsToSelector:@selector(didConnect)]) {
        [self.delegate didConnect];
    }
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
    NSDictionary *JSONOutput = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"JSON request: %@", JSONOutput);
    [self.socket writeData:data withTimeout:-1 tag:1];
}

- (void)startDownloadingFile:(NSData *)file ofSize:(NSUInteger)size
{
    [self.socket writeData:file withTimeout:-1 tag:kFileDownloadTag];

    [self.socket readDataToLength:size withTimeout:-1 tag:kFileDownloadTag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == kFileDownloadTag && self.downloadingFiles) {
        if ([self.delegate respondsToSelector:@selector(didDownloadFile:)]) {
            NSLog(@"Downloaded file of size %lu", (unsigned long)[data length]);
            [self.delegate didDownloadFile:data];
        }
    } else if (self.downloadingFiles == NO) {
        NSError *error;
        NSDictionary *JSONOutput = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            [self writeData:[DENClient createErrorMessageForCode:DESERIALIZATION_ERROR]];
        } else {
            NSInteger requestType = [[JSONOutput objectForKey:@"Request_type"] integerValue];
            NSLog(@"%@", JSONOutput);
            if ([self.delegate respondsToSelector:@selector(didReadServerRequest:withData:)]) {
                [self.delegate didReadServerRequest:requestType withData:JSONOutput];
            }
            if (requestType != GAME_START) {
                [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:2];
            }
        }
    }
}

- (void)restartListening
{
    NSLog(@"Restarting listening");
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:2];
}


@end

