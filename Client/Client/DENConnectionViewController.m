//
//  DENViewController.m
//  Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENConnectionViewController.h"
#import "DENButtonViewController.h"
#import "DENNSUserDefaults.h"

#import <UIAlertView+Blocks.h>

@interface DENConnectionViewController () <DENClientProtocol, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *services;

@end

@implementation DENConnectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.client = [DENClient sharedManager];
    self.client.delegate = self;
    self.services = [NSMutableArray new];
    
    // Add the toolbar
    self.navigationController.toolbarHidden = NO;
    UIBarButtonItem *connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Enter IP" style:UIBarButtonItemStylePlain target:self action:@selector(showEnterIP)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self setToolbarItems:@[space, connectButton]];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.client addObserver:self
                  forKeyPath:@"connected"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
    
    if ([DENClient isOnCorrectWiFi] == NO) {
        [self performSegueWithIdentifier:@"NoWifi" sender:self];
    } else {
        self.client.delegate = self;
        [self.client searchForServices];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.client removeObserver:self forKeyPath:@"connected"];
    
    [self.services removeAllObjects];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"connected"] && [object isKindOfClass:[DENClient class]]) {
        ConnectionState newState = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        
        if (newState == CONNECTED) {
            [self loadButtonViewController];
        }
    }
}

#pragma mark - View Controller Transition

- (void)loadButtonViewController
{
    [self performSegueWithIdentifier:@"loadButton" sender:self];
}

#pragma mark - Service picker

- (void)didFindServices:(NSMutableArray *)services
{
    self.services = services;
    [self.tableView reloadData];
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"serviceCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSNetService *service = [self.services objectAtIndex:indexPath.row];
    cell.textLabel.text = service.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (defaults.userName == nil) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Enter user name"
                                                     message:@"Please enter your in game display name"
                                                    delegate:nil
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil];
        
        av.alertViewStyle = UIAlertViewStylePlainTextInput;
        av.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                defaults.userName = [[alertView textFieldAtIndex:0] text];
                [defaults synchronize];
                NSNetService *service = [self.services objectAtIndex:indexPath.row];
                [self.client connectToService:service];
            }
        };
        
        [av show];
    } else {
        NSNetService *service = [self.services objectAtIndex:indexPath.row];
        [self.client connectToService:service];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Enter IP

- (void)showEnterIP
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Details"
                                                      message:@"Enter the IP address and port below"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Connect", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    UITextField *IP = [alert textFieldAtIndex:0];
    IP.placeholder = @"IP Address";
    IP.keyboardType = UIKeyboardTypeDecimalPad;
    
    UITextField *port = [alert textFieldAtIndex:1];
    port.placeholder = @"Port";
    port.secureTextEntry = NO;
    port.keyboardType = UIKeyboardTypeDecimalPad;
    
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *IP = [alertView textFieldAtIndex:0].text;
        NSString *port = [alertView textFieldAtIndex:1].text;
        [self.client connectWithHost:IP andPort:[port intValue]];
    }
}

- (void)didFailToConnect
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                    message:@"Couldn't connect to the server"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil, nil];
    
    [alert show];
}

@end
