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
        _x = [[data objectForKey:@"x"] integerValue];
        _y = [[data objectForKey:@"y"] integerValue];
        _ID = ID;
    }
    
    return self;
}

- (NSIndexPath *)indexPathForRows:(NSInteger)rows
{
    return [NSIndexPath indexPathForItem:((self.y * rows) + self.x) inSection:0];
}

- (NSNumber *)getIDAsNumber;
{
    return [NSNumber numberWithInteger:self.ID];
}

@end
