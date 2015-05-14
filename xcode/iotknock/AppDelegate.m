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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Kandy initializeSDKWithDomainKey:@"DAKbc28ee8581b749a1be89f30f6a0f03b1" domainSecret:@"DAS5d712ae1a0034a8ab3399b980eb1e990"];
    
    [[Kandy sharedInstance].access registerNotifications:self];
    
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        //Register UserNotificationSettings
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert) categories:nil]];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationType)(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
    }
    
    //Handle Kandy SDK remote notification
    self.notificationsList = [NSMutableArray new];
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] != nil)
    {
        NSDictionary* remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [self.notificationsList addObject:remoteNotification];
    }

    
    // Override point for customization after application launch.
    return YES;
    
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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


#pragma mark - Notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[NSUserDefaults standardUserDefaults]setObject:deviceToken forKey:@"deviceToken"];
    NSLog(@"device token is %@",deviceToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    [self.notificationsList addObject:userInfo];
    [self _handleRemoteNotifications];
}

#pragma mark - private
-(void) _handleRemoteNotifications
{
    if([Kandy sharedInstance].access.connectionState == EKandyConnectionState_connected)
    {
        NSMutableArray *notificationListCopy = [self.notificationsList copy];
        for(NSDictionary *remoteNotification in notificationListCopy)
        {
            [[Kandy sharedInstance].services.push handleRemoteNotification:remoteNotification responseCallback:^(NSError *error) {
                if(error &&
                   [error.domain isEqualToString:KandyNotificationServiceErrorDomain] &&
                   error.code == EKandyNotificationServiceError_pushFormatNotSupported)
                {
                    //Push format not supported by Kandy, handle the notification by my self
                }
            }];
            
            [self.notificationsList removeObject:remoteNotification];
        }
    }
}


#pragma mark - KandyAccessNotificationDelegate
-(void) connectionStatusChanged:(EKandyConnectionState)connectionStatus
{
    [self _handleRemoteNotifications];
}

-(void) gotInvalidUser:(NSError*)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Invalid User"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void) sessionExpired:(NSError*)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Session Expired"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [[Kandy sharedInstance].access renewExpiredSession:^(NSError *error) {
    }];
}

-(void) SDKNotSupported:(NSError*)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"SDK Not Supported"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
