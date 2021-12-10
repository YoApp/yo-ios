//
//  UINavigationController+CompletionHandler.m
//  
//
//  Created by Peter Reveles on 4/16/15.
//
//

#import "UINavigationController+CompletionHandler.h"

@implementation UINavigationController (CompletionHandler)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBLock:(void (^)())completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
    [CATransaction commit];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^)())completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    UIViewController *viewController = [self popViewControllerAnimated:animated];
    [CATransaction commit];
    return viewController;
}

@end
