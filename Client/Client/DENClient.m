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

@interface DENClient () <NSStreamDelegate>

// NSStreams
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
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
        self.connected = DISCONNECTED;
        self.host = @"192.168.0.7";
        self.port = 8080;
        self.handShaked = FALSE;
        self.sensorManager = [DENSensors new];
        self.queue = [NSMutableArray new];
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
                    NSLog(@"Error parsing JSON %@", [error debugDescription]);
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
            break;
            
        case HANDSHAKE:
        {
            if (self.handShaked == NO) {
                [self completeHandshake];
            } else {
                NSLog(@"Received duplicate handshake request, disconnecting for sanity");
                [self disconnect];
            }
            break;
        }
            
        case GAME_DATA:
        {
            [self sendGameDataForSensors:[JSONData objectForKey:@"Devices"]];
            break;
        }
            
        case DISCONNECT_SERVER:
        {
            [self disconnect];
            break;
        }
            
        default:
            NSLog(@"Unrecognized request type");
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
