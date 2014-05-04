//
//  DENButtonCell.m
//  Client
//
//  Created by Denis Ogun on 12/03/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonCell.h"
#import "UIImage+UIColor.h"

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
    
    [self.cellButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cellButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.cellButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.cellButton setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.cellButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:56.0f/255.0f green:58.0f/255.0f blue:63.0f/255.0f alpha:1.0f]] forState:UIControlStateHighlighted];
    
    self.cellButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.cellButton.layer.borderWidth = 2.0f;
    self.cellButton.layer.masksToBounds = YES;
    
    CGFloat inset = self.contentView.frame.size.width * 0.1f;
    
    self.cellButton.frame = CGRectInset(self.contentView.frame, inset, inset);
    
    CGRect newFrame;
    
    if (self.cellButton.frame.size.width <= self.cellButton.frame.size.height) {
        newFrame = self.cellButton.frame;
        newFrame.size.height = self.cellButton.frame.size.width;
    } else {
        newFrame = self.cellButton.frame;
        newFrame.size.width = self.cellButton.frame.size.height;
    }
    
    self.cellButton.frame = newFrame;
    self.cellButton.layer.cornerRadius = 15.0f;
    self.cellButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
    
    self.cellButton.center = CGPointMake(self.contentView.frame.size.width/2.0f, self.contentView.frame.size.height/2.0f);
    
    
}

@end
