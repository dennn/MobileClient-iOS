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
@property (nonatomic, strong) NSMutableDictionary *pressedButtons;

@end

@implementation DENButtonManager

- (instancetype)init {
    if (self = [super init]) {
        _buttons = [NSMutableDictionary new];
        _pressedButtons = [NSMutableDictionary new];
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
            [self.pressedButtons setObject:[NSNumber numberWithInteger:RELEASED] forKey:buttonID];
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
    return 6;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DENButtonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BUTTON_CELL" forIndexPath:indexPath];
    DENButton *button = [self.buttons objectForKey:indexPath];
    [cell.cellButton setTitle:button.title forState:UIControlStateNormal];
    [cell.cellButton setTag:button.ID];
    [cell.cellButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
    [cell.cellButton addTarget:self action:@selector(buttonReleased:) forControlEvents:UIControlEventTouchUpInside];
    [cell setImagesForIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Button Sending

- (void)buttonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    [self.pressedButtons setObject:[NSNumber numberWithInteger:PRESSED] forKey:[NSNumber numberWithInteger:button.tag]];
}

- (void)buttonReleased:(id)sender
{
    UIButton *button = (UIButton *)sender;
    [self.pressedButtons setObject:[NSNumber numberWithInteger:RELEASED] forKey:[NSNumber numberWithInteger:button.tag]];
}

- (NSDictionary *)getButtonDataForID:(NSInteger)ID
{
    NSDictionary *stateDictionary = @{@"Status" : [self.pressedButtons objectForKey:[NSNumber numberWithInteger:ID]]};
    
    return stateDictionary;
}

@end
