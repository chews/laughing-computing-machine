//
//  ViewController.m
//  iotknock
//
//  Created by Chris Hughes on 5/13/15.
//  Copyright (c) 2015 Chris Hughes. All rights reserved.
//
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "iotknock-Swift.h"
#import "ViewController.h"
#import "NSData+PNAdditions.h"

@interface ViewController ()
    @property (nonatomic) AVCaptureSession *captureSession;
    @property (strong,nonatomic) IBOutlet UIView *bigView;
    @property (strong,nonatomic) IBOutlet UIImageView *preview;

    @property (weak, nonatomic) IBOutlet UIButton *clientLoginBtn;
    @property (weak, nonatomic) IBOutlet UIButton *doorLoginBtn;
    @property (weak, nonatomic) IBOutlet UIButton *hangupBtn;
    @property (strong, nonatomic) MotionKit *motionKit;
    @property (weak, nonatomic) NSUserDefaults *userDefaults;
    @property (nonatomic, strong) id <KandyIncomingCallProtocol> currentIncomingCall;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewController

@synthesize captureSession, doorLoginBtn, clientLoginBtn, bigView, currentIncomingCall, hangupBtn, preview, motionKit, userDefaults, scrollView;
#define kUpdateFrequency    100.0
#define kFilteringFactor    0.1
float accelX;
float accelY;
float accelZ;
float prevAccelX;
float prevAccelY;
float prevAccelZ;
int knockCount = 0;
int knockTimeout = 0;
int photoCount = 0;
BOOL avSetup = NO;
BOOL isClient = YES;
BOOL BlockCalling = NO;




- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEvent:) name:@"myevent" object:nil];
    userDefaults = [NSUserDefaults standardUserDefaults];

    motionKit = [[NSClassFromString(@"MotionKit") alloc] init];
    bigView.hidden = YES;

    clientLoginBtn.hidden = NO;
    doorLoginBtn.hidden = NO;
    hangupBtn.hidden = YES;

    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)receiveEvent:(NSNotification *)notification {
    clientLoginBtn.hidden = NO;
    doorLoginBtn.hidden = NO;
    hangupBtn.hidden = NO;
    preview.hidden = NO;
    NSString *roleStr = [userDefaults objectForKey:@"role"];
    if (!roleStr){
        if ([roleStr containsString:@"door"]){
            [self doorLoginAction];
        }
        if ([roleStr containsString:@"client"]){
            [self clientLoginAction];
        }
    }

}
#pragma mark - Pubnub




-(void)sendChatWithMessage:(KandyChatMessage*)chatMessage {
    
    PNChannel *channel_1 = [PNChannel channelWithName:@"chattr" shouldObservePresence:YES];
    [[Kandy sharedInstance].services.chat sendChat:chatMessage
                                  progressCallback:^(KandyTransferProgress *transferProgress) {
                                      NSLog(@"Uploading message. Recipient - %@, UUID - %@, upload percentage - %ld", chatMessage.recipient.uri, chatMessage.uuid, (long)transferProgress.transferProgressPercentage);
////                                      NSInteger indexOfMsg = [self.messagesArray indexOfObject:chatMessage];
//                                      if (indexOfMsg != NSNotFound) {
////                                          [self.dictIndexPathToProgress setObject:transferProgress forKey:[NSIndexPath indexPathForRow:indexOfMsg inSection:0]];
//                                          NSLog(@"Done");
//                                      }
                                  }
                                  responseCallback:^(NSError *error) {
                                      if (!error) {
//                                          [self.messagesArray addObject:chatMessage];
                                          
                                          
                                          
                                          [PubNub sendMessage:chatMessage.mediaItem.text toChannel:channel_1];
                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Chat Sent Successfully"
                                                                                          message:error.localizedDescription
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"OK"
                                                                                otherButtonTitles:nil];
                                          [alert show];
                                      } else {
                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error sending chat"
                                                                                          message:error.localizedDescription
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"OK"
                                                                                otherButtonTitles:nil];
                                          [alert show];
                                      }
                                  }];
}

