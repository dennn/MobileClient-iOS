//
//  DENButton.m
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButton.h"

@implementation DENButton

- (instancetype)initWithDictionary:(NSDictionary *)data andID:(NSInteger)ID
{
    if (self = [super init]) {
        _title = [data objectForKey:@"Title"];
        _x = [[data objectForKey:@"X"] integerValue];
        _y = [[data objectForKey:@"Y"] integerValue];
        _ID = ID;
    }
    
    return self;
}

- (NSIndexPath *)indexPathForColumns:(NSInteger)columns
{
    NSLog(@"Index path for x: %i y: %i = %i", self.x, self.y, (self.y * columns) + self.x);
    return [NSIndexPath indexPathForItem:((self.y * columns) + self.x) inSection:0];
}

- (NSNumber *)getIDAsNumber;
{
    return [NSNumber numberWithInteger:self.ID];
}

@end
