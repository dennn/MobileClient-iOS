//
//  DENButtonCell.m
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonCell.h"

@import QuartzCore;

@implementation DENButtonCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setImagesForIndexPath:(NSIndexPath *)indexPath;
{
    self.cellButton.backgroundColor = [UIColor whiteColor];
    self.cellButton.titleLabel.textColor = [UIColor blackColor];
    
    /*// Normal Images
    NSArray *images = @[[UIImage imageNamed:@"button_dark_blue"], [UIImage imageNamed:@"button_green"], [UIImage imageNamed:@"button_light_blue"], [UIImage imageNamed:@"button_orange"], [UIImage imageNamed:@"button_red"], [UIImage imageNamed:@"button_yellow"]];
    
    // Pressed images
    NSArray *pressedImages = @[[UIImage imageNamed:@"button_dark_blue_pressed"], [UIImage imageNamed:@"button_green_pressed"], [UIImage imageNamed:@"button_light_blue_pressed"], [UIImage imageNamed:@"button_orange_pressed"], [UIImage imageNamed:@"button_red_pressed"], [UIImage imageNamed:@"button_yellow_pressed"]];
    
    unsigned long index = indexPath.item % images.count;
    
    [self.cellButton setBackgroundImage:images[index] forState:UIControlStateNormal];
    [self.cellButton setBackgroundImage:pressedImages[index] forState:UIControlStateHighlighted];*/
}

@end