-(void)loadCarosel{
//    PNChannel *channel_1 = [PNChannel channelWithName:@"images" shouldObservePresence:YES];
//    
//    [PubNub requestHistoryForChannel:channel_1 from:nil to:nil limit:3 reverseHistory:YES withCompletionBlock:^(NSArray *messages, PNChannel *channel, PNDate *startDate, PNDate *endDate, PNError *requestError) {
//        [NSString stringWithUTF8String:[[NSData dataFromBase64String:self] bytes]]
//        UIImage *image = [[UIImage alloc] initWithData:[[NSData dataFromBase64String:[[messages objectAtIndex:1] message]] bytes]  ];
//        UIImage *image2 = [[UIImage alloc] initWithData:[[messages objectAtIndex:1] pn_inflate]];
//        UIImage *image3 = [[UIImage alloc] initWithData:[[messages objectAtIndex:1] pn_inflate]];
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//        UIImageView *imageView2 = [[UIImageView alloc] initWithImage:image2];
//        UIImageView *imageView3 = [[UIImageView alloc] initWithImage:image3];
//        [self.scrollView addSubview:imageView];
//        [self.scrollView addSubview:imageView2];
//        [self.scrollView addSubview:imageView3];
//        
//        NSData *data = [[[messages objectAtIndex:1] message] ];
//    }];
}

#pragma mark IBActions
- (IBAction)didTapSend:(id)sender {
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:@"user1@knocker.gmail.com"];
    KandyChatMessage *textMessage = [[KandyChatMessage alloc] initWithText:@"test" recipient:kandyRecord];
    [self sendChatWithMessage:textMessage];
}
- (IBAction)didTapPull:(id)sender {
    [self pullEvents];
}
- (IBAction)didTapHangup:(id)sender {
    [self hanupCall];
}
- (IBAction)didTapLogout:(id)sender {
    [self logout];
}

#pragma mark - Kandy Login
-(void)clientLoginAction{
    isClient = YES;
    bigView.hidden = NO;
    preview.hidden = NO;
    hangupBtn.hidden = NO;
    clientLoginBtn.hidden = YES;
    doorLoginBtn.hidden = YES;

    userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"client" forKey:@"role"];
    NSLog(@"userdefaults are %@",userDefaults);
    [userDefaults synchronize];
    KandyUserInfo * userInfo = [[KandyUserInfo alloc] initWithUserId:@"user1@knocker.gmail.com" password:@"1voluptasexcupidi1"];
    [[Kandy sharedInstance].access login:userInfo responseCallback:^(NSError *error) {
        if (error) {
            // Failure
            NSLog(@"error lame sauce");
            
        } else {
            
            //            [NSTimer scheduledTimerWithTimeInterval:2.0
            //                                             target:self
            //                                           selector:@selector(registerForChatEvents)
            //                                 S          userInfo:nil
            //                                            repeats:NO];
            [self registerForConnectEvents];
            [self loadCarosel];
        }
    }];

}
-(IBAction)clientlogin:(id)sender{
    [self clientLoginAction];
}
-(IBAction)doorlogin:(id)sender{
    [self doorLoginAction];
}
-(void)doorLoginAction{
    isClient = NO;
    preview.hidden = YES;
    hangupBtn.hidden = YES;
    clientLoginBtn.hidden = YES;
    doorLoginBtn.hidden = YES;
    
    [userDefaults setObject:@"door" forKey:@"role"];
    [userDefaults synchronize];
    
    KandyUserInfo * userInfo = [[KandyUserInfo alloc] initWithUserId:@"user2@knocker.gmail.com" password:@"2noncumquevero2"];
    [[Kandy sharedInstance].access login:userInfo responseCallback:^(NSError *error) {
        if (error) {
            // Failure
            NSLog(@"error lame sauce");
            
        } else {
            
            //            [NSTimer scheduledTimerWithTimeInterval:2.0
            //                                             target:self
            //                                           selector:@selector(registerForChatEvents)
            //                                           userInfo:nil
            //                                            repeats:NO];
            [self startMotionTracking];
            [self registerForChatEvents];
            [self registerForConnectEvents];

        }
    }];
}
-(void)logout{
    clientLoginBtn.hidden = NO;
    doorLoginBtn.hidden = NO;
    hangupBtn.hidden = YES;
    preview.hidden = YES;
    
    [userDefaults removeObjectForKey:@"role"];
    [userDefaults synchronize];
    
    [[Kandy sharedInstance].access logoutWithResponseCallback:^(NSError *error) {
        if (error) {
            // Failure
            NSLog(@"error lame sauce");
            
        } else {
            
        }
    }];
}
-(void)sendMsg {
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:@"user1@knocker.gmail.com"];
    KandyChatMessage *textMessage = [[KandyChatMessage alloc] initWithText:@"Message text" recipient:kandyRecord];
    [[Kandy sharedInstance].services.chat sendChat:textMessage progressCallback:^(KandyTransferProgress *transferProgress) {
        //progress
    }
                                  responseCallback:^(NSError *error) {
                                      if (error) {
                                          //Failure
                                      } else {
                                          //Success
                                      }
                                  }];
}

