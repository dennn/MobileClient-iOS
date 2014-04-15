//
//  DENNetworking.h
//  Client
//
//  Created by Denis Ogun on 27/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkingType) {
    LibrarySocket,
    NativeSocket
};

typedef NS_ENUM(NSInteger, ConnectionState) {
    CONNECTED,
    DISCONNECTED,
    CONNECTING
};

@protocol DENNetworkingProtocol <NSObject>

- (void)didReadServerRequest:(NSInteger)requestType withData:(NSDictionary *)JSONData;
- (void)didDownloadFile:(NSData *)file;
- (void)willDisconnect;
- (void)didConnect;

@end

@interface DENNetworking : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

+ (instancetype)networkingControllerOfNetworkingType:(NetworkingType)type;

- (void)connect;
- (void)connectWithHost:(NSString *)host andPort:(uint16_t)port;
- (void)disconnect;
- (void)searchForServices;

- (void)writeData:(NSData *)data;
- (void)restartListening;
- (void)startDownloadingFile:(NSData *)file ofSize:(NSUInteger)size;

// Delegate
@property (nonatomic, weak) id <DENNetworkingProtocol> delegate;

@property (nonatomic, assign) BOOL downloadingFiles;

@end
