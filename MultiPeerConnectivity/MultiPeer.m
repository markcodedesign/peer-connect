//
//  MultiPeer.m
//  MultiPeerConnectivity
//
//  Created by Lemark on 10/31/14.
//  Copyright (c) 2014 Mr. McByte. All rights reserved.
//

#import "MultiPeer.h"

#define SERVICETYPENAME @"multipeer-test"

@implementation MultiPeer
{
    ActivityMonitor *activityMonitor;
    
    UIActivityIndicatorView* startActivityIndicator;
    
    UIView* browserMainView;
    BOOL browserOn, advertisingOn, sessionOn;
    
    UITextView* messageScreenMainView;
    UITextField* messageInput;
    float messageInputOriginalYPoistion;
    
    UIButton* browseStartButton;
    UIButton* browseStopButton;
    UIButton* disconnectButton;
    
    UILabel* peersAvailable;
    
    NSString* myUserName;
    MCPeerID* myPeerID;
    unsigned long myHash;
    MCPeerID* peersPeerID;
    unsigned long long peersHash;
    
    MCNearbyServiceAdvertiser* myAdvertiser;
    MCNearbyServiceBrowser* myBrowser;

    BOOL isConnectedToAnyPeer;
    
}

////////////////////////////
// USER DEFINED METHODS

-(void) messageScreenCreate
{
    messageScreenMainView = [[UITextView alloc]init];
    messageScreenMainView.backgroundColor = [UIColor whiteColor];
    messageScreenMainView.textColor = [UIColor blackColor];
    messageScreenMainView.delegate = self;
    messageScreenMainView.tag = 1000;
    
    
    CGFloat screenPositionY = browserMainView.frame.size.height+browserMainView.frame.origin.y;
    CGFloat screenFrameHeight = (([UIScreen mainScreen].bounds.size.height) - screenPositionY)-110;
    
    messageScreenMainView.frame = CGRectMake(0.0,screenPositionY,[UIScreen mainScreen].bounds.size.width,screenFrameHeight);
    messageScreenMainView.showsVerticalScrollIndicator = YES;
    
    CGFloat messageInputPositionY = messageInputOriginalYPoistion = [UIScreen mainScreen].bounds.size.height-100;
   
    messageInput = [[UITextField alloc]initWithFrame:CGRectMake(10.0,messageInputPositionY, [UIScreen mainScreen].bounds.size.width-20,44.0)];
    messageInput.backgroundColor = [UIColor whiteColor];
    messageInput.borderStyle = UITextBorderStyleRoundedRect;
    messageInput.delegate = self;
    messageInput.keyboardType = UIKeyboardTypeDefault;
    messageInput.returnKeyType = UIReturnKeySend;
    messageInput.spellCheckingType = UITextSpellCheckingTypeNo;
    messageInput.autocorrectionType = UITextAutocorrectionTypeNo;
    messageInput.enablesReturnKeyAutomatically = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShow:)
                                                 name:@"UIKeyboardWillShowNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHide:)
                                                 name:@"UIKeyboardDidHideNotification"
                                               object:nil];
    
    
    [self.view addSubview:messageScreenMainView];
    [self.view addSubview:messageInput];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self messageSendDisplay:textField.text];
    [self messageSend:textField.text];
    textField.text = @"";
    
    return YES;
}



