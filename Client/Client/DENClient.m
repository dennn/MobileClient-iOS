//
//  DENClient.m
//  Mobile Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENClient.h"
#import "DENSensors.h"
#import "NSMutableArray+Queue.h"

@import CoreMotion;

NS_ENUM(NSInteger, serverRequests) {
    NULL_REQUEST,
    HANDSHAKE,
    GAME_DATA,
    GAME_START,
    GAME_END,
    DISCONNECT_SERVER
};

typedef NS_ENUM(NSInteger, Error) {
    DESERIALIZATION_ERROR = 101,
    DATA_BEFORE_HANDSHAKE = 102,
    HANDSHAKE_AFTER_HANDSHAKE = 103,
    INVALID_REQUEST_TYPE = 104,
    INVALID_DEVICE_CODE = 105,
    DEVICE_UNAVAILABLE = 106
};

static NSString * const kBonjourService = @"_gpserver._tcp.";

@interface DENClient () <NSStreamDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

// NSStreams
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
// NSNetService
@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSNetService *serviceResolver;
// Socket details
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) UInt32 port;
@property (nonatomic, strong) DENSensors *sensorManager;

// States
@property BOOL handShaked;
@property (nonatomic, strong) NSMutableArray *queue;

@end

@implementation DENClient

- (instancetype)init
{
    if (self = [super init]) {
        _connected = DISCONNECTED;
        _host = @"192.168.0.7";
        _port = 8080;
        _handShaked = NO;
        _sensorManager = [DENSensors new];
        _queue = [NSMutableArray new];
        _serviceBrowser = [NSNetServiceBrowser new];
        _serviceBrowser.delegate = self;
        [_serviceBrowser searchForServicesOfType:kBonjourService inDomain:@"local"];
        _serviceResolver = [NSNetService new];
        _serviceResolver.delegate = self;
    }
    
    return self;
}

#pragma mark - Connection

- (void)connect
{
    if (self.connected == DISCONNECTED) {
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
        self.connected = CONNECTING;
    } else {
        NSLog(@"ERROR: Server is already connected, we should never reach here");
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
    self.handShaked = NO;
    [self.queue removeAllObjects];
    
    [self.inputStream close];
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.connected = DISCONNECTED;
}

#pragma mark - NSStream Delegate

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
            NSLog(@"Unhandled event");
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

#pragma mark - JSON Parsing and writing

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
                    [self processServerRequest:[requestType integerValue] withData:JSONOutput];
                }
            }
        }
    }
}

- (void)processServerRequest:(NSInteger)requestType withData:(NSDictionary *)JSONData
{
    switch (requestType) {
        case NULL_REQUEST:
        {
            [self writeToOutputStream:[DENClient createErrorMessageForCode:INVALID_REQUEST_TYPE]];
            break;
        }
            
        case HANDSHAKE:
        {
            if (self.handShaked == NO) {
                [self completeHandshake];
            } else {
                [self writeToOutputStream:[DENClient createErrorMessageForCode:HANDSHAKE_AFTER_HANDSHAKE]];
            }
            break;
        }
            
        case GAME_DATA:
        {
            if (self.handShaked == NO) {
                [self writeToOutputStream:[DENClient createErrorMessageForCode:DATA_BEFORE_HANDSHAKE]];
            } else {
                [self sendGameDataForSensors:[JSONData objectForKey:@"Devices"]];
            }
            break;
        }
            
        case DISCONNECT_SERVER:
        {
            [self disconnect];
            break;
        }
            
        case GAME_START:
        {
            //TODO: Implement the grid
            [self completeGameStart];
            break;
        }
            
        case GAME_END:
        {
            [self completeGameEnd];
            break;
        }
            
        default: {
            [self writeToOutputStream:[DENClient createErrorMessageForCode:INVALID_REQUEST_TYPE]];
        }
    }
}

#pragma mark - Server requests

- (void)completeGameStart
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game start");
    } else {
        [self writeToOutputStream:data];
    }
}

- (void)completeHandshake
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing handshake");
    } else {
        [self writeToOutputStream:data];
        self.handShaked = YES;
    }
}

- (void)completeGameEnd
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game end");
    } else {
        [self writeToOutputStream:data];
    }
}

- (void)sendGameDataForSensors:(NSMutableArray *)sensors
{
    NSDictionary *response;
    NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
    NSError *error;

    for (NSInteger i=0; i < [sensors count]; i++) {
        NSNumber *sensorValue = (NSNumber *)[sensors objectAtIndex:i];
        SensorType sensor = [DENSensors getSensorForID:[sensorValue integerValue]];
        NSDictionary *sensorData = [self.sensorManager getSensorDataForSensor:sensor];
        [deviceDictionary setObject:sensorData forKey:[NSString stringWithFormat:@"%li", sensor]];
    }
    
    response = @{@"Devices": deviceDictionary};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Error creating JSON while sending data");
    } else {
        [self writeToOutputStream:data];
    }
}

#pragma mark - Errors

//TODO: Look at using NSError instead, because its native blablabla...

/*
 * Return the JSON message as an NSData object so that we can send it along the stream
 * socket.
 */
+ (NSData *)createErrorMessageForCode:(Error)errorCode
{
    NSString *errorMessage = [DENClient getErrorMessageForCode:errorCode];
    NSLog(@"ERROR: %@", errorMessage);
    if (errorMessage == nil) {
        return nil;
    }
    
    NSDictionary *errorResponse = @{@"ErrorCode": @(errorCode),
                                    @"Error": errorMessage};
    NSError *error;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:errorResponse options:kNilOptions error:&error];

    if (error) {
        NSLog(@"Error creating JSON while creating error");
    } else {
        return data;
    }
    
    return nil;
}

/* 
 * Given an error code value, return a human readable description of it
 */
+ (NSString *)getErrorMessageForCode:(Error)errorCode
{
    switch (errorCode) {
        case DESERIALIZATION_ERROR:
            return @"Request could not be deserialized";
            
        case DATA_BEFORE_HANDSHAKE:
            return @"Data received before handshake";
            
        case HANDSHAKE_AFTER_HANDSHAKE:
            return @"Handshake received after handshake";
            
        case INVALID_DEVICE_CODE:
            return @"Invalid device code";
            
        case INVALID_REQUEST_TYPE:
            return @"Invalid request type";
            
        case DEVICE_UNAVAILABLE:
            return @"Device unavailable";
    }
    
    return nil;
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
    [self.serviceResolver stop];
    
    int count = 0;

    for (NSData *data in sender.addresses) {
        NSLog(@"Service name: %@ , ip: %@ , port %li", [sender name], [sender hostName], (long)[sender port]);
        if (count == 0){
            [self connectWithHost:[sender hostName] andPort:[sender port]];
            count++;
        }
    }
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

@end
