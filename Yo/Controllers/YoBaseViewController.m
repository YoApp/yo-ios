//
//  YoBaseViewController.m
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoBaseViewController.h"
#import <FXBlurView/FXBlurView.h>
#import "YoCardTransitionAnimator.h"
#import "YoPhoneVerificationByCodeController.h"
#import "YoPhoneVerificationBySMSController.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "YOFacebookManager.h"

@interface YoBaseViewController () <FBSDKAppInviteDialogDelegate>
@end

@implementation YoBaseViewController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.profileImageView.layer.cornerRadius = 5.0f;
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.borderColor = [[UIColor colorWithHexString:@"7A3B97"] CGColor];
    self.profileImageView.layer.borderWidth = 2.0f;
    
    self.view.layer.cornerRadius = 10.0;
    self.view.layer.masksToBounds = YES;
    
    self.contentView.layer.cornerRadius = 10.0;
    self.contentView.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ShowInviteFacebook"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self inviteViaFacebook];
                                                  }];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[YoActivityManager sharedInstance] controllerWillBePresented:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[YoActivityManager sharedInstance] controllerPresented:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[YoActivityManager sharedInstance] controllerDidDisAppear:self];
}

#pragma mark - External Utility

- (UIImage *)screenShotViewAtRect:(CGRect)rect afterScreenUpdates:(BOOL)afterScreenUpdates {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(rect.size);
    
    [self.view drawViewHierarchyInRect:CGRectMake(-rect.origin.x,
                                                  -rect.origin.y,
                                                  self.view.width,
                                                  self.view.height) afterScreenUpdates:NO];
    
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenShot;
}

- (BOOL)areNotificationAllowed {
    return YES;
}

- (IBAction)close {
    [self closeWithCompletionBlock:nil];
}

- (IBAction)closeWithCompletionBlock:(void (^)())completion {
    [self hideBlurredBackground];
    [self dismissViewControllerAnimated:YES completion:completion];
}

- (void)showBlurredBackgroundWithViewController:(YoBaseViewController *)vc {
    [self animateBlurredBackgroundAndAddBelowController:vc];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)presentController:(YoBaseViewController *)vc {
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationCustom;
    nc.transitioningDelegate = self;
    [self showBlurredBackgroundWithViewController:nc];
}

- (void)animateBlurredBackgroundAndAddBelowController:(YoBaseViewController *)vc {
    
    UIImage *screenShot = [[YoApp takeScreenShot] blurredImageWithRadius:40 iterations:3 tintColor:[UIColor blackColor]];
    
    self.blurredBackgrounImageView = [[UIImageView alloc] initWithImage:screenShot];
    self.blurredBackgrounImageView.frame = vc.view.frame;
    self.blurredBackgrounImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    UIView *view = [[UIView alloc] initWithFrame:self.blurredBackgrounImageView.frame];
    view.autoresizingMask = self.blurredBackgrounImageView.autoresizingMask;
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    [self.blurredBackgrounImageView addSubview:view];
    
    [vc.view insertSubview:self.blurredBackgrounImageView atIndex:0];
}

- (void)hideBlurredBackground {
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.blurredBackgrounImageView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.blurredBackgrounImageView removeFromSuperview];
                         self.blurredBackgrounImageView = nil;
                     }];
}

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    if (!CGRectContainsPoint(self.contentView.frame, touchPoint)) {
        [self close];
    }
}

- (void)showActivityOnView:(UIView *)view {
    UIActivityIndicatorView *myIndicator = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [myIndicator setCenter:CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2)];
    myIndicator.tag = 45;
    [view addSubview:myIndicator];
    [myIndicator startAnimating];
}

- (void)removeActivityFromView:(UIView *)view {
    [[view viewWithTag:45] removeFromSuperview];
}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    YoTransitionAnimator *transitionAnimator = [YoCardTransitionAnimator new];
    [transitionAnimator setTransition:YoPresentatingTransition];
    return transitionAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    YoTransitionAnimator *transitionAnimator = [YoCardTransitionAnimator new];
    [transitionAnimator setTransition:YoDismissingTransition];
    return transitionAnimator;
}

