//
//  DENClient.m
//  Mobile Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENClient.h"
#import "DENSensors.h"
@import CoreMotion;

NS_ENUM(NSInteger, serverRequests) {
    NULL_REQUEST,
    HANDSHAKE,
    GAME_DATA
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
@property BOOL connected;

- (void)completeHandshake;

@end

@implementation DENClient

- (instancetype)init
{
    if (self = [super init]) {
        self.connected = FALSE;
        self.host = @"192.168.0.7";
        self.port = 8080;
        self.handShaked = FALSE;
        self.sensorManager = [DENSensors new];
    }
    
    return self;
}

#pragma mark - Connection

- (void)connect
{
    if (self.connected == NO) {
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
    
    self.connected = NO;
}

- (BOOL)isConnected
{
    return self.connected;
}

#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"Stream opened");
            self.connected = YES;
            break;
        }
            
        case NSStreamEventEndEncountered:
        {
            NSLog(@"Stream ended");
            [self disconnect];
            break;
        }
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Couldn't connect to host");
            break;
            
        case NSStreamEventHasBytesAvailable:
        {
            if (aStream == self.inputStream) {
                [self handleDataRead];
            }
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
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
                    switch ([requestType integerValue]) {
                        case NULL_REQUEST:
                            break;
                            
                        case HANDSHAKE:
                        {
                            if (self.handShaked == NO) {
                                [self completeHandshake];
                            } else {
                                NSLog(@"Received duplicate handshake request, ignoring");
                            }
                            break;
                        }
                            
                        case GAME_DATA:
                        {
                            [self sendGameDataForSensors:[JSONOutput objectForKey:@"Devices"]];
                            break;
                        }
                            
                        default:
                            NSLog(@"Unrecognized request type");
                    }
                }
            }
        }
    }
}

- (void)completeHandshake
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    [self.outputStream write:[data bytes] maxLength:[data length]];
}

- (void)sendGameDataForSensors:(NSMutableArray *)sensors
{
    NSDictionary *response;
    NSMutableArray *deviceArray = [NSMutableArray new];
    NSError *error;

    for (NSInteger i=0; i < [sensors count]; i++) {
        NSLog(@"Received sensors: %@", sensors);
        NSNumber *sensorValue = (NSNumber *)[sensors objectAtIndex:i];
        SensorType sensor = [DENSensors getSensorForID:[sensorValue integerValue]];
        NSDictionary *sensorData = [self.sensorManager getSensorDataForSensor:sensor];
        [deviceArray addObject:sensorData];
    }
    
    response = @{@"Devices": deviceArray};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    [self.outputStream write:[data bytes] maxLength:[data length]];
}

@end
