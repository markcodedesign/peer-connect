//
//  AndroidNetworking.h
//  MultiPeerConnectivity
//
//  Created by Lemark on 11/4/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActivityMonitor.h"

@interface AndroidNetworking : NSObject
{
}
-(instancetype) initWithMonitor:(ActivityMonitor*) monitor;
-(void) createServer;
-(void) listenForConnections;


@end
