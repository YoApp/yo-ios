//
//  YoNotificationPresentationMananger.h
//  Yo
//
//  Created by Peter Reveles on 3/12/15.
//
//

#import <Foundation/Foundation.h>
#import "YoNotificationObjectProtocol.h"

#define kYoNotificationPresentationManagerWillPresentNotification @"YoNotificationPresentationManagerWillPresentNotification"
#define kYoNotificationPresentationManagerDidPresentNotification @"YoNotificationPresentationManagerDidPresentNotification"
#define kYoNotificationPresentationManagerWillHideNotification @"YoNotificationPresentationManagerWillHideNotification"
#define kYoNotificationPresentationManagerDidHideNotification @"YoNotificationPresentationManagerDidHideNotification"
#define kYoNotificationPresentationManagerWillDismissNotification @"YoNotificationPresentationManagerWillDismissNotification"
#define kYoNotificationPresentationManagerDidDismissNotification @"YoNotificationPresentationManagerDidDismissNotification"
#define kYoDirectionKey @"direction"
#define kYoHeightKey @"height"

@protocol YoNotificationDelegate <NSObject>
@optional
- (void)willPresentNotification:(id)notification;
- (void)didPresentNotification:(id)notificaion;
@end

typedef NS_ENUM(NSUInteger, YoDirection) {
    YoDirectionFromTop,
    YoDirectionFromBottom
};

typedef NS_ENUM(NSUInteger, YoQueueType) {
    YoQueueTypeActive, // notifications do not dismiss until acted upon
    YoQueueTypePassive // notification queue only retains 1 notification at a time
};

/**
 This is the base class for banner-type notifications. This class is inteneded to
 be subclassed for use. Be sure to implement createViewForNotification:
 */
@interface YoNotificationPresentationMananger : NSObject

@property (nonatomic, weak) id <YoNotificationDelegate> delegate;

@property (nonatomic, assign) YoDirection presentationDirection; // defaults to YoDirectionFromTop

@property (nonatomic, assign) YoQueueType queueType; // defaults to YoQueueTypeActive

- (void)enqueueNotification:(id <YoNotificationObjectProtocal>)notification;

- (void)enqueueNotifications:(NSArray *)notifications;

/**
 If the notification will be removed from the presentation queue. If it is the current
 notification being presented it will be dismissed and the next notififcation will
 come into view.
 */
- (void)dequeueNotification:(id <YoNotificationObjectProtocal>)notification;

/**
 Dismisses the top notification from screen & queue. Does not present the next notification.
 */
- (void)dismissCurrentNotificationWithCompletionBlock:(void (^)(BOOL finished))block;

/**
 If there is a notification on display it will be retracted but not removed from
 the presentation queue.
 */
- (void)hideCurrentNotificationWithCompletionBlock:(void (^)(BOOL finished))block;

/**
 Will present the next notification in the presentation queue if their isnt a
 notification currently on display
 */
- (void)presentNextNotificationInQueue;

@property (nonatomic, assign) BOOL pauseNotifications;

/**
 Removes the current notfication on display and clears the presentation queue.
 */
- (void)clearAllNotificationsWithCompletionBlock:(void (^)())block;

/**
 Returns the array of ojects currently in queue. The object on display is still in
 queue.
 */
- (NSArray *)getNotificationsInQueue;

@end

@interface YoNotificationPresentationMananger (YoNPMSubclassingHooks)
/**
 Implement this create a view for the notfication data passed.
 */
- (UIView *)createViewForNotification:(id)notification;
@end
