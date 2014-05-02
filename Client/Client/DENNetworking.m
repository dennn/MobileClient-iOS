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
@property (nonatomic, strong) NSMutableArray *services;

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
        _services = [NSMutableArray new];
    }
    
    return self;
}

- (void)searchForServices
{
    [self.services removeAllObjects];
    [self.serviceBrowser searchForServicesOfType:kBonjourService inDomain:@"local"];
}

#pragma mark - NSServiceBrowser Delegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.services addObject:aNetService];

    if (moreComing == NO) {
        // Send a delegate method to update
        if ([self.delegate respondsToSelector:@selector(didFindServices:)]) {
            [self.delegate didFindServices:self.services];
        }
    }
}

- (void)connectToService:(NSNetService *)service
{
    self.serviceResolver = service;
    self.serviceResolver.delegate = self;
    [self.serviceResolver resolveWithTimeout:2.0];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{    
    [self connectWithHost:[sender hostName] andPort:(uint32_t)[sender port]];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
        [self.delegate didFailToConnect];
    }
    [self.serviceBrowser stop];
}

- (void)connect
{
    NSError *err = nil;
    
    self.connected = CONNECTING;
    [self.socket connectToHost:self.host onPort:self.port withTimeout:2.0 error:&err];
    if (err) {
        if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
            [self.delegate didFailToConnect];
        }
        self.connected = DISCONNECTED;
    } else {
        [self.serviceResolver stop];
        [self.serviceBrowser stop];
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
    if (err.domain == GCDAsyncSocketErrorDomain) {
        switch (err.code) {
            case GCDAsyncSocketConnectTimeoutError:
                if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
                    [self.delegate didFailToConnect];
                }
                break;
                
            case GCDAsyncSocketBadParamError:
                if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
                    [self.delegate didFailToConnect];
                }
                break;
                
            case GCDAsyncSocketBadConfigError:
                if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
                    [self.delegate didFailToConnect];
                }
                break;
                
            default:
                break;
        }
    } else if (err.domain == NSPOSIXErrorDomain) {
        if (err.code == 65) {
            if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
                [self.delegate didFailToConnect];
            }
        } else if (err.code == 61) {
            if ([self.delegate respondsToSelector:@selector(didFailToConnect)]) {
                [self.delegate didFailToConnect];
            }
        }
    }
    
    [self disconnect];
}

- (void)writeData:(NSData *)data
{
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
            [self.delegate didDownloadFile:data];
        }
    } else if (self.downloadingFiles == NO) {
        NSError *error;
        NSDictionary *JSONOutput = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            [self writeData:[DENClient createErrorMessageForCode:DESERIALIZATION_ERROR]];
        } else {
            NSInteger requestType = [[JSONOutput objectForKey:@"Request_type"] integerValue];
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
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:2];
}

@end