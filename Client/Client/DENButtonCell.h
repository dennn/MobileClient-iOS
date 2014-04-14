//
//  DENButtonCell.h
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DENButtonCell : UICollectionViewCell

- (void)setImagesForIndexPath:(NSIndexPath *)indexPath;

@property (weak, nonatomic) IBOutlet UIButton *cellButton;

@end
