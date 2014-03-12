//
//  DENButtonViewController.m
//  Client
//
//  Created by Denis Ogun on 28/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonViewController.h"
#import "DENConnectionViewController.h"

@interface DENButtonViewController ()

@end

@implementation DENButtonViewController

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
    self.client = [DENClient sharedManager];
    self.collectionView.dataSource = self.client.buttonManager;
    self.client.buttonManager.collectionView = self.collectionView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.client addObserver:self   
                  forKeyPath:@"connected"
                     options: NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.client removeObserver:self forKeyPath:@"connected"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"connected"] && [object isKindOfClass:[DENClient class]]) {
        [self loadConnectionViewController];
    }
}

#pragma mark - View Controller Transition

- (void)loadConnectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
