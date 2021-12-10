//
//  YoAnimationController.m
//  Yo
//
//  Created by Peter Reveles on 4/9/15.
//
//

#import "YoTransitionAnimator.h"

@interface YoTransitionAnimator ()
@end

@implementation YoTransitionAnimator

#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.55; // Default animation duration
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext; 
    
    switch (self.transition) {
        case YoPresentatingTransition:
            [self executePresentationAnimation:transitionContext];
            break;
            
        case YoDismissingTransition:
            [self executeDismissalAnimation:transitionContext];
            break;
    }
}

- (void)animationEnded:(BOOL)transitionCompleted {
    // Can be subclassed
}

#pragma mark - Utility

- (CGFloat)getAreaToFillFromTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGFloat areaToFill = 0.0f;
    
    YoBaseViewController *fromViewController = (YoBaseViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    YoBaseViewController *toViewController = (YoBaseViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (![fromViewController isKindOfClass:[YoBaseViewController class]] ||
        ![toViewController isKindOfClass:[YoBaseViewController class]]) {
        return areaToFill;
    }
    else {
        CGFloat fromViewArea = 0.0f;
        CGFloat toViewArea = 0.0f;
        if (self.transition == YoPresentatingTransition) {
            fromViewArea = toViewController.presentorView.width * toViewController.presentorView.height;
            toViewArea = toViewController.view.width * toViewController.view.height;
        }
        else if (self.transition == YoDismissingTransition) {
            fromViewArea = fromViewController.view.width * fromViewController.view.height;
            toViewArea = fromViewController.presentorView.width * fromViewController.presentorView.height;
        }
        
        // these areas are rough estimates
        // They do not account for view masks (custom shapes)
        areaToFill = fabs(toViewArea - fromViewArea);
    }
    
    return areaToFill;
}

#pragma mark Subclass

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Should be subclassed
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Should be subclassed
}

@end
