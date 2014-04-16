//
//  DENClient.m
//  Mobile Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENClient.h"
#import "DENSensors.h"
#import "DENButtonManager.h"
#import "DENMediaManager.h"
#import "NSMutableArray+Queue.h"
#import "DENButtonViewController.h"

@import CoreMotion;
@import AudioToolbox;

@interface DENClient () <DENNetworkingProtocol>

// Socket details
@property (nonatomic, strong) NSString *username;
// Networking
@property (nonatomic, strong) DENNetworking *networkManager;
// Media and sensors
@property (nonatomic, strong) DENMediaManager *mediaManager;
@property (nonatomic, strong) DENSensors *sensorManager;

// States
@property BOOL handShaked;

@end

@implementation DENClient

#pragma mark - Initialization

+ (instancetype)sharedManager {
    static DENClient *staticInstance = nil;
    if (!staticInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            staticInstance = [[DENClient alloc] init];
        });
    }
    
    return staticInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _username = @"Guest_iOS";
        _handShaked = NO;

        _sensorManager = [DENSensors new];
        
        // Specify whether to use raw sockets, or GCDAsyncSocket
        _networkManager = [DENNetworking new];
        _networkManager.delegate = self;
        [_networkManager searchForServices];
        
        _connected = DISCONNECTED;

        _buttonManager = [DENButtonManager new];
        _mediaManager = [DENMediaManager new];
        _mediaManager.client = self;
        
        _xbmcQueue = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - Connection

- (void)connect
{
    [self.networkManager connect];
    self.connected = CONNECTING;
}

- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port
{
    [self.networkManager connectWithHost:host andPort:port];
}

- (void)didConnect
{
    self.connected = CONNECTED;
}

- (void)disconnect
{
    [self.networkManager disconnect];
}

- (void)willDisconnect
{
    self.handShaked = NO;
    self.connected = DISCONNECTED;
}

#pragma mark - Server event handling

- (void)didReadServerRequest:(NSInteger)requestType withData:(NSDictionary *)JSONData
{
    switch (requestType) {
        case NULL_REQUEST:
        {
            [self.networkManager writeData:[DENClient createErrorMessageForCode:INVALID_REQUEST_TYPE]];
            break;
        }
            
        case HANDSHAKE:
        {
            if (self.handShaked == NO) {
                [self completeHandshake];
            } else {
                [self.networkManager writeData:[DENClient createErrorMessageForCode:HANDSHAKE_AFTER_HANDSHAKE]];
            }
            break;
        }
            
        case GAME_DATA:
        {
            if (self.handShaked == NO) {
                [self.networkManager writeData:[DENClient createErrorMessageForCode:DATA_BEFORE_HANDSHAKE]];
            } else {
                [self sendGameDataForSensors:[JSONData objectForKey:@"Devices"]];
                if ([self.delegate respondsToSelector:@selector(shouldVibratePhone:)]) {
                    [self.delegate shouldVibratePhone:[[JSONData objectForKey:@"Vibrate"] unsignedIntegerValue]];
                }
                if ([self.delegate respondsToSelector:@selector(shouldSetBackground:)]) {
                    [self.delegate shouldSetBackground:[JSONData objectForKey:@"SetBackground"]];
                }
                if ([self.delegate respondsToSelector:@selector(shouldPlayMusic:)]) {
                    [self.delegate shouldPlayMusic:[JSONData objectForKey:@"PlaySound"]];
                }
            }
            break;
        }
            
        case DISCONNECT:
        {
            [self disconnect];
            break;
        }
            
        case GAME_START:
        {
            [self.buttonManager processGameData:[JSONData objectForKey:@"Buttons"]];
            [self.mediaManager processMediaData:[JSONData objectForKey:@"Media"]];
            break;
        }
            
        case GAME_END:
        {
            [self completeGameEnd];
            break;
        }
            
        case XBMC_START:
        {
            if (self.buttonViewController) {
                [self.buttonViewController loadXBMCViewController];
                [self completeXBMCStart];
            }
            break;
        }
            
        case XBMC_END:
        {
            [self.buttonViewController dismissXBMCViewController];
            [self completeXBMCEnd];
            break;
        }
            
        case XBMC_REQUEST:
        {
            [self sendXBMCRequest];
            break;
        }
            
        case PULSE:
        {
            [self completePulse];
            break;
        }
            
        default:
        {
            [self.networkManager writeData:[DENClient createErrorMessageForCode:INVALID_REQUEST_TYPE]];
        }
    }
}

- (void)startDownloadingFile:(NSString *)fileName withSize:(NSUInteger)size
{
    self.networkManager.downloadingFiles = YES;
    
    NSDictionary *response = @{@"Name": fileName};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game start");
    } else {
        [self.networkManager startDownloadingFile:data ofSize:size];
    }
}

- (void)completedDownloadingMedia
{
    self.networkManager.downloadingFiles = NO;
    [self.networkManager restartListening];
    [self completeGameStart];
}

- (void)didDownloadFile:(NSData *)file {
    [self.mediaManager downloadedFile:file];
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
        [self.networkManager writeData:data];
    }
}

- (void)completeHandshake
{
    NSDictionary *response = @{@"Response": @1, @"Username": self.username};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing handshake");
    } else {
        [self.networkManager writeData:data];
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
        [self.networkManager writeData:data];
    }
}

- (void)sendGameDataForSensors:(NSMutableArray *)sensors
{
    NSDictionary *response;
    NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
    NSError *error;

    for (NSInteger i=0; i < [sensors count]; i++) {
        NSInteger sensorValue = [[sensors objectAtIndex:i] integerValue];
        SensorType sensor = [DENSensors getSensorForID:sensorValue];
        NSDictionary *sensorData;
        if (sensor == BUTTONS) {
            sensorData = [self.buttonManager getButtonDataForID:sensorValue];
        } else {
            sensorData = [self.sensorManager getSensorDataForSensor:sensorValue];
        }
        [deviceDictionary setObject:sensorData forKey:[NSString stringWithFormat:@"%li", (long)sensorValue]];
    }
    
    response = @{@"Devices": deviceDictionary};
            
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Error creating JSON while sending data");
    } else {
        [self.networkManager writeData:data];
    }
}

- (void)completeXBMCStart
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game end");
    } else {
        [self.networkManager writeData:data];
    }
}

- (void)completeXBMCEnd
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game end");
    } else {
        [self.networkManager writeData:data];
    }
}

- (void)completePulse
{
    NSDictionary *response = @{@"Response": @1};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game end");
    } else {
        [self.networkManager writeData:data];
    }
}

- (void)sendXBMCRequest
{
    NSDictionary *response;
    
    if ([self.xbmcQueue isEmpty] == NO) {
        response = @{@"Event": [self.xbmcQueue dequeue]};
    } else {
        response = @{@"Event": [NSNumber numberWithInteger:NO_EVENT]};
    }
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"Error creating JSON while completing game end");
    } else {
        [self.networkManager writeData:data];
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

@end
