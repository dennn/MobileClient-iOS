//
//  DENButtonViewController.h
//  Client
//
//  Created by Denis Ogun on 28/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DENClient.h"

@interface DENButtonViewController : UICollectionViewController <DENClientProtocol>

@property (nonatomic, strong) DENClient *client;

@end
