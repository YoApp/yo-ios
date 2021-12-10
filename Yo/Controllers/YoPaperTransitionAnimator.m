//
//  YoPaperAnimationController.m
//  Yo
//
//  Created by Peter Reveles on 4/9/15.
//
//

#import "YoPaperTransitionAnimator.h"

@implementation YoPaperTransitionAnimator

#pragma mark Main

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGFloat areaToFill = [self getAreaToFillFromTransitionContext:transitionContext];
    
    NSTimeInterval duration = areaToFill/233549.0f * 0.275;
    
    return duration;
}

- (void)executePresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    // pull relevant data
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    YoBaseViewController *fromViewController = (YoBaseViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    YoBaseViewController *toViewController = (YoBaseViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    if (![fromViewController isKindOfClass:[YoBaseViewController class]] ||
        ![toViewController isKindOfClass:[YoBaseViewController class]]) {
        [transitionContext completeTransition:NO];
        return;
    }
    
    [toViewController beginAppearanceTransition:YES animated:[transitionContext isAnimated]];
    
    [containerView addSubview:toViewController.view];
    
    NSMutableArray *maskPathValues = [NSMutableArray new];
    
    CGPoint presentationViewRelativeOrigin = [fromViewController.view convertPoint:CGPointZero
                                                                          fromView:toViewController.presentorView];
    CGFloat presentationViewAspectRatio = toViewController.presentorView.height/toViewController.presentorView.width;
    
    // frame 1 - Begining
    CGRect frameOneRect = CGRectMake(presentationViewRelativeOrigin.x,
                                     presentationViewRelativeOrigin.y,
                                     toViewController.presentorView.width,
                                     toViewController.presentorView.height);
    
    CGFloat frameOneCornerRadius = toViewController.presentorView.layer.cornerRadius;
    
    UIBezierPath *frameOneMaskPath = [UIBezierPath bezierPathWithRoundedRect:frameOneRect
                                                                cornerRadius:frameOneCornerRadius];
    
    [maskPathValues addObject:(__bridge id)(frameOneMaskPath.CGPath)];
    
    // frame 2 - Middle
    CGFloat frameTwoWidth = toViewController.view.width;
    CGFloat frameTwoHeight = frameTwoWidth * presentationViewAspectRatio;
    CGSize frameTwoSize = CGSizeMake(frameTwoWidth, frameTwoHeight);
    CGFloat xCoordinate = 0.0f;
    CGFloat relativeCenterY = presentationViewRelativeOrigin.y + (toViewController.presentorView.height/2.0f);
    CGFloat yCoordinate = relativeCenterY - (frameTwoHeight/2.0f);
    
    CGRect frameTwoRect = CGRectMake(xCoordinate,
                                     yCoordinate,
                                     frameTwoSize.width,
                                     frameTwoSize.height);
    
    CGFloat frameTwoCornerRadius = fabs(toViewController.view.layer.cornerRadius - toViewController.presentorView.layer.cornerRadius)/2.0f;
    
    UIBezierPath *frameTwoMaskPath = [UIBezierPath bezierPathWithRoundedRect:frameTwoRect
                                                                cornerRadius:frameTwoCornerRadius];
    
    [maskPathValues addObject:(__bridge id)(frameTwoMaskPath.CGPath)];
    
    // frame 3 - End
    CGRect frameThreeRect = toViewController.view.frame;
    
    CGFloat frameThreeCornerRadius = toViewController.view.layer.cornerRadius;
    
    UIBezierPath *frameThreeMaskPath = [UIBezierPath bezierPathWithRoundedRect:frameThreeRect
                                                                cornerRadius:frameThreeCornerRadius];
    
    [maskPathValues addObject:(__bridge id)(frameThreeMaskPath.CGPath)];
    
    // set mask
    CAShapeLayer *mask = [CAShapeLayer new];
    mask.path = frameThreeMaskPath.CGPath;
    toViewController.view.layer.mask = mask;
    
    // calculate timing
    CGFloat heightToTravel = toViewController.view.height - toViewController.presentorView.height;
    CGFloat widthToTravel = toViewController.view.width - toViewController.presentorView.width;
    CGFloat totalDistanceToTravel = heightToTravel + widthToTravel;
    
    CGFloat relativeHeightToTravel = 0.0f;
    if (heightToTravel > 0) {
        relativeHeightToTravel = heightToTravel / totalDistanceToTravel;
    }
    CGFloat relativeWidthToTravel = 0.0f;
    if (widthToTravel > 0) {
        relativeWidthToTravel = widthToTravel / totalDistanceToTravel;
    }
    
//    // add presentation view
//    CGPoint absolutePoint = [fromViewController.view convertPoint:CGPointZero
//                                                         fromView:toViewController.presentorView];
//    CGRect absoluteFrame = CGRectMake(absolutePoint.x,
//                                      absolutePoint.y,
//                                      toViewController.presentorView.width,
//                                      toViewController.presentorView.height);
//    
//    UIImage *presentationViewImage = [fromViewController screenShotCurrentViewAtRect:absoluteFrame
//                                                                  afterScreenUpdates:NO];
//    
//    UIImageView *presentationViewImageView = [[UIImageView alloc] initWithImage:presentationViewImage];
//    [containerView addSubview:presentationViewImageView];
//    
//    CGPoint presentationViewInitialPlacement = CGPointMake(toViewController.presentorView.center.x, relativeCenterY);
//    presentationViewImageView.center = presentationViewInitialPlacement;
//    
//    CGPoint presentationViewFinalPlacement = CGPointMake(toViewController.presentorView.center.x, (frameTwoRect.origin.y + toViewController.presentorView.height/2.0f));
//    
//    [UIView animateWithDuration:duration * relativeWidthToTravel animations:^{
//        presentationViewImageView.center = presentationViewFinalPlacement;
//    }];
//    
//    [UIView animateWithDuration:duration animations:^{
//        presentationViewImageView.alpha = 0.0f;
//    }];
    
    // animate
    CAKeyframeAnimation *paperAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    paperAnimation.values = maskPathValues;
    paperAnimation.keyTimes = @[@(0.0), @(relativeWidthToTravel), @(relativeHeightToTravel)];
    paperAnimation.duration = duration;
    paperAnimation.delegate = self;
    [mask addAnimation:paperAnimation forKey:@"path"];
    
    // Making ToViewController Content Fluid DuringAnimation
    //[toViewController.view.subviews makeObjectsPerformSelector:@selector(setAlpha:) withObject:@(0.0f)];
    
    for (UIView *subview in toViewController.view.subviews) {
        subview.alpha = 0.0f;
    }
    
    [UIView animateKeyframesWithDuration:0.2 delay:duration options:0 animations:^{
        //[toViewController.view.subviews makeObjectsPerformSelector:@selector(setAlpha:) withObject:@(1.0f)];
        for (UIView *subview in toViewController.view.subviews) {
            subview.alpha = 1.0f;
        }
    } completion:^(BOOL finished) {
        toViewController.view.layer.mask = nil;
        [transitionContext completeTransition:YES];
        [toViewController endAppearanceTransition];
    }];
}

- (void)executeDismissalAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    // pull relevant data
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    
    UIView *presentationView = nil;
    if ([fromViewController isKindOfClass:[YoBaseViewController class]]) {
        presentationView = [(YoBaseViewController *)fromViewController presentorView];
    }
    
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    NSMutableArray *maskPathValues = [NSMutableArray new];
    
    CGPoint presentationViewRelativeOrigin = [fromViewController.view convertPoint:CGPointZero
                                                                          fromView:presentationView];
    
    // initial frame
    CGRect initialFrameRect = fromViewController.view.frame;
    
    CGFloat initialFrameCornerRadius = fromViewController.view.layer.cornerRadius;
    
    UIBezierPath *initialFrameMaskPath = [UIBezierPath bezierPathWithRoundedRect:initialFrameRect
                                                                cornerRadius:initialFrameCornerRadius];
    
    [maskPathValues addObject:(__bridge id)(initialFrameMaskPath.CGPath)];
    
    // final frame
    CGRect finalFrameRect = CGRectMake(presentationViewRelativeOrigin.x,
                                       presentationViewRelativeOrigin.y,
                                       presentationView.width,
                                       presentationView.height);
    
    CGFloat finalFrameCornerRadius = presentationView.layer.cornerRadius;
    
    UIBezierPath *finalFrameMaskPath = [UIBezierPath bezierPathWithRoundedRect:finalFrameRect
                                                                  cornerRadius:finalFrameCornerRadius];
    
    [maskPathValues addObject:(__bridge id)(finalFrameMaskPath.CGPath)];
    
    // set mask
    CAShapeLayer *mask = [CAShapeLayer new];
    mask.path = finalFrameMaskPath.CGPath;
    fromViewController.view.layer.mask = mask;
    
    // calculate timing
    CGFloat heightToTravel = presentationView.height - toViewController.view.height;
    CGFloat widthToTravel = presentationView.width - toViewController.view.width;
    CGFloat totalDistanceToTravel = heightToTravel + widthToTravel;
    
    CGFloat relativeHeightToTravel = 0.0f;
    if (heightToTravel > 0) {
        relativeHeightToTravel = heightToTravel / totalDistanceToTravel;
    }
    CGFloat relativeWidthToTravel = 0.0f;
    if (widthToTravel > 0) {
        relativeWidthToTravel = widthToTravel / totalDistanceToTravel;
    }
    
//    // add presentation view
//    UIImage *presentationViewImage = nil;
//    UIImageView *presentationViewImageView = [[UIImageView alloc] initWithImage:presentationViewImage];
//    [containerView addSubview:presentationViewImageView];
//    
//    presentationViewImageView.frame = CGRectMake(presentationViewRelativeOrigin.x, presentationViewRelativeOrigin.y, presentationView.width, presentationView.height);
//    presentationViewImageView.alpha = 0.0f;
//    
//    [UIView animateWithDuration:duration animations:^{
//        presentationViewImageView.alpha = 1.0f;
//    } completion:^(BOOL finished) {
//        [presentationViewImageView removeFromSuperview];
//    }];
    
    // animate
    CAKeyframeAnimation *paperAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    paperAnimation.values = maskPathValues;
    paperAnimation.duration = duration;
    paperAnimation.delegate = self;
    [mask addAnimation:paperAnimation forKey:@"path"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [transitionContext completeTransition:YES];
    });
}

//- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
//    if (flag) {
//        UIViewController *toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
//        toViewController.view.layer.mask = nil;
//        [self.transitionContext completeTransition:YES];
//    }
//}

@end