- (void) keyboardShow:(NSNotification *)note {
    NSDictionary *userInfo = [note userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect frame = messageInput.frame;
    messageInputOriginalYPoistion = frame.origin.y;
    frame.origin.y = [UIScreen mainScreen].bounds.size.height-keyboardSize.height-messageInput.frame.size.height-10;
    
    [UIView animateWithDuration:0.3 animations:^{
        messageInput.frame = frame;
    }];
}

- (void) keyboardHide:(NSNotification *)note {
    
    CGRect frame = messageInput.frame;
    frame.origin.y = messageInputOriginalYPoistion;
    
    [UIView animateWithDuration:0.3 animations:^{
        messageInput.frame = frame;
    }];
}

-(void) messageSend:(NSString*) message
{
    if(isConnectedToAnyPeer)
    {
        [activityMonitor logActivity:@"MultiPeer - Sending message to peers"];
        if(!message)
        {
            [activityMonitor logActivity:@"MultiPeer Cannot send message because message is empty"];
        }
        
        NSData* messageData = [[NSData  alloc]initWithData:[message dataUsingEncoding:NSASCIIStringEncoding]];
       
        if(message)
           [activityMonitor logActivity:@"MultiPeer Constructing message SUCCESSFUL"];
        else
            [activityMonitor logActivity:@"MultiPeer Cunstructing message UNSUCCESSFUL"];
        
        NSArray* tempPeers = [[NSArray alloc]initWithObjects:peersPeerID, nil];
    
        if([_mySession sendData:messageData toPeers:tempPeers withMode:MCSessionSendDataUnreliable error:NULL])
        {
            [activityMonitor logActivity:@"MultiPeer - Message sent."];
        }else
        {
            [activityMonitor logActivity:@"MultiPeer - Message did not send."];
        }
    }else
    {
        [self logActivityLocal:@"Must be connected to a peer to send messages."];
    }
}

-(void) messageReceive:(NSData*) messageData fromPeer:(NSString*) peerName
{
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer - Receiving data from %@\n", peerName]];
    
    NSString* message = [[NSString alloc]initWithBytes:messageData.bytes length:messageData.length encoding:NSASCIIStringEncoding];
    
    [self messageReceiveDisplay:message fromPeer:peerName];
    
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer - Receiving data from %@ SUCCESSFUL!\n", peerName]];
}

-(void) messageSendDisplay:(NSString*) messageString
{
    if(isConnectedToAnyPeer)
        messageScreenMainView.text = [messageScreenMainView.text stringByAppendingFormat:@"[You] %@\n",messageString];
    [self scrollDown];
    
}

-(void) messageReceiveDisplay:(NSString*) messageString fromPeer:(NSString*) peerName
{
    messageScreenMainView.text = [messageScreenMainView.text stringByAppendingFormat:@"[%@] %@\n",peerName,messageString];
    [self scrollDown];
}

-(void) logActivityLocal:(NSString*) messageString
{
    [self messageReceiveDisplay:messageString fromPeer:@"SYSTEM"];
}

-(void) initMultiPeer
{
    if(!myUserName)
    {
        myUserName = @"Skywalker";
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer using default username of %@", myUserName]];
    }

    
    if(!myPeerID)
    {
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer initializing for Username: %@", myUserName]];

        myPeerID = [[MCPeerID alloc]initWithDisplayName:myUserName];
        
        if(myPeerID)
        {
            [activityMonitor logActivity:@"MultiPeer Username initialized"];

            [activityMonitor logActivity:@"MultiPeer initializing Browser"];

            myBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:myPeerID serviceType:SERVICETYPENAME];
            if(!myBrowser)
                [activityMonitor logActivity:@"MultiPeer could not initialize browser!"];
            else{
                myBrowser.delegate = self;
                [activityMonitor logActivity:@"MultiPeer Browser initialized"];

            }
            [activityMonitor logActivity:@"MultiPeer initializing Advertiser"];

            self->myHash = myPeerID.hash;
            
            
            NSString* stringValue = [NSString stringWithFormat:@"%lu",self->myHash];
           
            NSDictionary* myDiscoveryInfo = [NSDictionary dictionaryWithObject:stringValue forKey:@"hash"];
      
            
             [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Hash of %@ is %lu", myPeerID.displayName,self->myHash]];
            [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Hash Converted of %@ is %lu", myPeerID.displayName, strtoul([stringValue UTF8String],NULL,0)]];
            

            myAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:myPeerID discoveryInfo:myDiscoveryInfo serviceType:SERVICETYPENAME];
            if(!myAdvertiser)
                [activityMonitor logActivity:@"MultiPeer could not initialize advertiser!"];
            else{
                myAdvertiser.delegate = self;
                [activityMonitor logActivity:@"MultiPeer Advertiser initialized"];
            }
           
            
            [activityMonitor logActivity:@"MultiPeer initializing Session"];
            
            _mySession = [[MCSession alloc]initWithPeer:myPeerID];
            if(!_mySession)
                [activityMonitor logActivity:@"MultiPeer could not initialize session!"];
            else{
                _mySession.delegate = self;
                [activityMonitor logActivity:@"MultiPeer Session initialized"];

            }
            
        }
        
    }
    
    [activityMonitor logActivity:@"MultiPeer initialization - SUCCESS"];

}

-(void) startBrowsingAndAdvertising
{
    [self startAnnouncing];
    [self startBrowsing];
}

-(void) stopBrowsingAndAdvertising
{
    [self stopAnnouncing];
    [self stopBrowsing];

}

-(void) startBrowsing
{
    
    if(!browserOn)
    {
        browserOn = TRUE;
        
        if(!startActivityIndicator)
        {
            startActivityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            startActivityIndicator.center = browserMainView.center;
            startActivityIndicator.color = [UIColor greenColor];
            [browserMainView addSubview:startActivityIndicator];
            [startActivityIndicator startAnimating];

        }
        else
        {
            [startActivityIndicator startAnimating];
        }
        
        
        if(myBrowser)
        {
            [activityMonitor logActivity:@"MultiPeer start browsing"];
            [self logActivityLocal:@"Browsing for peers started"];

            [myBrowser startBrowsingForPeers];
            
        }else
        {
            [activityMonitor logActivity:@"MultiPeer could not start browsing"];
        }
    }
}

-(void) stopBrowsing
{

    if(browserOn)
    {
        browserOn = FALSE;
    
        [startActivityIndicator stopAnimating];
        [activityMonitor logActivity:@"MultiPeer stop browsing"];
        [self logActivityLocal:@"Browsing for peers halted"];

        [myBrowser stopBrowsingForPeers];
        
    }
}

-(void) startAnnouncing
{

    if(!advertisingOn)
    {
        advertisingOn = TRUE;
    
        if(myAdvertiser)
        {
            [activityMonitor logActivity:@"MultiPeer start advertising"];
            [self logActivityLocal:@"Advertising for peers started"];

            [myAdvertiser startAdvertisingPeer];
        }else{
            [activityMonitor logActivity:@"MultiPeer could not start advertising"];
        }
    }
}

-(void) stopAnnouncing
{

    if(advertisingOn)
    {
        advertisingOn = FALSE;
    
        [myAdvertiser stopAdvertisingPeer];

        [activityMonitor logActivity:@"MultiPeer stop advertising"];
        [self logActivityLocal:@"Advertising for peers halted"];

    }
}

-(void) disconnectConnection
{
    if(self->_mySession)
    {
        
        [self->_mySession disconnect];
        [activityMonitor logActivity:@"MultiPeer You are now disconnected"];
        [self logActivityLocal:@"You are now disconnected."];
        [self stopBrowsingAndAdvertising];
        isConnectedToAnyPeer = NO;
        
    }
}

-(void) invitePeer:(MCPeerID*) peer hashOfPeer:(unsigned long long) peerHash
{


    [self stopBrowsing];

    
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer (Invite) hash for username %@ is %lu",myUserName,self->myHash]];
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer (Invite) hash for username %@ is %llu",peer.displayName,peerHash]];


    if(self->myHash > peerHash)
    {
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Trying to send invitation to %@", peer.displayName]];
      
        
        [self->myBrowser invitePeer:peer toSession:_mySession withContext:nil timeout:0];
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Invitation to %@ sent", peer.displayName]];

    }else
    {
        [activityMonitor logActivity:@"MultiPeer Waiting for invitation"];
        [self logActivityLocal:@"Waiting for invitation"];
        
    }
}


-(void) addFoundPeer: (MCPeerID*) peerID
{
    [activityMonitor logActivity:@"MultiPeer Adding found peer(s)"];

    peersPeerID = peerID;

    if(!peersAvailable)
        peersAvailable = [[UILabel alloc]initWithFrame:CGRectMake(5.0, 5.0, browserMainView.frame.size.width-10.0,20.0)];
    
    if(peersAvailable)
    {
        peersAvailable.text = [NSString stringWithFormat:@" %@", peerID.displayName];
        peersAvailable.tag = 100;
    }
    
    [activityMonitor logActivity:@"MultiPeer Adding found peer(s) - SUCCESS"];

}

-(void) displayFoundPeers
{
    [activityMonitor logActivity:@"MultiPeer Displaying found peer(s)"];

    peersAvailable.textColor = [UIColor whiteColor];
    peersAvailable.layer.borderColor = [UIColor whiteColor].CGColor;
    peersAvailable.layer.borderWidth = 1.0;
   
    [peersAvailable setUserInteractionEnabled:YES];
    peersAvailable.adjustsFontSizeToFitWidth = YES;

    
    [browserMainView addSubview:peersAvailable];
    
    [activityMonitor logActivity:@"MultiPeer Displaying found peer(s) - SUCCESS"];

}

-(void) resetBrowser
{
    [activityMonitor logActivity:@"MultiPeer Ressetting browser"];
    peersHash = 0;
    peersPeerID = NULL;
    [peersAvailable removeFromSuperview];
}

-(void) attachToMainActivityMonitor:(ActivityMonitor*) mainActivityMonitor
{
    activityMonitor = mainActivityMonitor;
    [activityMonitor logActivity:@"MultiPeer Attaching to Monitor - SUCCESS"];
}

-(void) displayDisconnectButton:(BOOL) turnOn
{
    
        if(turnOn)
        {
            self->disconnectButton.hidden = NO;
        }else
        {
            self->disconnectButton.hidden = YES;
        }
    
}


-(void) askForUserName
{
    UIAlertView* alertForUserName = [[UIAlertView alloc]initWithTitle:@"Enter Username"
                                                              message:@"max 10 char - Letters only"
                                                             delegate:self
                                                    cancelButtonTitle:@"Done"
                                                    otherButtonTitles:nil];
    
    alertForUserName.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alertForUserName show];

    
}


