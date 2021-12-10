//
//  YoPushNotificationRequestor.h
//  Yo
//
//  Created by Peter Reveles on 2/12/15.
//
//

#import <Foundation/Foundation.h>

@interface YoPushNotificationPermissionRequestor : NSObject

+ (instancetype)sharedInstance;

typedef void (^PushNotificationRequestResultBlock)(BOOL permissionGranted);

- (void)makeRequestWithCompletionBlock:(PushNotificationRequestResultBlock)resultBlock;

@property (nonatomic, readonly) BOOL requestAlertIsOnScreen;

@end
