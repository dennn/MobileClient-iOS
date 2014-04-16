//
//  DENNoWifiViewController.m
//  Client
//
//  Created by Denis Ogun on 16/04/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENNoWifiViewController.h"
#import "DENClient.h"

@interface DENNoWifiViewController ()

@end

@implementation DENNoWifiViewController

id thisClass;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    thisClass = self;
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    NULL, // observer
                                    onNotifyCallback, // callback
                                    CFSTR("com.apple.system.config.network_change"), // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

static void onNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSString* notifyName = (__bridge NSString*)name;
    // this check should really only be necessary if you reuse this one callback method
    //  for multiple Darwin notification events
    if ([notifyName isEqualToString:@"com.apple.system.config.network_change"]) {
        // use the Captive Network API to get more information at this point
        //  http://stackoverflow.com/a/4714842/119114
        if ([DENClient isOnCorrectWiFi] == YES) {
            [thisClass dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        NSLog(@"intercepted %@", notifyName);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