-(BOOL) doesUserNameEnteredContainsValidCharacters: (NSString*) userName
{
    NSString* validCharacters = @"abcdefghijklmnopqrstuvwxyz";
    NSString* upperCase = [validCharacters capitalizedString];
    validCharacters = [validCharacters stringByAppendingString:upperCase];
    
    NSCharacterSet* validCharacterSet = [NSCharacterSet characterSetWithCharactersInString:validCharacters];
    
    for(int i=0;i<userName.length;i++)
    {
        if(![validCharacterSet characterIsMember:[userName characterAtIndex:i]])
        {
            return NO;
        }
            
    }
    
    return YES;
}

//////////////////////////////
// ALERT VIEW DELEGATES

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* inputString = [alertView textFieldAtIndex:0].text;
    
    switch(buttonIndex)
    {
        case 0:
        {
            if([inputString  isEqual: @""] || [inputString isEqual:@" "])
            {
                [self askForUserName];
            }else
            {
                if(inputString.length < 11)
                {
                    if([self doesUserNameEnteredContainsValidCharacters:inputString])
                    {
                        self->myUserName = [alertView textFieldAtIndex:0].text;
                        [self->activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer USERNAME: %@\n", self->myUserName]];

                        [self initMultiPeer];
                        [self startBrowsingAndAdvertising];
                        
                    }else{
                        [self logActivityLocal:@"Invalid character entered. Please use Letters only."];
                        [self askForUserName];
                    }
            
                }
                else
                {
                    [self logActivityLocal:@"Username exceed allowable characters. Please enter username with no more than 10 characters."];
                    
                    [self askForUserName];
                    break;
                    
                }
            }
            
        }
        default:break;
        
    }
}