-(void)sendImageMsg:(NSString *)path {
    KandyRecord * kandyRecord = [[KandyRecord alloc] initWithURI:@"user1@knocker.gmail.com"];
    id<KandyMediaItemProtocol> mediaItem = [[Kandy sharedInstance].services.chat.messageBuilder createImageItem:path text:@"Optional text"];
    KandyChatMessage *message = [[KandyChatMessage alloc] initWithMediaItem:mediaItem recipient:kandyRecord];
    [[Kandy sharedInstance].services.chat sendChat:message progressCallback:^(KandyTransferProgress *transferProgress){
        //progress
    }
                                  responseCallback:^(NSError *error) {
                                      if (error) {
                                          //Failure
                                      } else {
                                          NSLog(@"sent message");
                                          //Success
                                      }
                                  }];
}
#pragma mark Kandy Message Protocol
-(void)markAsRead:(id<KandyMessageProtocol>)kandyMessage{
    [kandyMessage markAsReceivedWithResponseCallback:^(NSError *error) {
        if (error) {
            //Failure
        } else {
            id<KandyEventProtocol> kandyEvent = kandyMessage;
            [self ackEvent:kandyEvent];
            //Success
        }
    }];
}

-(void)onMessageReceived:(id<KandyMessageProtocol>)kandyMessage recipientType:(EKandyRecordType)recipientType{
    [self markAsRead:kandyMessage];
    
    switch (kandyMessage.mediaItem.mediaType) {
        case EKandyFileType_text:
            //Your code here
            NSLog(@"============== GOT CHAT MSG");
            break;
        case EKandyFileType_image:
            //Your code here
            
            NSLog(@"============== GOT IMG MSG");
            break;
        case EKandyFileType_video:
            //Your code here
            break;
        case EKandyFileType_audio:
            //Your code here
            break;
        case EKandyFileType_location:
            //Your code here
            break;
        case EKandyFileType_contact:
            //Your code here
            break;
        default:
            break;
    }
}

-(void) onAutoDownloadProgress:(KandyTransferProgress*)transferProgress kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    //Progress
}
-(void) onAutoDownloadFinished:(NSError*)error fileAbsolutePath:(NSString*)path kandyMessage:(id<KandyMessageProtocol>)kandyMessage {
    if(error){
        //Failure
    } else{
        //Success
    }
}


-(void)pullEvents {
    NSLog(@"GETTING CHATS");
    [[Kandy sharedInstance].services.chat pullEventsWithResponseCallback:^(NSError *error) {
        if (error) {
            //Failure
        }
        else {
            NSLog(@"PULLING CHATS");
            //Success
        }
    }];
}

