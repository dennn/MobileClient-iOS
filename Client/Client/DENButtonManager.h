//
//  DENButtonManager.h
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DENButtonManager : NSObject <UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

- (void)processGameData:(NSDictionary *)buttonData;

@end
