//
//  YoBannerNotificationPresentationManager.m
//  Yo
//
//  Created by Peter Reveles on 3/12/15.
//
//

#import "YoBannerNotificationPresentationManager.h"
#import "YoBannerNotificationView.h"
#import "YoActionPerformer.h"
#import "YoNotification.h"

@interface YoBannerNotificationPresentationManager () <YoBannerNoteDelegate>

@end

@implementation YoBannerNotificationPresentationManager

#pragma mark - Life

- (instancetype)init {
    self = [super init];
    if (self) {
        // setup
        [self setup];
    }
    return self;
}

- (void)setup {
    self.presentationDirection = YoDirectionFromBottom;
    self.queueType = YoQueueTypePassive;
}

#pragma mark - External Utility

- (void)showNotification:(YoNotification *)notification {
    if (notification == nil) {
        DDLogWarn(@"%@ | Error: Enqueued Yo with no notification", [[YoBannerNotificationPresentationManager class] description]);
    }
    else {
        [super enqueueNotification:notification];
    }
}

#pragma mark - YoNPMSubclassingHooks

- (UIView *)createViewForNotification:(YoNotification *)notification {
    YoBannerNotificationView *bannerView = [[YoBannerNotificationView alloc] initWithNotification:notification];
    bannerView.delegate = self;
    bannerView.frame = [self getDefaultBannerFrame];
    return bannerView;
}

- (CGRect)getDefaultBannerFrame {
    CGFloat screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    return CGRectMake(0.0f, screenHeight, screenWidth, BANNER_NOTIFICATION_HEIGHT);
}

#pragma mark - YoBannerNoteDelegate

- (void)userDidTapBannerNotificaitonView:(YoBannerNotificationView *)bannerNote {
    YoNotification *notificaiton = bannerNote.notificaiton;
    [self dismissCurrentNotificationWithCompletionBlock:^(BOOL finished){
        if (notificaiton.tapBlock) {
            notificaiton.tapBlock();
        }
    }];
}

- (void)userDidTapDismissButtonForBannerNotificaitonView:(YoBannerNotificationView *)bannerNote {
    [self dismissCurrentNotificationWithCompletionBlock:nil];
}

@end