-(void)ackEvent:(id<KandyEventProtocol>)kandyEvent {
    [kandyEvent markAsReceivedWithResponseCallback:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Acking Event"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

-(void)manualDownload:(id<KandyMessageProtocol>)kandyMessage{
    [[Kandy sharedInstance].services.chat downloadMedia:kandyMessage progressCallback:^(KandyTransferProgress *transferProgress) {
//        [self _updateDownloadProgressWithMessage:kandyMessage transferProgress:transferProgress downloadFinished:NO];
    } responseCallback:^(NSError *error, NSString *fileAbsolutePath) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Downloading Message"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
//            [self _updateDownloadProgressWithMessage:kandyMessage transferProgress:nil downloadFinished:YES];
        }
    }];
}


-(void)registerForChatEvents {

    NSData* deviceToken = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
    NSLog(@"Logging STR %@",[[NSUserDefaults standardUserDefaults]objectForKey:@"deviceTokenStr"]);
    NSString* bundleId = [[NSBundle mainBundle]bundleIdentifier];
    [[Kandy sharedInstance].services.push enableRemoteNotificationsWithToken:deviceToken bundleId:bundleId responseCallback:^(NSError *error) {
        if (error) {
            //handle error e.g no Internet connection
        } else {
            [[Kandy sharedInstance].services.chat registerNotifications:self];
            NSLog(@"TOTALLY GOOD! registered DEVICE ID");
        }
    }];
    
    NSLog(@"registering for events");
}
-(void)registerForConnectEvents{
    [[Kandy sharedInstance].services.call registerNotifications:self];
}




#pragma mark - KandyCallServiceNotificationDelegate

//-(void) gotIncomingCall:(id<KandyIncomingCallProtocol>)call {
//    BOOL isAnswerWithVideo = YES;
//    call.remoteVideoView=bigView;
//    [call accept:isAnswerWithVideo withResponseBlock:^(NSError *error) {
//        if (error) {
//            //Failure
//        }
//        else {
//            
//            
//            //Success
//        }
//    }];
//}


-(void) gotIncomingCall:(id<KandyIncomingCallProtocol>)call{
    call.remoteVideoView=bigView;
    CGPoint pos = bigView.layer.position;
    CGFloat x = 1.35;
    CGAffineTransform affineTransform = CGAffineTransformMakeTranslation(x, x);
    affineTransform = CGAffineTransformScale(affineTransform, x, x);
    affineTransform = CGAffineTransformRotate(affineTransform, 0);
    [CATransaction begin];
    //previewLayer is object of AVCaptureVideoPreviewLayer
    //[[bigView setAffineTransform:affineTransform];
    bigView.layer.affineTransform = affineTransform;
    pos.x = 135;
    pos.y = 146.5;
    bigView.layer.position = pos;
     
//    [[[self captureManager]previewLayer] setAffineTransform:affineTransform];
    [CATransaction commit];

    self.currentIncomingCall = call;
    if([call isSendingVideo]){
        [self muteCall];
    }
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Incoming Call" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Accept With Video", @"Accept Without Video", @"Reject", @"Ignore", nil];
    [actionSheet showInView:self.view];
}

-(void) gotMissedCall:(KandyMissedCall*)missedCall{
    if (isClient == YES) {
        [NSTimer scheduledTimerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(enableCalling)
                                       userInfo:nil
                                        repeats:NO];
    }
}
-(void) stateChanged:(EKandyCallState)callState forCall:(id<KandyCallProtocol>)call{
    NSLog(@"got a notice");
    //NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (callState == EKandyCallState_terminated) {
        if (isClient == NO) {
            //
            // door code
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(startMotionTracking)
                                           userInfo:nil
                                            repeats:NO];
        }
        if (isClient == YES) {
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(enableCalling)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
    if (callState == EKandyCallState_initialized) {
        if (isClient == NO) {
            [NSTimer scheduledTimerWithTimeInterval:20.0
                                             target:self
                                           selector:@selector(enableCalling)
                                           userInfo:nil
                                            repeats:NO];
            
        }
        if (isClient == YES) {
            
        }
    }
//    if (callState == EKandyCallState_initialized) {

//    }
    if (callState == EKandyCallState_talking) {

    }
}

