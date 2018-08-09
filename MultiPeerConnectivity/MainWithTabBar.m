//
//  MainWithTabBar.m
//  MultiPeerConnectivity
//
//  Created by Lemark on 10/28/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import "MainWithTabBar.h"
#import "ActivityMonitor.h"
#import "MultiPeer.h"
#import "Android.h"
@implementation MainWithTabBar
{
    ActivityMonitor *activityMonitor;
    MultiPeer *multiPeer;
    Android *android;
    
    NSArray *barTabs;
}


- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{

    if(tabBarController.selectedViewController != viewController )
    [UIView transitionFromView:tabBarController.selectedViewController.view toView:viewController.view duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve completion:nil];

    return YES;
}

- (void)loadView
{
    [super loadView];
    self.delegate = self;
    
    activityMonitor = [[ActivityMonitor alloc]init];
    multiPeer = [[MultiPeer alloc]init];
    android = [[Android alloc]init];
    
    barTabs = [NSArray arrayWithObjects:activityMonitor,multiPeer,android, nil];
    
    [multiPeer attachToMainActivityMonitor:activityMonitor];
    [android attachToMainActivityMonitor:activityMonitor];
    
    [self setViewControllers:barTabs animated:YES];
    
    self.selectedViewController = multiPeer;
    self.selectedIndex = 0;
}


@end
