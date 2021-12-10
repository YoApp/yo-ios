//
//  YoNotificationManager.h
//  Yo
//
//  Created by Peter Reveles on 3/2/15.
//
//

#import <Foundation/Foundation.h>
@class Yo;
@class YoNotification;

@interface YoNotificationManager : NSObject

#pragma mark - Core Interface

@property (nonatomic, assign) BOOL pauseNotifications;

#pragma mark - Notificaitons

- (void)clearNotifications;

#pragma mark Banner Tool Tips

- (void)presentBannerNotification:(YoNotification *)notification NS_EXTENSION_UNAVAILABLE("not availavle in extension");

@end
