//
//  YoFormTransistionAnimator.m
//  Yo
//
//  Created by Peter Reveles on 4/17/15.
//
//

#import "YoFormTransistionAnimator.h"

@implementation YoFormTransistionAnimator

#pragma mark Main

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    //[toViewController beginAppearanceTransition:YES animated:[transitionContext isAnimated]];
    [containerView addSubview:toViewController.view];
    
    // fromViewController no transform
    toViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, CGRectGetHeight(containerView.frame));
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:finished];
        //[toViewController endAppearanceTransition];
    }];
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    //[toViewController beginAppearanceTransition:YES animated:[transitionContext isAnimated]];
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        fromViewController.view.transform = CGAffineTransformMakeTranslation(0.0f, CGRectGetHeight(containerView.frame));
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:finished];
        //[toViewController endAppearanceTransition];
    }];
}

@end
