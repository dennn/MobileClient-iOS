//
//  DENButtonManager.m
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonManager.h"
#import "DENButtonCell.h"
#import "DENButton.h"

@interface DENButtonManager ()

@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, strong) NSMutableDictionary *buttons;

@end

@implementation DENButtonManager

- (instancetype)init {
    if (self = [super init]) {
        _buttons = [NSMutableDictionary new];
    }
    return self;
}

- (void)processGameData:(NSDictionary *)buttonData
{
    [buttonData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:@"Width"]) {
            self.columns = [obj integerValue];
        } else if ([key isEqualToString:@"Height"]) {
            self.rows = [obj integerValue];
        } else {
            NSNumber *buttonID = [NSNumber numberWithInteger:[key integerValue]];
            DENButton *newButton = [[DENButton alloc] initWithDictionary:obj andID:[buttonID integerValue]];
            [self.buttons setObject:newButton forKey:[newButton indexPathForRows:self.rows]];
        }
    }];
    
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self.buttons count] == 0) {
        NSLog(@"FUCK %@", self);
    }
    NSLog(@"Number buttons requested %lu %@", (unsigned long)[self.buttons count], self.buttons);
    return [self.buttons count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DENButtonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BUTTON_CELL" forIndexPath:indexPath];
    DENButton *button = [self.buttons objectForKey:indexPath];
    cell.cellTitle.text = button.title;
    
    return cell;
}

@end
