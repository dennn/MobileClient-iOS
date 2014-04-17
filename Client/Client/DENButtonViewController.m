//
//  DENButtonViewController.m
//  Client
//
//  Created by Denis Ogun on 28/02/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENButtonViewController.h"
#import "DENConnectionViewController.h"
#import "DENMediaManager.h"
#import "NSMutableArray+Queue.h"

@import AudioToolbox;

@interface DENButtonViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureLeft;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRight;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureUp;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureDown;

@property (nonatomic, strong) UIView *gestureView;

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
    self.client.buttonViewController = self;
    self.collectionView.dataSource = self.client.buttonManager;
    self.client.buttonManager.collectionView = self.collectionView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.client addObserver:self   
                  forKeyPath:@"connected"
                     options: NSKeyValueObservingOptionNew
                     context:nil];
    
    self.client.delegate = self;
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

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
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

- (void)loadXBMCViewController
{
    self.gestureView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.gestureView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *xbmcLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"XBMC_Logo"]];
    [xbmcLogo setCenter:CGPointMake(self.gestureView.bounds.size.width/2, self.gestureView.bounds.size.height/2)];
    
    [self.gestureView addSubview:xbmcLogo];
    
    // Add tap
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tapGesture.numberOfTapsRequired = 1;
    [self.gestureView addGestureRecognizer:self.tapGesture];
    
    // Add swipes
    self.swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    self.swipeGestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.gestureView addGestureRecognizer:self.swipeGestureLeft];
    
    self.swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    self.swipeGestureRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.gestureView addGestureRecognizer:self.swipeGestureRight];
    
    self.swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    self.swipeGestureUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.gestureView addGestureRecognizer:self.swipeGestureUp];
    
    self.swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    self.swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.gestureView addGestureRecognizer:self.swipeGestureDown];
    
    [self.view addSubview:self.gestureView];
    [self.view bringSubviewToFront:self.gestureView];
}

- (void)dismissXBMCViewController
{
    [self.gestureView removeFromSuperview];
}

#pragma mark - Handle Gestures

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:TAP]];
}

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gesture
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:SWIPE_LEFT]];
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gesture
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:SWIPE_RIGHT]];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)gesture
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:SWIPE_DOWN]];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gesture
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:SWIPE_UP]];
}

#pragma mark - DENClientProtocol

- (void)shouldSetBackground:(NSString *)background
{
    UIImage *backgroundImage = [DENMediaManager getImageWithFileName:background];
    
    if (backgroundImage) {
        self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    }
}

@end