/////////////////////////////////////////
// BROWSER DELEGATE

- (void)browser:(MCNearbyServiceBrowser *)browser
didNotStartBrowsingForPeers:(NSError *)error
{
    [activityMonitor logActivity:@"MultiPeer Did Not Start browsing for peers - ERROR"];
    
}

/* Called when myBrowser finds peers */
- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary *)info
{
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Found nearby peer: %@", peerID.displayName]];

    [self resetBrowser];
    [self stopBrowsing];
    
    NSString* hashValue = [info objectForKey:@"hash"];
   
    
    if(!peersHash)
        self->peersHash = strtoull([hashValue UTF8String], NULL, 0);
    
    unsigned long long pearHasReceived = peerID.hash;

    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Recieved peerID = %llu", pearHasReceived]];
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Discover string hash value of peer %@ is %@", peerID.displayName, hashValue]];
    
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Discover string Converted hash value of peer %@ is %llu", peerID.displayName,self->peersHash]];

    [self addFoundPeer:peerID];
    [self displayFoundPeers];
    [self invitePeer:peerID hashOfPeer:self->peersHash];
    
}

- (void)browser:(MCNearbyServiceBrowser *)browser
       lostPeer:(MCPeerID *)peerID
{
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Lost nearby peer: %@", peerID.displayName]];

}

////////////////////////////////////////////////
// ADVERTISER DELEGATE