-(void) participantsChanged:(NSArray*)participants forCall:(id<KandyCallProtocol>)call{
}
-(void) videoStateChangedForCall:(id<KandyCallProtocol>)call{
}
-(void) audioRouteChanged:(EKandyCallAudioRoute)audioRoute forCall:(id<KandyCallProtocol>)call{
}
-(void) videoCallImageOrientationChanged:(EKandyVideoCallImageOrientation)newImageOrientation forCall:(id<KandyCallProtocol>)call{
}
-(void) GSMCallIncoming{
}
-(void) GSMCallDialing{
}
-(void) GSMCallConnected{
}
-(void) GSMCallDisconnected{
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self acceptCall:NO];
            break;
        case 1:
            [self acceptCall:NO];
            break;
        case 2:
            [self rejectCall];
            break;
        case 3:
            [self ignoreCall];
            break;
        default:
            break;
    }
}

#pragma mark - Using Kandy SDK - Incoming Call
-(void) hanupCall {
    [self.currentIncomingCall hangupWithResponseCallback:^(NSError *error) {
        if (error) {
            //Failure
        }
        else {
            //Success
        }
    }];
}
-(void) muteCall{
    [self.currentIncomingCall muteWithResponseCallback:^(NSError *error) {
        if (error) {
            //Failure
        }
        else {
            //Success
        }
    }];
}
-(void) enableCalling{
    BlockCalling = NO;
}
-(void) makeVoipCall {
    if (isClient) return;
    if (BlockCalling) return;
    BlockCalling = YES;
    
    NSLog(@"calling ");
    [motionKit stopAccelerometerUpdates];
    KandyRecord *callee = [[KandyRecord alloc] initWithURI:@"user1@knocker.gmail.com"];
    BOOL isStartCallWithVideo = YES;
    
    id<KandyOutgoingCallProtocol> outgoingCall = [[Kandy sharedInstance].services.call createVoipCall:callee isStartVideo:isStartCallWithVideo];

    [outgoingCall establishWithResponseBlock:^(NSError *error) {
        if (error) {
            //Failure
        }
        else {

                [NSTimer scheduledTimerWithTimeInterval:15.0
                                                 target:self
                                               selector:@selector(enableCalling)
                                               userInfo:nil
                                                repeats:NO];

        }
    }];
}

-(void)acceptCall:(BOOL)isWithVideo{
    

    [self.currentIncomingCall accept:isWithVideo withResponseBlock:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            [self muteCall];
        }
    }];
}

