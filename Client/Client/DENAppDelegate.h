//
//  DENAppDelegate.h
//  Client
//
//  Created by Denis Ogun on 26/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DENClient.h"

@interface DENAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DENClient *client;

@end
