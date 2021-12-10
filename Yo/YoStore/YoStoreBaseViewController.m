//
//  YoStoreBaseViewController.m
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoStoreBaseViewController.h"
#import "YoStoreButton.h"

@implementation YoStoreBaseViewController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.cornerRadius = 0.0;
}

- (NSURL *)photoURLForForFileName:(NSString *)fileName {
    return [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/profile/%@", fileName)];
}

- (NSURL *)screenshotURLForFilename:(NSString *)filename {
    return [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/screenshots/%@", filename)];
}

#pragma mark - Subscribing

- (void)unsubscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block {
    void (^relayResult)(BOOL success) = ^(BOOL success) {
        if (block) {
            block(success);
        }
    };
    if ([service.username length]) {
        // dont do anything but pass it on
        [[[YoUser me] contactsManager] unsubscribeFromServiceWithUsername:service.username withCompletionBlock:^(BOOL success) {
            relayResult(success);
        }];
        [YoAnalytics logEvent:YoEventUnsubscribedToService withParameters:@{YoParam_USERNAME:service.username?:@"no_username"}];
    }
    else {
        relayResult(NO);
        DDLogWarn(@"%@ | Error, could not unsubscribe due to missing username.", NSStringFromSelector(@selector(unsubscribeFromServiceWithUsername:withCompletionBlock:)));
    }
}

- (void)subscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block {
    if ([service.username length]) {
        [[[YoUser me] contactsManager] subscribeToService:service withCompletionBlock:block];
        [YoAnalytics logEvent:YoEventSubscribedToService withParameters:@{YoParam_USERNAME:service.username?:@"no_username"}];
    }
}

#pragma mark - Animations

- (void)performTitleChangeAnimationOnButton:(YoStoreButton *)button
                                      delay:(NSTimeInterval)delay
                                   newTitle:(NSString *)newTitle
                        withCompletionBlock:(void (^)(BOOL finished))block {
    CGRect orinalFrame = button.layer.frame;
    CGFloat originalCornerRadius = button.layer.cornerRadius;
    struct CGColor *layerBackgroundColor = button.layer.backgroundColor;
    
    CGFloat finalWidth = button.frame.size.height;
    CGPoint finalFrameOrigin = CGPointMake(button.frame.origin.x + (button.width - finalWidth), button.frame.origin.y);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            button.layer.frame = CGRectMake(finalFrameOrigin.x, finalFrameOrigin.y, finalWidth, button.height);
            button.layer.cornerRadius = button.layer.frame.size.height/2.0f;
            button.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        } completion:^(BOOL finished) {
            NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:2*2];
            for (int index = 0; index < 3; index++) {
                [values addObject:(id)[[UIColor clearColor] CGColor]];
                [values addObject:(id)[[UIColor whiteColor] CGColor]];
            }
            
            CAKeyframeAnimation *colorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
            
            colorAnimation.duration = 1.5f;
            colorAnimation.values = values;
            colorAnimation.repeatCount = 1;
            
            [button.layer addAnimation:colorAnimation forKey:@"backgroundColor"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    [button setTitle:newTitle forState:UIControlStateNormal];
                    button.layer.frame = orinalFrame;
                    button.layer.cornerRadius = originalCornerRadius;
                    button.layer.backgroundColor = layerBackgroundColor;
                } completion:^(BOOL finished) {
                    if (block) {
                        block(finished);
                    }
                }];
            });
        }];
    });
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
