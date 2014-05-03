//
//  DENButtonFlowLayout.m
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonLayout.h"

const CGFloat kCellSpacing = 10.0f;

@interface DENButtonLayout ()

@property (nonatomic, strong) NSMutableArray *layout;

@end

@implementation DENButtonLayout

- (CGSize)collectionViewContentSize
{
    CGFloat width = self.collectionView.frame.size.width;
    CGFloat height = self.collectionView.frame.size.height;
    
    CGSize contentSize = CGSizeMake(width, height);
    
    return contentSize;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    if (self.layout) {
        [self.layout removeAllObjects];
    } else {
        self.layout = [NSMutableArray new];
    }
    
    CGFloat cellWidth = self.collectionViewContentSize.width / self.columns;
    CGFloat cellHeight = self.collectionViewContentSize.height / self.rows;
    
    for (int i = 0 ; i < (self.rows * self.columns); i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        int column = (i % self.columns);
        int row = (i/self.columns);
        
        attributes.frame = CGRectMake((column*cellWidth) , (row*cellHeight), cellWidth, cellHeight);
        
        [self.layout addObject:attributes];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.layout objectAtIndex:indexPath.row];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.layout;
}



@end
