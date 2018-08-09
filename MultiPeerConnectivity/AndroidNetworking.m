//
//  AndroidNetworking.m
//  MultiPeerConnectivity
//
//  Created by Lemark on 11/4/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import "AndroidNetworking.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation AndroidNetworking
{
    ActivityMonitor *activityMonitor;
    
    int mySocket;
    struct sockaddr_in myAddress;
    unsigned short myPort;
    unsigned int myAddressLength;

    
    int peerSocket;
    struct sockaddr_in peerAddress;
    unsigned int peerAddressLength;
    
    
    dispatch_queue_t listenForConnectionsQueue;
    
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (instancetype) initWithMonitor:(ActivityMonitor*) monitor
{
    self = [super init];
    
    if(self)
    {
        self->activityMonitor = monitor;
        return self;
    }else
    {
        NSLog(@"Cannot Initialize AndroidNetworking");
    }
    
    
    return NULL;
}

-(void) createServer
{
    mySocket = socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
    
    memset(&myAddress, 0, sizeof(myAddress));
    
    myAddress.sin_len = sizeof(myAddress);
    myAddress.sin_family = AF_INET;
    
    inet_pton(AF_INET,"0.0.0.0",&myAddress.sin_addr.s_addr);
    
    myAddress.sin_port = htons(5500);
    myAddress.sin_addr.s_addr = INADDR_ANY;
    int val, len;
    len = sizeof(val);
    if(setsockopt(mySocket, SOL_SOCKET, SO_DONTROUTE, &val, len)<0)
    {
        NSLog(@"Socket Option Unsuccessful");
    }
    if(bind(mySocket,(struct sockaddr*)&myAddress,sizeof(myAddress))<0)
    {
        [activityMonitor logActivity:@"Android: Bind unsuccesful"];
    }
    
    struct sockaddr_in localAddress;
    memset(&localAddress, 0, sizeof(localAddress));
    int localAddressLength = sizeof(localAddress);
    getsockname(mySocket,(struct sockaddr_in*)&localAddress, &localAddressLength);
    
    [activityMonitor logActivity:[NSString stringWithFormat:@"Local Address: %s",inet_ntoa(localAddress.sin_addr)]];
    if(listen(mySocket, 2)<0)
    {
        [activityMonitor logActivity:@"Android Listen unsuccesful"];
    }
    
    listenForConnectionsQueue = dispatch_queue_create("listen.for.connections", NULL);
    
}

-(void) listenForConnections
{
    peerAddressLength = sizeof(peerAddress);
    char *buffersize = alloca(sizeof(INET_ADDRSTRLEN));
    buffersize = memset(&buffersize, 0, sizeof(buffersize));

    dispatch_async(listenForConnectionsQueue, ^{
        bool keepListening = YES;

        while(keepListening){
            if((peerSocket = accept(mySocket,(struct sockaddr*)&peerAddress,&peerAddressLength)) <0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [activityMonitor logActivity:@"Android Accept connections unsuccesful"];
                });
                
                keepListening = NO;
                
            }else if(peerSocket)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    struct sockaddr_in localAddress;
                    memset(&localAddress, 0, sizeof(localAddress));
                    int localAddressLength = sizeof(localAddress);
                    getsockname(mySocket,(struct sockaddr_in*)&localAddress, &localAddressLength);
                    

                    
                    NSString* messageClient = [NSString stringWithFormat:@"Android Client address: %s", inet_ntoa( peerAddress.sin_addr)];
                    [activityMonitor logActivity:messageClient];
                    
                    NSString* messageServer = [NSString stringWithFormat:@"Android Server address: %s", inet_ntop(AF_INET, &myAddress.sin_addr.s_addr, buffersize, sizeof(buffersize))];
                    [activityMonitor logActivity:messageServer];

                });

            }
    }
    
    
    });
    

}

@end