-(void)rejectCall{
    [self.currentIncomingCall rejectWithResponseBlock:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Call Rejected"
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

-(void)ignoreCall{
    [self.currentIncomingCall ignoreWithResponseCallback:^(NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Call Ignored"
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

#pragma mark MotionKit

- (void)startMotionTracking {
    
    [motionKit stopAccelerometerUpdates];
    
    [motionKit getAccelerometerValuesWithInterval:1.0/kUpdateFrequency values:^(double x, double y, double z) {
        
        
        accelX = x - ( (x * kFilteringFactor) +
                      (prevAccelX * (1.0 - kFilteringFactor)) );
        accelY = y - ( (y * kFilteringFactor) +
                      (prevAccelY * (1.0 - kFilteringFactor)) );
        accelZ = z - ( (z * kFilteringFactor) +
                      (prevAccelZ * (1.0 - kFilteringFactor)) );
        
        // Compute the derivative (which represents change in acceleration).
        float deltaX = ABS((accelX - prevAccelX));
        float deltaY = ABS((accelY - prevAccelY));
        float deltaZ = ABS((accelZ - prevAccelZ));
        
        prevAccelX = x;
        prevAccelY = y;
        prevAccelZ = z;
        
        // Check if the derivative exceeds some sensitivity threshold
        // (Bigger value indicates stronger bump)
        // (Probably should use length of the vector instead of componentwise)
        if ( deltaX > 1.3 || deltaY > 1.3 || deltaZ > 1.3 ) {
            knockCount = knockCount + 1;
            NSLog( @"BUMP:  %.3f, %.3f, %.3f", deltaX, deltaY, deltaZ);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self strobeScreen];
            });
        }
        if (knockCount > 8)
        {
            NSLog(@"BUMPTED ENOUGH!!!");
            knockCount = 0;
            if (avSetup){
                [captureSession startRunning];
            } else {
                avSetup = YES;
                [self setupCaptureSession];
            }
        }
        if (knockCount > 1)
        {
            if (knockTimeout > 290)
            {
                knockTimeout = 0;
                knockCount = 0;
            } else {
                knockTimeout = knockTimeout +1;
            }
        }
        
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)strobeScreen{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view setNeedsDisplay];
    
    //fade in
    [UIView animateWithDuration:0.5f animations:^{
        
        self.view.backgroundColor = [UIColor redColor];
        
    } completion:^(BOOL finished) {
        
        //fade out
        [UIView animateWithDuration:0.5f animations:^{
            
            self.view.backgroundColor = [UIColor whiteColor];
            
        } completion:nil];
        
    }];
}

#pragma mark - image capture


// Create and configure a capture session and start it running
- (void)setupCaptureSession
{
    NSError *error = nil;
    
    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice deviceWithUniqueID:@"com.apple.avfoundation.avcapturedevice.built-in_video:1"];
    NSError *error2;
    [device lockForConfiguration:&error2];
    if (error2 == nil) {
        if (device.activeFormat.videoSupportedFrameRateRanges){
            [device setActiveVideoMinFrameDuration:CMTimeMake(1, 2)];
            [device setActiveVideoMaxFrameDuration:CMTimeMake(1, 2)];
        }else{
            //handle condition
        }
    }else{
        // handle error2
    }
    [device unlockForConfiguration];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if (!input)
    {
        NSLog(@"PANIC: no media input");
    }
    [session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    //dispatch_release(queue);
    
    // Specify the pixel format
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    // If you wish to cap the frame rate to a known value, such as 15 fps, set
    // minFrameDuration.
    
    // Start the session running to start the flow of data
    [session startRunning];
    
    // Assign session to an ivar.
    [self setSession:session];
}




// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        //< Add your code here that uses the image >
//        [self.imageView setImage:image];
        [self.view setNeedsDisplay];
        if (photoCount < 120){
            NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
            if (photoCount == 20){
                photoCount = 0;
                
                if (image != nil)
                {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                         NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSString *uuidString = [[NSUUID UUID] UUIDString];
                    NSString* path = [documentsDirectory stringByAppendingPathComponent:uuidString];
                    path = [path stringByAppendingPathExtension:@".png"];
                    NSData* data = UIImageJPEGRepresentation(image,0.5);
                    [data writeToFile:path atomically:YES];
                    [self makeVoipCall];
                    //[PubNub sendMessage:[data pn_base64Encoding] toChannel:[PNChannel channelWithName:@"images"]];
                    
//                    [PubNub sendMessage:@{@"array": @[@"of", @"strings"], @"and": @16}
//                  applePushNotification:@{@"aps":@{@"alert":@"Hey! Someone is knocking at your door"}}
//                              toChannel:[PNChannel channelWithName:@"apns"]];
                    
 //                   [imageOne setImage:image];
                    [captureSession stopRunning];
                    
                }
                
                
            }
            //TODO : Multiple upload support
            //            if (photoCount == 65){
            //                [imageTwo setImage:image];
            //            }
            //            if (photoCount == 119){
            //                [imageThree setImage:image];
            //                photoCount = 0;
            //                [captureSession stopRunning];
            //
            //            }
            photoCount = photoCount+1;
            
        }
    });
    
}
// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    NSLog(@"imageFromSampleBuffer: called");
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

-(void)setSession:(AVCaptureSession *)session
{
    NSLog(@"setting session...");
    self.captureSession=session;
}


@end
