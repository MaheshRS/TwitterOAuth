//
//  ViewController.m
//  Twitter Sample
//
//  Created by Mahesh on 3/20/14.
//  Copyright (c) 2014 Mahesh. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Connect to Twitter
- (IBAction)connect:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    delegate.twitter = [Twitter twitter];
    typeof(self) __weak weakself = self;
    [delegate.twitter connect:^(BOOL success, NSDictionary *result) {
        if(success)
        {
            NSLog(@"I did Login!");
            [weakself getFriends];
        }
    }];
}

- (void)getFriends
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
   
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:delegate.twitter.user.screenName forKey:@"screen_name"];
    [dict setObject:@"-1" forKey:@"cursor"];
    [delegate.twitter getFriendsList:^(BOOL success, NSDictionary *result) {
        
    } withParameters:dict];
}


@end
