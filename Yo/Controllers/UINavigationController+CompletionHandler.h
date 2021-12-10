//
//  UINavigationController+CompletionHandler.h
//  
//
//  Created by Peter Reveles on 4/16/15.
//
//

#import <UIKit/UIKit.h>

@interface UINavigationController (CompletionHandler)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBLock:(void (^)())completionBlock;

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^)())completion;

@end
