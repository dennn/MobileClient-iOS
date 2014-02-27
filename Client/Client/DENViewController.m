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
@property (nonatomic, weak) IBOutlet UIButton *connectButton;
@property (nonatomic, weak) IBOutlet UITextField *serverIP;
@property (nonatomic, weak) IBOutlet UITextField *serverPort;
@property (nonatomic, weak) IBOutlet UITextField *userName;

@end

@implementation DENViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.client = [[DENClient alloc] init];
    
    [self.client addObserver:self
                  forKeyPath:@"connected"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.client removeObserver:self forKeyPath:@"connected"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectToServer:(id)sender
{
    switch ([self.client isConnected]) {
        case CONNECTED:
            [self.client disconnect];
            break;
            
        case DISCONNECTED:
            if ([self.serverIP.text length] > 0) {
                [self.client connectWithHost:self.serverIP.text andPort:8080];
            } else {
                [self.client connect];
            }
            break;
            
        case CONNECTING:
            [self.client disconnect];
            break;
            
        default:
            NSLog(@"Unknown connection state");
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"connected"] && [object isKindOfClass:[DENClient class]]) {
        ConnectionState newState = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        
        switch (newState) {
            case CONNECTED:
                [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
                break;
                
            case DISCONNECTED:
                [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
                break;
                
            case CONNECTING:
                [self.connectButton setTitle:@"Connecting..." forState:UIControlStateNormal];
                break;
                
            default:
                NSLog(@"Unknown connection state");
        }
        
    }
}

@end
