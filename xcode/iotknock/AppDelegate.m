//
//  AppDelegate.m
//  iotknock
//
//  Created by Chris Hughes on 5/13/15.
//  Copyright (c) 2015 Chris Hughes. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <KandyAccessNotificationDelegate>
    @property (nonatomic, strong) NSMutableArray * notificationsList;
@end

@implementation AppDelegate
@synthesize dToken, apnsID;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Kandy initializeSDKWithDomainKey:@"DAKbc28ee8581b749a1be89f30f6a0f03b1" domainSecret:@"DAS5d712ae1a0034a8ab3399b980eb1e990"];
    [self loginToPubNub];
    
    //[[Kandy sharedInstance].access registerNotifications:self];
    
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        //Register UserNotificationSettings
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationType)(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
    }
    
    //Handle Kandy SDK remote notification
    self.notificationsList = [NSMutableArray new];
    [[NSUserDefaults standardUserDefaults] setObject:@"GreatPlayer" forKey:@"displayName"];
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] != nil)
    {
        NSDictionary* remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//
    }
//    [NSTimer scheduledTimerWithTimeInterval:1.75
//                                     target:self
//                                   selector:@selector(relogin)
//                                   userInfo:nil
//                                    repeats:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self relogin];
    });
    // Override point for customization after application launch.
    return YES;
    
}

-(void)relogin{
    NSDictionary* dict = [NSDictionary dictionaryWithObject:@"login" forKey:@"message"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"myevent"
                                                        object:self
                                                      userInfo:dict];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark PUBNUB

-(void)loginToPubNub{
    
    [PubNub setConfiguration:[PNConfiguration configurationForOrigin:@"pubsub.pubnub.com" publishKey:@"pub-c-68cc8c1b-2ad1-4956-84d5-41ae7c010b15" subscribeKey:@"sub-c-cfc489e0-fd04-11e4-afbd-02ee2ddab7fe" secretKey:@"sec-c-MGZjMWIyYjEtYWJhMy00NDNkLThkNGItNDU1NjU1NmQyM2Ex"]];
    [PubNub setDelegate:self];
    [PubNub connect];
    
    //Define a channel
    PNChannel *channel_1 = [PNChannel channelWithName:@"chattr" shouldObservePresence:YES];
    PNChannel *apns = [PNChannel channelWithName:@"chattr" shouldObservePresence:YES];
    //Subscribe to the channel
    [PubNub subscribeOnChannel:channel_1];
    [PubNub subscribeOnChannel:apns];

    //    [PubNub disablePushNotificationsOnChannel:apns withDevicePushToken:deviceToken];
    //    [PubNub disablePushNotificationsOnChannel:channel_1 withDevicePushToken:deviceToken];
    
    
    
    //Publish on the channel
    NSArray *signArr = @[@"---THE.JAYS.HAVE.BEEN.GOOD.TO.US---",@"--------ALL.HAIL.THE.SIGN!---------",@"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",@"XXX...............................X",@"..XX..............................X",@"...XXX...........................X.",@".....XX.........................X..",@".......XX.....................XX...",@"........XX...................XX....",@"........XX...................XX....",@".........XX..................X.....",@".........XX..................X.....",@"..........XX................X......",@"............XX............XXX......",@".............XX.....XXXXXX.........",@".............XXXXXXX...XXXX........",@"........XXXXXX..X.....XX..XXX......",@"......XXX........XXXXXX.....XX.....",@"......X...........XX.........XX....",@".....XX............................",@".....X.............................",@".....X.............................",@".....X.............................",@".....X.............................",@".....X.............................",@".....XXX........................X..",@".......XX......................XX..",@"........XX....................XX...",@".........XX.................XXX....",@"..........XXX..............XX......",@"............XX.XXXXXXXXXXXX........"];
    
    for (NSString *signPart in signArr) {
        [PubNub sendMessage:signPart toChannel:channel_1];
    }
    
}

#pragma mark remote code

//
//  Remote Code
//

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    NSLog(@"Error:%@",str);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"My device token is: %@", deviceToken);
    
    NSString *devToken = [[[[deviceToken description]
                            stringByReplacingOccurrencesOfString:@"<"withString:@""]
                           stringByReplacingOccurrencesOfString:@">" withString:@""]
                          stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    apnsID = devToken;
    dToken = deviceToken;
    PNChannel *apns = [PNChannel channelWithName:@"apns" shouldObservePresence:YES];
    [PubNub enablePushNotificationsOnChannel:apns withDevicePushToken:dToken andCompletionHandlingBlock:^(NSArray *channels, PNError *error) {
        NSLog(@"%@: enabled push",dToken);
    }];
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    
    if (notificationSettings.types) {
        NSLog(@"user allowed notifications");
    }else{
        NSLog(@"user did not allow notifications");
        UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Please turn on Notification"
                                                         message:@"Go to Settings > Notifications App.\n Switch on Sound, Badge & Alert"
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles: nil];
        [alert show];
        // show alert here
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PNChannel *apns = [PNChannel channelWithName:@"apns" shouldObservePresence:YES];
    if ([PubNub isSubscribedOnChannel:apns]){
        // do nothing
    } else {
        NSString *message = nil;
        NSLog(@"Logging: %@",userInfo);
        NSLog(@"padding str");
        id alert = [userInfo objectForKey:@"aps"];
        if ([alert isKindOfClass:[NSString class]]) {
            message = alert;
        } else if ([alert isKindOfClass:[NSDictionary class]]) {
            message = [alert objectForKey:@"alert"];
        }
        if (alert) {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message
//                                                                message:@"is the message."  delegate:self
//                                                      cancelButtonTitle:@"Yeah PubNub!"
//                                                      otherButtonTitles:@"Cool PubNub!", nil];
//            [alertView show];
        }
    }
}

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
    NSLog(@"message %@", message);
