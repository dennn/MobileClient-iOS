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

typedef NS_ENUM(NSInteger, ConnectionState) {
    CONNECTED,
    DISCONNECTED,
    CONNECTING
};

@protocol DENNetworkingProtocol <NSObject>

- (void)didReadServerRequest:(NSInteger)requestType withData:(NSDictionary *)JSONData;
- (void)willDisconnect;

@end

@interface DENNetworking : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type;

- (void)connect;
- (void)connectWithHost:(NSString *)host andPort:(uint32_t)port;
- (void)disconnect;
- (void)searchForServices;

- (void)writeData:(NSData *)data;

// Delegate
@property (nonatomic, weak) id <DENNetworkingProtocol> delegate;
// Socket state
@property (nonatomic) ConnectionState connected;
// Socket details
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) uint32_t port;
// NSNetService
@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSNetService *serviceResolver;


@end
