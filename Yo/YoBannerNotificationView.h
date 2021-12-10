//
//  YoTapNotificationView.h
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import <UIKit/UIKit.h>
@class YoNotification;
@class YoBannerNotificationView;

#define BANNER_NOTIFICATION_HEIGHT 90.0f

@protocol YoBannerNoteDelegate <NSObject>
- (void)userDidTapDismissButtonForBannerNotificaitonView:(YoBannerNotificationView *)bannerNote;
- (void)userDidTapBannerNotificaitonView:(YoBannerNotificationView *)bannerNote;
@end

@interface YoBannerNotificationView : UIView

- (instancetype)initWithNotification:(YoNotification *)notification;

@property (nonatomic, weak) id <YoBannerNoteDelegate> delegate;
@property (nonatomic, readonly) YoNotification *notificaiton;

@end
