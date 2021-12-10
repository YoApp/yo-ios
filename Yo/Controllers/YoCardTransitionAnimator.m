//
//  YoProfileTransitionAnimator.m
//  Yo
//
//  Created by Peter Reveles on 5/19/15.
//
//

#import "YoCardTransitionAnimator.h"

@implementation YoCardTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    toViewController.view.layer.opacity = 0.0f;
    toViewController.view.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    
    [containerView addSubview:toViewController.view];
    
    CGFloat introPercentage = 0.6f;
    NSTimeInterval introTime = duration * introPercentage;
    NSTimeInterval outroTime = duration - introTime;
    
    [UIView animateWithDuration:introTime animations:^{
        toViewController.view.layer.opacity = introPercentage;
        toViewController.view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:outroTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toViewController.view.layer.opacity = 1.0f;
            toViewController.view.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:finished];
        }];
    }];
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    CGFloat introPercentage = 0.4f;
    NSTimeInterval introTime = duration * introPercentage;
    NSTimeInterval outroTime = duration - introTime;
    
    [UIView animateWithDuration:introTime animations:^{
        fromViewController.view.layer.opacity = 1.0f - introPercentage;
        fromViewController.view.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:outroTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromViewController.view.layer.opacity = 0.0f;
            fromViewController.view.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        } completion:^(BOOL finished) {
            fromViewController.view.layer.opacity = 1.0f;
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:finished];
        }];
    }];
}

@end
