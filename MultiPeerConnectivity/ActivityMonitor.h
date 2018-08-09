//
//  ActivityMonitor.h
//  MultiPeerConnectivity
//
//  Created by Lemark on 10/28/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface ActivityMonitor : UIViewController <UITextViewDelegate,UIScrollViewDelegate>

- (void) logActivity:(NSString*) log;

@end
