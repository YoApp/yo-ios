//
//  YoBannerNotificationPresentationManager.h
//  Yo
//
//  Created by Peter Reveles on 3/12/15.
//
//

#import "YoNotificationPresentationMananger.h"
@class YoNotification;

@interface YoBannerNotificationPresentationManager : YoNotificationPresentationMananger

- (void)showNotification:(YoNotification *)notification;

@end
