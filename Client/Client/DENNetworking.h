//
//  DENNetworking.h
//  Client
//
//  Created by Denis Ogun on 27/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkingType) {
    GCDAsyncSocket,
    Native
};

@interface DENNetworking : NSObject

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type;

@end