//    if ([message.message isKindOfClass:[NSString class]]){
//        if ([message.message rangeOfString:@"chews"].location == NSNotFound) {
//            if ([message.message rangeOfString:@"update"].location == NSNotFound) {
//            } else {
//                //            NSData *json;
//                //            json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
//                
//                NSLog( @"%@", [NSString stringWithFormat:@"received: %@", message.message] );
//                //            NSDictionary* dict = [NSDictionary dictionaryWithObject:message.message
//                //                                                             forKey:@"message"];
//                //
//            }
//        } else {
//            //self update ignore it
//        }
//    } else {
//        NSDictionary *messageData = message.message;
//        if ([messageData isKindOfClass:[NSDictionary class]]) {
//            if ([[messageData valueForKey:@"User"] rangeOfString:@"chews"].location == NSNotFound )
//            {
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"myevent"
//                                                                    object:self
//                                                                  userInfo:messageData];
//            } else {
//                // self update do nothing
//            }
//        }
//        
//        
//        NSError *error = nil;

//        id object = [NSJSONSerialization JSONObjectWithData:message.message options:NSJSONReadingAllowFragments error:&error];
//
//        // Verify object retrieved is dictionary
//        if ([object isKindOfClass:[NSDictionary class]] && error == nil)
//        {
//            NSLog(@"dictionary: %@", object);
//
//            // Get the value (string) for key 'next_page'
//            NSString *str;
//            str = [object objectForKey:@"title"];
//            NSLog(@"title is: %@", str);
//        }
//    }
}




//#pragma mark - Notifications
//- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
//{
//    [[UIApplication sharedApplication] registerForRemoteNotifications];
//}
//
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
//{
//    [[NSUserDefaults standardUserDefaults]setObject:deviceToken forKey:@"deviceToken"];
//    NSLog(@"device token is %@",deviceToken);
//}
//
//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
//{
//    
//    [self.notificationsList addObject:userInfo];
//    [self _handleRemoteNotifications];
//}
//
//#pragma mark - private
//-(void) _handleRemoteNotifications
//{
//    if([Kandy sharedInstance].access.connectionState == EKandyConnectionState_connected)
//    {
//        NSMutableArray *notificationListCopy = [self.notificationsList copy];
//        for(NSDictionary *remoteNotification in notificationListCopy)
//        {
//            [[Kandy sharedInstance].services.push handleRemoteNotification:remoteNotification responseCallback:^(NSError *error) {
//                if(error &&
//                   [error.domain isEqualToString:KandyNotificationServiceErrorDomain] &&
//                   error.code == EKandyNotificationServiceError_pushFormatNotSupported)
//                {
//                    //Push format not supported by Kandy, handle the notification by my self
//                }
//            }];
//            
//            [self.notificationsList removeObject:remoteNotification];
//        }
//    }
//}
//
//
//#pragma mark - KandyAccessNotificationDelegate
//-(void) connectionStatusChanged:(EKandyConnectionState)connectionStatus
//{
//    [self _handleRemoteNotifications];
//}
//
//-(void) gotInvalidUser:(NSError*)error{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                    message:@"Invalid User"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//}
//
//-(void) sessionExpired:(NSError*)error{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                    message:@"Session Expired"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//    [[Kandy sharedInstance].access renewExpiredSession:^(NSError *error) {
//    }];
//}
//
//-(void) SDKNotSupported:(NSError*)error{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                    message:@"SDK Not Supported"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//}


#pragma PUBNUB Section



@end
