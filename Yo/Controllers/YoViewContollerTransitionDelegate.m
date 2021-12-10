//
//  YoViewContollerTransitionDelegate.m
//  Yo
//
//  Created by Peter Reveles on 4/10/15.
//
//

#import "YoViewContollerTransitionDelegate.h"
#import "YoTransitionAnimator.h"
#import "YoPaperTransitionAnimator.h"
#import "YoFormTransistionAnimator.h"
#import "YoMenuTransitionAnimator.h"

@implementation YoViewContollerTransitionDelegate

#pragma mark View controller transitioning delegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    YoTransitionAnimator *transitionAnimator = nil;
    if ([presented isKindOfClass:[YoBaseViewController class]]) {
        YoBaseViewController *keyViewController = (YoBaseViewController *)presented;
        transitionAnimator = [self getTransitionAnimatorForViewController:keyViewController];
    }
    [transitionAnimator setTransition:YoPresentatingTransition];
    return transitionAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    YoTransitionAnimator *transitionAnimator = nil;
    if ([dismissed isKindOfClass:[YoBaseViewController class]]) {
        YoBaseViewController *keyViewController = (YoBaseViewController *)dismissed;
        transitionAnimator = [self getTransitionAnimatorForViewController:keyViewController];
    }
    [transitionAnimator setTransition:YoDismissingTransition];
    return transitionAnimator;
}

- (YoTransitionAnimator *)getTransitionAnimatorForViewController:(YoBaseViewController *)viewController {
    YoTransitionAnimator *transitionAnimator = nil;
    YoTransitionStyle transitionStyle = [viewController transitionStyle];
    transitionAnimator = [YoViewContollerTransitionDelegate getAnimatorForTransitionStyle:transitionStyle];
    // can't perform paper animation without presentationSender
    id presentationSender = [viewController presentorView];
    if (transitionStyle == YoPaperTransitionStyle && presentationSender == nil) {
        transitionAnimator = nil;
    }
    return transitionAnimator;
}

+ (YoTransitionAnimator *)getAnimatorForTransitionStyle:(YoTransitionStyle)transitionStyle {
    YoTransitionAnimator *animationController = nil;
    switch (transitionStyle) {
        case YoFormTransistionStyle:
            animationController = [YoFormTransistionAnimator new];
            break;
            
        case YoMenuTransistionStyle:
            animationController = [YoMenuTransitionAnimator new];
            break;
            
        case YoPaperTransitionStyle:
            // figure out what to do here
            animationController = [YoPaperTransitionAnimator new];
            break;
            
        default:
            // figure out what to do here
            animationController = nil;
            break;
    }
    return animationController;
}

@end

@implementation YoViewContollerTransitionDelegate (NavigationController)

#pragma mark - Navigation controller delegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController {
    YoTransitionAnimator *transitionAnimator = nil;
    YoTransition transition = [self getTransitionForOperation:operation];
    UIViewController *keyViewController = nil;
    switch (transition) {
        case YoDismissingTransition:
            keyViewController = fromViewController;
            break;
            
        case YoPresentatingTransition:
            keyViewController = toViewController;
            break;
    }
    if ([keyViewController isKindOfClass:[YoBaseViewController class]]) {
        YoTransitionStyle transitionStyle = [(YoBaseViewController *)keyViewController transitionStyle];
        transitionAnimator = [YoViewContollerTransitionDelegate getAnimatorForTransitionStyle:transitionStyle];
    }
    [transitionAnimator setTransition:transition];
    return transitionAnimator;
}

- (YoTransition)getTransitionForOperation:(UINavigationControllerOperation)operation {
    switch (operation) {
        case UINavigationControllerOperationPop:
            return YoDismissingTransition;
            
        case UINavigationControllerOperationPush:
            return YoPresentatingTransition;
            
        default:
            return YoPresentatingTransition;
    }
}

@end