#pragma mark - Phone Verification

- (void)loadPhoneVerificationHash {
    self.hashLoadingStatus = YoLoadingStatusInProgress;
    [[YoApp currentSession] getPhoneVerificationHashWithCompletionBlock:^(NSString *hash) {
        if (hash) {
            self.phoneVerificationHash = hash;
            self.hashLoadingStatus = YoLoadingStatusComplete;
        }
        else {
            self.hashLoadingStatus = YoLoadingStatusFailed;
        }
        
        if (self.shouldPresentPhoneVerificationFlowOnHashLoad) {
            self.shouldPresentPhoneVerificationFlowOnHashLoad = NO;
            [self presentSMSPhoneVerification];
        }
    }];
}

- (void)presentPhoneVerificationFlowWithCloseButton:(BOOL)allowClose {
    
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *countryCode = [[[networkInfo subscriberCellularProvider] isoCountryCode] uppercaseString];
    
    if (!countryCode || [countryCode isEqualToString:@"ZZ"]) {
        NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
        countryCode = [[currentLocale objectForKey:NSLocaleCountryCode] uppercaseString];
    }
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    YoPhoneVerificationBySMSController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoPhoneVerificationBySMSControllerID"];
    vc.closeButtonText = NSLocalizedString(@"Close", nil);
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:^{
        if ( ! [countryCode isEqualToString:@"US"]) {
            [vc showEnterPhoneNumber];
        }
    }];
}

- (void)presentSMSPhoneVerification {
    if ( ! [MFMessageComposeViewController canSendText]) {
        DDLogError(@"This device can't send texts. simulator/ipod/ipad?");
        //        return;
    }
    if (self.hashLoadingStatus == YoLoadingStatusComplete &&
        self.phoneVerificationHash.length) {
        [MBProgressHUD hideAllHUDsForView:self.contentView animated:YES];
        [[YoApp currentSession] verifyUserPhoneNumberWithHash:self.phoneVerificationHash
                                              completionBlock:^(MessageComposeResult result)
         {
             if (result == MessageComposeResultFailed) {
                 YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Hello", nil).capitalizedString
                                                      desciption:NSLocalizedString(@"Looks like something went wrong. Please try again later.", nil)];
                 [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil)
                                                              tapBlock:nil]];
                 [[YoAlertManager sharedInstance] showAlert:alert];
             }
             else if (result == MessageComposeResultCancelled) {
                 UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
                 YoPhoneVerificationByCodeController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoPhoneVerificationByCodeControllerID"];
                 YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
                 [self presentViewController:nc animated:YES completion:nil];
             }
         }];
    }
    else if (self.hashLoadingStatus == YoLoadingStatusFailed) {
        YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Hello", nil).capitalizedString
                                             desciption:NSLocalizedString(@"An error occured. Please try again later.", nil)];
        [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:alert];
    }
    else if (self.hashLoadingStatus == YoLoadingStatusInProgress) {
        self.shouldPresentPhoneVerificationFlowOnHashLoad = YES;
        [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    }
    else {
        self.shouldPresentPhoneVerificationFlowOnHashLoad = YES;
        [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
        [self loadPhoneVerificationHash];
    }
}

- (void)doInviteFacebook {
    FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:@"https://www.justyo.co"];
    content.appInvitePreviewImageURL = [NSURL URLWithString:@"https://yoapp.s3.amazonaws.com/yo/bro.png"];
    [FBSDKAppInviteDialog showFromViewController:self withContent:content delegate:self];
    
    [[YoApp currentSession].yoAPIClient POST:@"rpc/link_facebook_account"
                                  parameters:@{@"facebook_token":[[YOFacebookManager sharedInstance] accessToken]}
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         DDLogDebug(@"linked");
                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         DDLogDebug(@"error linking");
                                     }];
}

- (void)inviteViaFacebook {
    if ( ! [YOFacebookManager isLoggedIn]) {
        [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
            if (isLoggedIn) {
                [self doInviteFacebook];
            }
        }];
    }
    else {
        [self doInviteFacebook];
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results {
    
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    
}

@end