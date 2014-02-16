//
//  NSMutableArray+Queue.h
//  Client
//
//  Created by Denis Ogun on 16/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)

- (NSData *)dequeue;
- (void)enqueue:(NSData *)obj;

- (BOOL)isEmpty;

@end
