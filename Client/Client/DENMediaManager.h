//
//  DENMediaManager.h
//  Client
//
//  Created by Denis Ogun on 14/04/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DENClient;

@interface DENMediaManager : NSObject

- (void)processMediaData:(NSArray *)media;
- (void)downloadedFile:(NSData *)data;

+ (UIImage *)getImageWithFileName:(NSString *)fileName;
+ (NSURL *)getAudioFileWithFileName:(NSString *)fileName;

@property (nonatomic, weak) DENClient *client;

@end
