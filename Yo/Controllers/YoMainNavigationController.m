//
//  YoMainNavigationController.m
//  Yo
//
//  Created by Peter Reveles on 5/18/15.
//
//

// Controller
#import "YoMainNavigationController.h"
#import "YoShareSheet.h"
#import "YoCardTransitionAnimator.h"

#import "YoConfigManager.h"

@interface YoMainNavigationController () <UIViewControllerTransitioningDelegate>
@end

@implementation YoMainNavigationController

- (void)presentLogin {
    UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:YoLoginStoryboard bundle:nil];
    UIViewController *loggedOutViewController = [loginStoryBoard instantiateInitialViewController];
    loggedOutViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:loggedOutViewController animated:YES completion:nil];
}

@end