/* Called when an Inivitation is Received*/
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept,MCSession *session))invitationHandler
{

    NSString* peerDisplayName = peerID.displayName;
    
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer INVITATION RECEIVE from: %@",peerDisplayName]];
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer (Receive Invitation) hash for username %@ is %lu",myUserName,self->myHash]];
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer (Receive Invitation) hash for username %@ is %lu",peerDisplayName,(unsigned long)peerID.hash]];

    if(self->myHash < self->peersHash)
    {
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Accepting invitation receive from %@", peerDisplayName]];
        invitationHandler(YES,_mySession);
    }else
    {
        [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer (Receive Invitation) hash test FAILED. Invite receive from %@", peerDisplayName]];
       
        invitationHandler(NO,_mySession);
    }
}

////////////////////////////////////////////////
// SESSION DELEGATE

/* Called when peer accepts/rejects/connecting the invitation */
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    
    dispatch_async(dispatch_get_main_queue(),
^{

        
    [activityMonitor logActivity:@"MultiPeer Entering Session State"];
    NSString* peerDisplayName = peerID.displayName;
   
    @try {
       switch (state) {
        case MCSessionStateConnected:
        {
            isConnectedToAnyPeer = YES;
            [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Connection request Accepted by peer: %@",peerDisplayName]];
            [self logActivityLocal:[NSString stringWithFormat:@"You are now connected to peer: %@", peerDisplayName]];
            
            [activityMonitor logActivity:@"MultiPeer Removing Browse Start/Stop buttons"];
           
            browseStartButton.hidden = YES;
            browseStopButton.hidden = YES;
            [self displayDisconnectButton:YES];
            

            
        break;
        }
        case MCSessionStateNotConnected:
        {
            isConnectedToAnyPeer = NO;
            
            [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Connection request Declined/Disconnected by peer: %@",peerDisplayName]];
            [self logActivityLocal:[NSString stringWithFormat:@"You are disconnected from peer: %@", peerDisplayName]];
            
            [activityMonitor logActivity:@"MultiPeer Restoring Browse Start/Stop buttons"];

            [self displayDisconnectButton:NO];
            browseStartButton.hidden = NO;
            browseStopButton.hidden = NO;
            
            [self resetBrowser];
            

            break;
        }
        case MCSessionStateConnecting:
        {
            [self stopBrowsingAndAdvertising];

            [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Connectiing to %@",peerDisplayName]];
            [self logActivityLocal:[NSString stringWithFormat:@"Trying to connect to peer: %@",peerDisplayName]];
            break;
        }
            
        default:
           {
               //[self resetBrowser];
            break;
           }
    }
    }
     @catch (NSException *exception) {
         [activityMonitor logActivity:[exception description]];
         [self resetBrowser];
         
     }
    
});
}

-(void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
    [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer Data receive from %@", peerID.displayName]];

    [self messageReceive:data fromPeer:peerID.displayName];
                   });
}

-(void) session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    [activityMonitor logActivity:@"MultiPeer Receiving Stream"];
}

-(void) session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    [activityMonitor logActivity:@"MultiPeer Receiving Start"];
}

-(void) session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    [activityMonitor logActivity:@"MultiPeer Receiving Resource Finish"];
}


/////////////////////////////////////////
// CLASS OVERRIDE METHODS

-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        myUserName = NULL;
        startActivityIndicator = NULL;
        myBrowser = NULL;
        myAdvertiser = NULL;
        _mySession = NULL;
        isConnectedToAnyPeer = advertisingOn = sessionOn = browserOn = FALSE;

         self.title = @"MultiPeer";
        
//        NSFileManager* file = [NSFileManager defaultManager];
//        NSLog(@"Current Directory Path: %@", file.currentDirectoryPath);
//        NSString* filePath;
//        if([file fileExistsAtPath:@"tabicon-apple-50.png"])
//        {
//            NSLog(@"File Exist");
//            filePath = @"tabicon-apple-30.png";
//        }
//        else
//            NSLog(@"File Does Not Exist");
        
        
        UITabBarItem* tabItem = [[UITabBarItem alloc] initWithTitle:@"Apple" image:[UIImage imageNamed:@"tabicon-apple-30.png"] tag:100];
        if(!tabItem.image)
           NSLog(@"Cannot load image for tab item");
        tabItem.selectedImage = tabItem.image;
    
        self.tabBarItem = tabItem;
    }
    return self;
}

