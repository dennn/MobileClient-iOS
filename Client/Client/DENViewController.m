//
//  DENViewController.m
//  Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENViewController.h"
#import "DENClient.h"

@interface DENViewController ()

@property (nonatomic, strong) DENClient *client;
@property (nonatomic, strong) UIButton IBOutlet *connectButton;

@end

@implementation DENViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.client = [[DENClient alloc] init];
    
    NSString *connectLabel = [self.client connected] ? @"Disconnect" : @"Connect";
    [self.connectButton setTitle:connectLabel forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectToServer:(id)sender
{
    if ([self.client connected] == YES) {
        [self.client disconnect];
        [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    } else {
        [self.client connect];
        [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    }
}

@end
