//
//  NSMutableArray+Queue.m
//  Client
//
//  Created by Denis Ogun on 16/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (NSData *)dequeue
{
    if ([self count] == 0)
        return nil;
    
    NSData *objectToReturn = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];
    
    return objectToReturn;
}

- (void)enqueue:(NSData *)obj
{
    [self addObject:obj];
}

- (BOOL)isEmpty
{
    if ([self count] == 0)
    {
        return YES;
    } else {
        return NO;
    }
}
@end
