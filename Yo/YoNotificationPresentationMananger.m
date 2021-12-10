//
//  YoNotificationPresentationMananger.m
//  Yo
//
//  Created by Peter Reveles on 3/12/15.
//
//

#import "YoNotificationPresentationMananger.h"
#import "YoMainNavigationController.h"

@interface YoNotificationPresentationMananger ()

@property (nonatomic, strong) NSMutableArray *notificationsQueue;

@property (nonatomic, weak) UIView *currentNotificationViewOnDisplay;

@end

@implementation YoNotificationPresentationMananger

#pragma mark - Lazy Loading

- (NSMutableArray *)notificationsQueue {
    if (!_notificationsQueue) {
        _notificationsQueue = [NSMutableArray array];
    }
    return _notificationsQueue;
}

#pragma mark - External Utility

///**
// Pauses all future notifications from coming to display and hides the current
// notification, if present.
// */
//- (void)pauseNotifications {
//    if (self.pauseNotifications == NO) {
//        self.pauseNotifications = YES;
//        [self dismissCurrentNotificationViewfromDirection:self.presentationDirection withCompletionBlock:nil];
//    }
//}
//
///**
// Allows future notfication to display and presents the first notfication in queue,
// if one is present.
// */
//- (void)resumeNotifications {
//    if (self.pauseNotifications == YES) {
//        self.pauseNotifications = NO;
//        [self popTopNotification]; // incase there are notificaitons in queue
//    }
//}

- (void)hideCurrentNotificationWithCompletionBlock:(void (^)(BOOL finished))block {
    if (self.currentNotificationViewOnDisplay == nil) {
        if (block) {
            block(YES);
        }
    }
    else {
        NSDictionary *context = @{kYoDirectionKey:@(self.presentationDirection),
                                  kYoHeightKey:@(self.currentNotificationViewOnDisplay.height)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerWillHideNotification object:self userInfo:context];
        [self dismissCurrentNotificationViewfromDirection:self.presentationDirection withCompletionBlock:^(bool finished) {
            if (block) {
                block(finished);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerDidHideNotification object:self userInfo:context];
        }];
    }
}

- (NSArray *)getNotificationsInQueue {
    return self.notificationsQueue;
}

- (void)clearAllNotificationsWithCompletionBlock:(void (^)())block {
    [self dismissCurrentNotificationWithCompletionBlock:^(BOOL finished) {
        [self.notificationsQueue removeAllObjects];
        if (block) {
            block();
        }
    }];
}

#pragma mark - Notifications Queue

- (void)enqueueNotification:(id <YoNotificationObjectProtocal>)notification {
    if (notification == nil) {
        return;
    }
    
    if (self.pauseNotifications) {
        if (self.queueType == YoQueueTypePassive &&
            self.notificationsQueue.count >= 1) {
            [self.notificationsQueue removeObjectAtIndex:0];
        }
    }
    else {
        __weak YoNotificationPresentationMananger *weakSelf = self;
        if (self.queueType == YoQueueTypeActive) {
            [self hideCurrentNotificationWithCompletionBlock:^(BOOL finished) {
                [weakSelf.notificationsQueue insertObject:notification atIndex:0];
                [weakSelf presentNextNotificationInQueue];
            }];
        }
        else if (self.queueType == YoQueueTypePassive){
            [weakSelf.notificationsQueue addObject:notification];
            [self popTopNotification];
        }
        else {
            DDLogWarn(@"%@ | Warning notificatino not presented due to invalid queue type.", [[self class] description]);
        }
    }
}

#warning This will clearly not maintain queue order if there are already notifications in the queue; however, this case should not happen.
- (void)enqueueNotifications:(NSArray *)notifications {
    if ([notifications count] == 0) {
        return;
    }
    NSMutableArray *mutableNotifications = [notifications mutableCopy];
    id firstNotification = [mutableNotifications firstObject];
    if (firstNotification != nil) {
        [self enqueueNotification:firstNotification];
        [mutableNotifications removeObject:firstNotification];
    }
    self.notificationsQueue = [[self.notificationsQueue arrayByAddingObjectsFromArray:mutableNotifications] mutableCopy];
}

- (void)dequeueNotification:(id<YoNotificationObjectProtocal>)notification {
    NSInteger indexOfObject = [self.notificationsQueue indexOfObject:notification];
    if (indexOfObject != NSNotFound) {
        if (indexOfObject == 0 && self.currentNotificationViewOnDisplay != nil) {
            [self popTopNotification];
        }
        else {
            [self.notificationsQueue removeObjectAtIndex:indexOfObject];
        }
    }
}

/**
 If a notification is present on screen it will be hidden and removed from the
 notfication queue. If the queue is not empty, the next Yo in queue will be presented.
 */
- (void)popTopNotification {
    __weak YoNotificationPresentationMananger *weakSelf = self;
    id <YoNotificationObjectProtocal> notification = [self.notificationsQueue firstObject];
    if (self.currentNotificationViewOnDisplay) {
        [self dismissCurrentNotificationWithCompletionBlock:^(BOOL finished) {
            [weakSelf popTopNotification];
        }];
        if ([notification respondsToSelector:@selector(dismissalSound)]) {
            [APPDELEGATE playSound:[notification dismissalSound]];
        }
        return;
    }
    else if (self.notificationsQueue.count && !self.pauseNotifications) {
        [self presentNextNotificationInQueue];
    }
}

