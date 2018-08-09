//
//  ActivityMonitor.m
//  MultiPeerConnectivity
//
//  Created by Lemark on 10/28/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import "ActivityMonitor.h"


@implementation ActivityMonitor
{
    
    UITabBarItem *barItem;
    UITextView *textView;
    BOOL logActivityActivated;
    int logActivityLineCount;
    NSString *logActivityLogs;

}

- (void) logActivity:(NSString*) log
{
    ++logActivityLineCount;
    
    if(!logActivityLogs)
    {
        logActivityLogs = @"";
        logActivityLogs = [logActivityLogs stringByAppendingString:[NSString stringWithFormat:@"[%i] %@\n",logActivityLineCount,log]];
    }else{
        
        logActivityLogs = [logActivityLogs stringByAppendingString:[NSString stringWithFormat:@"[%i] %@\n",logActivityLineCount,log]];
    }
    
    NSLog(@"%@",log);
    textView.text = logActivityLogs;

}

- (instancetype)init
{
    self = [super init];
    self.title = @"Monitor";
    
    logActivityActivated = NO;
    logActivityLineCount = 0;
    textView = [[UITextView alloc] init];
    NSString* filePath = @"tabicon-monitor-30.png";
    barItem = [[UITabBarItem alloc] initWithTitle:@"Monitor" image:[UIImage imageNamed:filePath] tag:1];

    return self;
}


- (void) viewDidLoad
{
    // Assign the TabBar icon for this view controller.
    self.tabBarItem = barItem;
   
    self.view.backgroundColor = [UIColor whiteColor];

    
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor greenColor];
    textView.delegate = self;
    textView.frame = CGRectMake(0.0,20.0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 49 - 20);
    textView.showsVerticalScrollIndicator = NO;
    textView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:textView];
    
    [self logActivity:@"Activity Monitor loaded."];
    
//    NSLog(@"ActMon frame width %f height %f\n",self.view.frame.size.width,self.view.frame.size.height);
//    NSLog(@"textView frame width %f height %f\n",textView.frame.size.width,textView.frame.size.height);
//    NSLog(@"Fontsize %f",textView.font.pointSize);
    
    
    // This just tells the scrollbar to scroll down to the bottom.
    // Otherwise, the default location of the scroll bar remains
    // at the top.
    [self scrollDown];

    [super viewDidLoad];
}

-(void) scrollDown
{
    NSRange stringRange = {stringRange.length = stringRange.location = [textView.text length]};
    [textView scrollRangeToVisible:stringRange];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollDown];
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    // This is a delegate method.
    // We don't want editing in the text view; we just want to
    // use it to hold our log messages.
    return NO;
}


@end
