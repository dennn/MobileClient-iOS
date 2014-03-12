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

@import CoreMotion;
@import AudioToolbox;

NS_ENUM(NSInteger, serverRequests) {
    NULL_REQUEST,
    HANDSHAKE,
    GAME_DATA,
    GAME_START,
    GAME_END,
    DISCONNECT
};

@interface DENClient () <DENNetworkingProtocol>

// Socket details
@property (nonatomic, strong) DENSensors *sensorManager;
@property (nonatomic, strong) NSString *username;
//Networking
@property (nonatomic, strong) DENNetworking *networkManager;

// States
@property BOOL handShaked;

@end

@implementation DENClient

#pragma mark - Initialization

+ (id)sharedManager {
    static DENClient *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _username = @"Guest_iOS";
        _handShaked = NO;
        _sensorManager = [DENSensors new];
        // Specify whether to use raw sockets, or GCDAsyncSocket
        _networkManager = [DENNetworking networkingControllerOfNetworkingType:LibrarySocket];
        _networkManager.delegate = self;
        [_networkManager searchForServices];
        _connected = DISCONNECTED;
        _buttonManager = [DENButtonManager new];
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
                [DENClient vibratePhoneForDuration:[[JSONData objectForKey:@"Vibrate"] integerValue]];
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
            [self completeGameStart];
            break;
        }
            
        case GAME_END:
        {
            [self completeGameEnd];
            break;
        }
            
        default:
        {
            [self.networkManager writeData:[DENClient createErrorMessageForCode:INVALID_REQUEST_TYPE]];
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
        NSNumber *sensorValue = (NSNumber *)[sensors objectAtIndex:i];
        SensorType sensor = [DENSensors getSensorForID:[sensorValue integerValue]];
        NSDictionary *sensorData;
        if (sensor == BUTTONS) {
            sensorData = [self.buttonManager getButtonDataForID:sensor];
        } else {
            sensorData = [self.sensorManager getSensorDataForSensor:sensor];
        }
        [deviceDictionary setObject:sensorData forKey:[NSString stringWithFormat:@"%li", (long)[sensorValue integerValue]]];
    }
    
    response = @{@"Devices": deviceDictionary};
            
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Error creating JSON while sending data");
    } else {
        [self.networkManager writeData:data];
    }
}

+ (void)vibratePhoneForDuration:(NSInteger)duration
{
    //There's no way to change the duration of a vibration in iOS,
    //for now we should ignore the milliseconds and just play a single
    //vibration of duration 0.5s
    if (duration != 0) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
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
