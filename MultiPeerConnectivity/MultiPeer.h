//
//  MultiPeer.h
//  MultiPeerConnectivity
//
//  Created by Lemark on 10/31/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActivityMonitor.h"
@import MultipeerConnectivity;

@import UIKit;


@interface MultiPeer : UIViewController <UIAlertViewDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, UITextViewDelegate, UITextFieldDelegate, MCNearbyServiceAdvertiserDelegate>

@property (retain, strong) MCSession* mySession;


-(void) attachToMainActivityMonitor:(ActivityMonitor*) mainActivityMonitor;

@end
