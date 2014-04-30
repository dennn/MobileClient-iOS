//
//  DENClient.h
//  Mobile Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DENNetworking.h"
#import "DENButtonManager.h"

typedef NS_ENUM(NSInteger, Error) {
    DESERIALIZATION_ERROR = 101,
    DATA_BEFORE_HANDSHAKE = 102,
    HANDSHAKE_AFTER_HANDSHAKE = 103,
    INVALID_REQUEST_TYPE = 104,
    INVALID_DEVICE_CODE = 105,
    DEVICE_UNAVAILABLE = 106
};

NS_ENUM(NSInteger, serverRequests) {
    NULL_REQUEST,
    HANDSHAKE,
    GAME_DATA,
    GAME_START,
    GAME_END,
    DISCONNECT,
    XBMC_START,
    XBMC_END,
    XBMC_REQUEST,
    PULSE
};

NS_ENUM(NSInteger, xbmc) {
    NO_EVENT,
    TAP,
    SWIPE_LEFT,
    SWIPE_RIGHT,
    SWIPE_UP,
    SWIPE_DOWN,
    BACK
};

@protocol DENClientProtocol <NSObject>

@optional
- (void)shouldSetBackground:(NSString *)background;
- (void)didFindServices:(NSMutableArray *)services;
- (void)didFailToConnect;

@end

@class DENButtonViewController;

@interface DENClient : NSObject

// Connection methods
- (void)connect;
- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port;
- (void)disconnect;
- (void)connectToService:(NSNetService *)service;
- (void)searchForServices;

// Media Downloading
- (void)completedDownloadingMedia;
- (void)startDownloadingFile:(NSString *)fileName withSize:(NSUInteger)size;

+ (NSData *)createErrorMessageForCode:(Error)errorCode;

+ (id)sharedManager;
+ (BOOL)isOnCorrectWiFi;

@property (nonatomic, assign) ConnectionState connected;
@property (nonatomic, strong) DENButtonManager *buttonManager;

@property (nonatomic, weak) id <DENClientProtocol> delegate;
@property (nonatomic, strong) NSMutableArray *xbmcQueue;

@property (nonatomic, weak) DENButtonViewController *buttonViewController;

@end