-(void) loadView
{
    [super loadView];
    if([self isViewLoaded])
    {
        self.view.backgroundColor = [UIColor whiteColor];
        
        CGRect browseMainViewFrameSize = self.view.frame;
        browseMainViewFrameSize.size.height = self.view.frame.size.height/3;
        browseMainViewFrameSize.origin.y = 20.0;
        browserMainView = [[UIView alloc] initWithFrame:browseMainViewFrameSize];
        browserMainView.backgroundColor = [UIColor lightGrayColor];
        browserMainView.tag = 500;
        
        disconnectButton = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 110.0, 24.0)];
        [disconnectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [disconnectButton setTitleColor:[UIColor greenColor] forState:UIControlEventTouchDown];
        disconnectButton.layer.borderColor = [UIColor whiteColor].CGColor;
        disconnectButton.layer.borderWidth = 1.0;
        disconnectButton.layer.cornerRadius = 4.0;
        disconnectButton.center = CGPointMake(browserMainView.center.x,browserMainView.frame.size.height-20);
        [disconnectButton addTarget:self action:@selector(disconnectConnection) forControlEvents:UIControlEventTouchDown];
        
        
        browseStartButton = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 88.0, 24.0)];
        [browseStartButton setTitle:@"Browse" forState:UIControlStateNormal];
        [browseStartButton setTitleColor:[UIColor greenColor] forState:UIControlEventTouchDown];
        browseStartButton.layer.borderColor = [UIColor whiteColor].CGColor;
        browseStartButton.layer.borderWidth = 1.0;
        browseStartButton.layer.cornerRadius = 4.0;
        browseStartButton.center = CGPointMake(self.view.center.x-(browseStartButton.frame.size.width/2)-5,browserMainView.frame.size.height-20);
        [browseStartButton addTarget:self action:@selector(startBrowsingAndAdvertising) forControlEvents:UIControlEventTouchDown];
        
        browseStopButton = [[UIButton alloc]initWithFrame:browseStartButton.frame];
        [browseStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        [browseStopButton setTitleColor:[UIColor greenColor] forState:UIControlEventTouchDown];
        browseStopButton.layer.borderColor = [UIColor whiteColor].CGColor;
        browseStopButton.layer.borderWidth = 1.0;
        browseStopButton.layer.cornerRadius = 4.0;
        browseStopButton.center = CGPointMake(browseStopButton.center.x+(browseStartButton.frame.size.width)+5,browserMainView.frame.size.height-20);
        [browseStopButton addTarget:self action:@selector(stopBrowsingAndAdvertising) forControlEvents:UIControlEventTouchDown];
    
   
        [browserMainView addSubview:browseStartButton];
        [browserMainView addSubview:browseStopButton];
        [browserMainView addSubview:disconnectButton];
        self->disconnectButton.hidden = YES;
        
        [self.view addSubview:browserMainView];
        [self messageScreenCreate];
        
    }
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    
    NSEnumerator *enumerateTouches = [touches objectEnumerator];
    
   
    for( UITouch *touch=NULL;touch = [enumerateTouches nextObject]; )
    {
        if(touch.view.tag == 100)
        {
            peersAvailable.backgroundColor = [UIColor grayColor];
          //  [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer peer selected: %@", peersAvailable.text] ];

            break;
        }else
        {
            if(peersAvailable)
            {
                peersAvailable.backgroundColor = [UIColor clearColor];
          //      [activityMonitor logActivity:[NSString stringWithFormat:@"MultiPeer peer diselected: %@", peersAvailable.text] ];
            }
        }

    }
    
    
    [messageInput resignFirstResponder];
}

-(void) viewDidLoad
{
    [activityMonitor logActivity:@"MultiPeer loaded"];
    
    [super viewDidLoad];
                        
}

-(void) viewWillAppear:(BOOL)animated
{
    if(!myUserName)
    {
        [self askForUserName];
    }
    
    [super viewWillAppear:animated];
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    [messageInput resignFirstResponder];

    // This is a delegate method.
    // We don't want editing in the text view; we just want to
    // use it to hold our log messages.
    return NO;
}

-(void) scrollDown
{
    NSRange stringRange = {stringRange.length = stringRange.location = [messageScreenMainView.text length]};
    [messageScreenMainView scrollRangeToVisible:stringRange];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
 }

@end
