//
//  DENClient.h
//  Mobile Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DENClient : NSObject

- (void)connect;
- (void)connectWithHost:(NSString*)host andPort:(uint16_t)port;
- (void)disconnect;

@property BOOL connected;


@end
