//
//  DENViewController.m
//  Client
//
//  Created by Denis Ogun on 22/12/2013.
//  Copyright (c) 2013 Mulan. All rights reserved.
//

#import "DENConnectionViewController.h"
#import "DENButtonViewController.h"

@interface DENConnectionViewController () <DENClientProtocol>

@property (nonatomic, weak) IBOutlet UIButton *connectButton;
@property (nonatomic, weak) IBOutlet UITextField *serverIP;
@property (nonatomic, weak) IBOutlet UITextField *serverPort;

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.client addObserver:self
                  forKeyPath:@"connected"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:nil];
    
    self.client.delegate = self;
    [self.client searchForServices];
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

- (IBAction)connectToServer:(id)sender
{
    switch (self.client.connected) {
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
                [self loadButtonViewController];
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

#pragma mark - View Controller Transition

- (void)loadButtonViewController
{
    [self performSegueWithIdentifier:@"loadButton" sender:self];
}

#pragma mark - Service picker

- (void)didFindServices:(NSMutableArray *)services
{
    [self.services addObjectsFromArray:services];
    
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
    NSNetService *service = [self.services objectAtIndex:indexPath.row];
    [self.client connectToService:service];
}




@end
