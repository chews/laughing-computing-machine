//
//  AppDelegate.h
//  iotknock
//
//  Created by Chris Hughes on 5/13/15.
//  Copyright (c) 2015 Chris Hughes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KandySDK/KandySDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PNDelegate>


@property (strong, nonatomic) UIWindow *window;
@property NSString *apnsID;
@property NSData *dToken;

@end

