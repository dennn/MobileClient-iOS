//
//  DENButtonManager.h
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Button_State) {
    RELEASED = 0,
    PRESSED = 1
};

@interface DENButtonManager : NSObject <UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

- (void)processGameData:(NSDictionary *)buttonData;
- (NSDictionary *)getButtonDataForID:(NSInteger)ID;

@end
