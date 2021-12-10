//
//  YoMenuTransitionAnimator.m
//  Yo
//
//  Created by Peter Reveles on 5/18/15.
//
//

#import "YoMenuTransitionAnimator.h"

@implementation YoMenuTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toViewController.view];
    
    // fromViewController no transform
    toViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -CGRectGetHeight(containerView.frame));
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, CGRectGetHeight(containerView.frame));
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:finished];
    }];
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    toViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, CGRectGetHeight(containerView.frame));
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        fromViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, -CGRectGetHeight(containerView.frame));
        toViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:finished];
    }];
}

@end
