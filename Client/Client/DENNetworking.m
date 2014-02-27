//
//  DENNetworking.m
//  Client
//
//  Created by Denis Ogun on 27/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENNetworking.h"

@interface DENNetworkingNative : DENNetworking @end

@interface DENNetworkingGCDAsyncSocket : DENNetworking @end

@implementation DENNetworking

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type
{
    if (type == GCDAsyncSocket){
        return [[DENNetworkingGCDAsyncSocket alloc] init];
    } else if (type == Native) {
        return [[DENNetworkingNative alloc] init];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"No known networking type provided"];
    }
    
    return nil;
}

@end

@implementation DENNetworkingNative

@end

@implementation DENNetworkingGCDAsyncSocket

@end

