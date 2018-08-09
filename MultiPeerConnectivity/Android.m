//
//  Android.m
//  MultiPeerConnectivity
//
//  Created by Lemark on 11/2/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import "Android.h"
#import "AndroidNetworking.h"

@implementation Android
{
    ActivityMonitor* activityMonitor;
    
    AndroidNetworking* androidNetworking;
    
    UITextView* mainScreenView;
    
}

-(void) attachToMainActivityMonitor:(ActivityMonitor*) mainActivityMonitor
{
    activityMonitor = mainActivityMonitor;
    [activityMonitor logActivity:@"Android Attaching to Monitor - SUCCESS"];

}

/////////////////////////////////////////
// CLASS OVERRIDE METHODS

-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        activityMonitor = NULL;
        mainScreenView = NULL;
        androidNetworking = NULL;
        
        self.title = @"Android";
       
    //    NSFileManager* fileManager = [[NSFileManager alloc]init];
        
        NSString* filePath;
        filePath = @"tabicon-android-30.png";
    
        UITabBarItem* tabItem = [[UITabBarItem alloc] initWithTitle:@"Android" image:[UIImage imageNamed:filePath] tag:200];
      
        if(!tabItem.image)
            NSLog(@"Cannot load image for tab item");
       
        self.tabBarItem = tabItem;
    }
    
    return self;
}

-(void) loadView
{
    [super loadView];
    
    mainScreenView = [[UITextView alloc]init];
    mainScreenView.delegate = self;
    mainScreenView.frame = CGRectMake(0.0, 20.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-69);
    mainScreenView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:mainScreenView];
    
    
}



-(void) viewDidLoad
{
    
    [activityMonitor logActivity:@"Android loaded"];
    androidNetworking = [[AndroidNetworking alloc] initWithMonitor:activityMonitor];
   
    [androidNetworking createServer];
    [androidNetworking listenForConnections];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [super viewDidLoad];

}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

@end
