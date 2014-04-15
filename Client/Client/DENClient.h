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

@interface DENClient : NSObject

// Connection methods
- (void)connect;
- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port;
- (void)disconnect;

// Media Downloading
- (void)completedDownloadingMedia;
- (void)startDownloadingFile:(NSString *)fileName;

+ (NSData *)createErrorMessageForCode:(Error)errorCode;

+ (id)sharedManager;

@property (nonatomic, assign) ConnectionState connected;
@property (nonatomic, strong) DENButtonManager *buttonManager;

@end
