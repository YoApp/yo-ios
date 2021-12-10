//
//  YoViewContollerTransitionDelegate.h
//  Yo
//
//  Created by Peter Reveles on 4/10/15.
//
//

#import <Foundation/Foundation.h>
#import "YoTransitioningConstants.h"
@class YoTransitionAnimator;

/**
 Responsible for managing the transition animation between Yo View Controllers.
 */
@interface YoViewContollerTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

+ (YoTransitionAnimator *)getAnimatorForTransitionStyle:(YoTransitionStyle)transitionStyle;

@end

@interface YoViewContollerTransitionDelegate (NavigationController) <UINavigationControllerDelegate>

@end