/**
 Will present the next notification in the presentation queue if their isnt a 
 notification currently on display
 */
- (void)presentNextNotificationInQueue {
    __weak YoNotificationPresentationMananger *weakSelf = self;
    id <YoNotificationObjectProtocal> notification = [self.notificationsQueue firstObject];
    if (!self.currentNotificationViewOnDisplay && self.notificationsQueue.count && !self.pauseNotifications) {
        UIView *notificationView = [self createViewForNotification:notification];
        if (notificationView == nil) {
            DDLogWarn(@"WARNING - %@ failed to create Yo View", NSStringFromClass([self class]));
            return;
        }
        switch (self.presentationDirection) {
            case YoDirectionFromBottom:
                notificationView.top = CGRectGetHeight([[UIScreen mainScreen] bounds]);
                break;
                
            case YoDirectionFromTop:
                notificationView.bottom = 0.0f;
                break;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(willPresentNotification:)]) {
            [self.delegate willPresentNotification:notification];
        }
        NSDictionary *context = @{kYoDirectionKey:@(weakSelf.presentationDirection),
                                  kYoHeightKey:@(notificationView.height)};
        void (^postYoDidDisplayNotification)() = ^() {
            // let the rest of the app know
            [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerDidPresentNotification object:weakSelf userInfo:context];
            if ([notification respondsToSelector:@selector(presentationSound)]) {
                if ([notification presentationSound]) {
                    [APPDELEGATE playSound:[notification presentationSound]];
                }
            }
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerWillPresentNotification object:weakSelf userInfo:context];
        [self presentNotificationView:notificationView fromDirection:self.presentationDirection completionBlock:^(BOOL finished) {
            if (finished) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didPresentNotification:)]) {
                    [weakSelf.delegate didPresentNotification:notification];
                }
                postYoDidDisplayNotification();
            }
        }];
    }
}

#pragma mark - Presentation

- (void)presentNotificationView:(UIView *)noteView fromDirection:(YoDirection)direction completionBlock:(void (^)(BOOL finished))block {
    if (noteView == nil) {
        return;
    }
    if (self.currentNotificationViewOnDisplay != nil) {
        DDLogWarn(@"Cannot present another notification while there is a notification on display. Call %@ first", NSStringFromSelector(@selector(popTopNotification)));
        return;
    }

    [[[(YOAppDelegate *)[[UIApplication sharedApplication] delegate] mainController] view] addSubview:noteView];
    self.currentNotificationViewOnDisplay = noteView;
    
    void (^animationBlock)() = ^(){
        switch (direction) {
            case YoDirectionFromBottom:
                noteView.bottom = CGRectGetHeight([[UIScreen mainScreen] bounds]);
                break;
                
            case YoDirectionFromTop:
                noteView.top = 0.0;
                break;
        }
    };
    
    if (!IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.2 delay:0.0
             usingSpringWithDamping:0.8 initialSpringVelocity:0.2
                            options:UIViewAnimationOptionCurveEaseInOut animations:^{
            animationBlock();
        } completion:block];
    }
    else {
        [UIView animateWithDuration:0.2 animations:^{
            animationBlock();
        } completion:block];
    }
}

- (void)dismissCurrentNotificationWithCompletionBlock:(void (^)(BOOL finished))block {
    if (self.currentNotificationViewOnDisplay == nil) {
        if (block) {
            block(YES);
        }
    }
    else {
        NSDictionary *context = @{kYoDirectionKey:@(self.presentationDirection),
                                  kYoHeightKey:@(self.currentNotificationViewOnDisplay.height)};
        [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerWillDismissNotification object:self userInfo:context];
        __weak YoNotificationPresentationMananger *weakSelf = self;
        [self dismissCurrentNotificationViewfromDirection:self.presentationDirection withCompletionBlock:^(bool finished) {
            if ([self.notificationsQueue count]) {
                [weakSelf.notificationsQueue removeObjectAtIndex:0];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kYoNotificationPresentationManagerDidDismissNotification object:self userInfo:context];
            
            if (block) {
                block(finished);
            }
        }];
    }
}

/**
 Dismisses the view from display. Does not remove it from the queue.
 */
- (void)dismissCurrentNotificationViewfromDirection:(YoDirection)direction withCompletionBlock:(void (^)(bool finished))block{
    if (self.currentNotificationViewOnDisplay == nil) {
        if (block) {
            block(NO);
        }
        return;
    }
    YoNotificationPresentationMananger *weakSelf = self;
    void (^animationBlock)() = ^(){
        switch (direction) {
            case YoDirectionFromTop:
                weakSelf.currentNotificationViewOnDisplay.bottom = 0.0;
                break;
                
            case YoDirectionFromBottom:
                weakSelf.currentNotificationViewOnDisplay.top = CGRectGetHeight([[UIScreen mainScreen] bounds]);
                break;
        }
    };
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        [weakSelf.currentNotificationViewOnDisplay removeFromSuperview];
        weakSelf.currentNotificationViewOnDisplay = nil;
        if (block) {
            block(finished);
        }
    };
    if (!IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.2 delay:0.1
             usingSpringWithDamping:0.7 initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animationBlock
                         completion:completionBlock];
    }
    else {
        [UIView animateWithDuration:0.2
                         animations:animationBlock
                         completion:completionBlock];
    }
}

@end
