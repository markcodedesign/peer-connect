//
//  Android.h
//  MultiPeerConnectivity
//
//  Created by Lemark on 11/2/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActivityMonitor.h"

@import UIKit;

@interface Android : UIViewController <UITextViewDelegate>
-(void) attachToMainActivityMonitor:(ActivityMonitor*) mainActivityMonitor;
@end
