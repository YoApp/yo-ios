//
//  YoNotificationManager.m
//  Yo
//
//  Created by Peter Reveles on 3/2/15.
//
//

#import "YoNotificationManager.h"

#ifndef IS_APP_EXTENSION
#import "YoBannerNotificationPresentationManager.h"
#import "RavenClient.h"
#endif

#define kYoNotificationQueueKey @"kYoNotificationQueueKey"

@interface YoNotificationManager ()
@property (nonatomic, strong) NSMutableOrderedSet *bannerNotificationBuffer;

@property (nonatomic, strong) YoBannerNotificationPresentationManager *bannerNotificationPresenter;
@end

@implementation YoNotificationManager

#pragma mark - Lazy Loading

- (NSMutableOrderedSet *)bannerNotificationBuffer {
    if (!_bannerNotificationBuffer) {
        _bannerNotificationBuffer = [NSMutableOrderedSet new];
    }
    return _bannerNotificationBuffer;
}

- (YoBannerNotificationPresentationManager *)bannerNotificationPresenter {
    if (!_bannerNotificationPresenter) {
        _bannerNotificationPresenter = [YoBannerNotificationPresentationManager new];
    }
    return _bannerNotificationPresenter;
}

#ifndef IS_APP_EXTENSION

#pragma mark - Notification Control

- (void)setPauseNotifications:(BOOL)pauseNotifications {
    _pauseNotifications = pauseNotifications;
    if (pauseNotifications) {
        [self.bannerNotificationPresenter hideCurrentNotificationWithCompletionBlock:nil];
    }
    else {
        [self.bannerNotificationPresenter presentNextNotificationInQueue];
        [self flushBannerNotificationBuffer];
    }
}

- (void)clearNotifications {
    [self.bannerNotificationPresenter clearAllNotificationsWithCompletionBlock:nil];
}

#pragma mark - Banner Notifiations

- (void)presentBannerNotification:(YoNotification *)notification {
    /*if (!self.pauseNotifications) {
        [self.bannerNotificationPresenter showNotification:notification];
    }
    else {
        [self.bannerNotificationBuffer addObject:notification];
    }*/
}

- (void)flushBannerNotificationBuffer {
    if (self.bannerNotificationBuffer.count) {
        [self.bannerNotificationPresenter enqueueNotifications:[self.bannerNotificationBuffer array]];
        [self.bannerNotificationBuffer removeAllObjects];
    }
}

#endif

@end
