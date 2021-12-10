//
//  YoAnimationController.h
//  Yo
//
//  Created by Peter Reveles on 4/9/15.
//
//

#import <UIKit/UIKit.h>
#import "YoTransitioningConstants.h"

@interface YoTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) id <UIViewControllerContextTransitioning> transitionContext;
@property (assign, nonatomic) YoTransition transition;

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext;
- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext;

#pragma mark Utility

- (CGFloat)getAreaToFillFromTransitionContext:(id <UIViewControllerContextTransitioning>)transitionContext ;

@end