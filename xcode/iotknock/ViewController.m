//
//  ViewController.m
//  iotknock
//
//  Created by Chris Hughes on 5/13/15.
//  Copyright (c) 2015 Chris Hughes. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self login];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)login{
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

            [self registerForChatEvents];
        }
    }];
}


-(void)onMessageReceived:(id<KandyMessageProtocol>)kandyMessage recipientType:(EKandyRecordType)recipientType{
    
    [kandyMessage markAsReceivedWithResponseCallback:^(NSError *error) {
        if (error) {
            //Failure
        } else {
            //Success
        }
    }];
    
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
-(void)onMessageDelivered:(KandyDeliveryAck*)ackData{
    // do some acking here
    //
    
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

@end
