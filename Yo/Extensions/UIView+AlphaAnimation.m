//
//  UIView+Animations.m
//  Yo
//
//  Created by Peter Reveles on 4/17/15.
//
//

#import "UIView+AlphaAnimation.h"

@implementation UIView (AlphaAnimation)

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated completionBlock:(void (^)(BOOL finished))block {
    CGFloat newAlpha = hidden?0.0f:1.0f;
    __weak UIView *weakSelf = self;
    void (^hideButtons)() = ^() {
        weakSelf.alpha = newAlpha;
    };
    void (^replyToSender)(BOOL finished) = ^(BOOL finished) {
        if (block) {
            block(finished);
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.75 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            hideButtons();
        } completion:^(BOOL finished) {
            weakSelf.hidden = hidden;
            replyToSender(finished);
        }];
    }
    else {
        hideButtons();
        self.hidden = hidden;
        replyToSender(YES);
    }
}

@end
