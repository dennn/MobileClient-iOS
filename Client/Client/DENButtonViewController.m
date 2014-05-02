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

#import <SVProgressHUD.h>
#import <UIActionSheet+Blocks.h>

@import AudioToolbox;

@interface DENButtonViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureLeft;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRight;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureUp;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureDown;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureTwoFingersRight;

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
    self.client.delegate = self;
    self.collectionView.dataSource = self.client.buttonManager;
    self.client.buttonManager.collectionView = self.collectionView;
}

- (void)viewDidAppear:(BOOL)animated
{
    // Observe keys please
    [self.client addObserver:self   
                  forKeyPath:NSStringFromSelector(@selector(connected))
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    [self.client addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(waitingForGame))
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                     context:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.client removeObserver:self forKeyPath:NSStringFromSelector(@selector(connected))];
    [self.client removeObserver:self forKeyPath:NSStringFromSelector(@selector(waitingForGame))];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(connected))] && [object isKindOfClass:[DENClient class]]) {
        [self loadConnectionViewController];
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(waitingForGame))] && [object isKindOfClass:[DENClient class]]) {
        if (self.client.waitingForGame == YES) {
            [self addWaitingForGame];
        } else {
            [self removeWaitingForGame];
        }
    }
}

#pragma mark - Waiting For Game

- (void)addWaitingForGame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SVProgressHUD isVisible] == NO) {
            [self removeBackground];
            [SVProgressHUD showWithStatus:@"Waiting for game"];

        }
    });
}

- (void)removeWaitingForGame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

#pragma mark - View Controller Transition

- (void)loadConnectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadXBMCViewController
{
    self.gestureView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.gestureView.backgroundColor = [UIColor blackColor];
    
    UIImageView *dimensionsLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"controllerModeLogo"]];
    [dimensionsLogo setCenter:CGPointMake(self.gestureView.bounds.size.width/2, self.gestureView.bounds.origin.y + 100)];
    
    [self.gestureView addSubview:dimensionsLogo];
   
    UILabel *dimensionsLabel = [[UILabel alloc] init];
    dimensionsLabel.frame = CGRectMake(0, 0, 300, 100);
    dimensionsLabel.center = CGPointMake(self.gestureView.bounds.size.width/2, self.gestureView.bounds.origin.y + 250);
    dimensionsLabel.textColor = [UIColor colorWithRed:233.0f/255.0f green:233.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    dimensionsLabel.font = [UIFont fontWithName:@"MalayalamSangamMN" size:18.0];
    dimensionsLabel.text = @"DIMENSIONS MASTER MODE";
    dimensionsLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.gestureView addSubview:dimensionsLabel];
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(self.gestureView.bounds.size.width - 44, self.gestureView.bounds.size.height - 44, 44, 44);
    infoButton.tintColor = [UIColor whiteColor];
    [infoButton addTarget:self action:@selector(showHelpController) forControlEvents:UIControlEventTouchUpInside];
    
    [self.gestureView addSubview:infoButton];
    
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
    
    self.swipeGestureTwoFingersRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingersRight:)];
    self.swipeGestureTwoFingersRight.direction = UISwipeGestureRecognizerDirectionRight;
    self.swipeGestureTwoFingersRight.numberOfTouchesRequired = 2;
    [self.gestureView addGestureRecognizer:self.swipeGestureTwoFingersRight];
    
    [self.view addSubview:self.gestureView];
    [self.view bringSubviewToFront:self.gestureView];
}

- (void)dismissXBMCViewController
{
    [self.gestureView removeFromSuperview];
}

#pragma mark - Show Help Controller

- (void)showHelpController
{
    [self performSegueWithIdentifier:@"showHelp" sender:self];
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

- (void)handleTwoFingersRight:(UISwipeGestureRecognizer *)gestuire
{
    [self.client.xbmcQueue enqueue:[NSNumber numberWithInteger:BACK]];
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
    if (background) {
        UIImage *backgroundImage = [DENMediaManager getImageWithFileName:background];
                
        if (backgroundImage) {
            [UIView animateWithDuration:0.5f animations:^{
                self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
            }];
        }
    }
}

- (void)removeBackground
{
    self.collectionView.backgroundView.alpha = 0.0f;
    self.collectionView.backgroundColor = [UIColor blackColor];
}

- (void)isGameMaster
{
    // Add the button
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(self.view.bounds.size.width - 44, self.view.bounds.size.height - 44, 44, 44);
    infoButton.tintColor = [UIColor whiteColor];
    [infoButton addTarget:self action:@selector(showQuit) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:infoButton];
}

- (void)showQuit
{
    [UIActionSheet showInView:self.view
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:@"Quit game"
            otherButtonTitles:nil
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex == [actionSheet destructiveButtonIndex]) {
                             [self.client sendKillCommand];
                         }
                     }];
}

@end
