//
//  DENButton.h
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DENButton : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)data andID:(NSInteger)ID;
- (NSIndexPath *)indexPathForRows:(NSInteger)rows;
- (NSNumber *)getIDAsNumber;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;

@end
