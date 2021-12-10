//
//  YoBaseViewController.h
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoViewControllerProtocol.h"
#import "YoTransitioningConstants.h"
#import "YoContextObject.h"
#import "YoActionButton.h"
#import "NSDate_Extentions.h"

typedef NS_ENUM(NSUInteger, YoLoadingStatus) {
    YoLoadingStatusUnstarted,
    YoLoadingStatusInProgress,
    YoLoadingStatusComplete,
    YoLoadingStatusFailed,
};

@protocol YoBlurredBackgroundPresentable <NSObject>

- (void)showBlurredBackgroundWithViewController:(UIViewController *)viewController;
- (void)hideBlurredBackground;
- (IBAction)close;
- (IBAction)closeWithCompletionBlock:(void (^)())completion;

@end

@interface YoBaseViewController : UIViewController <YoViewControllerProtocol, YoBlurredBackgroundPresentable, UIViewControllerTransitioningDelegate>

@property (assign, nonatomic) YoLoadingStatus hashLoadingStatus;
@property (strong, nonatomic) NSString *phoneVerificationHash;
@property (assign, nonatomic) BOOL shouldPresentPhoneVerificationFlowOnHashLoad;

@property (strong, nonatomic) UIColor *transparentBackgroundColor;
@property (weak, nonatomic) IBOutlet UIView *tapToDismissView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIView *userProfileView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet YoLabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet YoLabel *usernameLabel;

/**
 Captures the rect of this controllers current view.
 */
- (UIImage *)screenShotViewAtRect:(CGRect)rect afterScreenUpdates:(BOOL)afterScreenUpdates;

/**
 This property should be used to retain the object from which this controller was
 presented if it makes sense to do so.
 */
@property (nonatomic, weak) UIView *presentorView;

/**
 Set to desired transition style.
 */
@property (nonatomic, assign) YoTransitionStyle transitionStyle;

@property(nonatomic, strong) UIImageView *blurredBackgrounImageView;

@property(nonatomic, strong) YoContextObject *currentContextObject;

@property (nonatomic, strong) IBOutlet UIView *containerView;

- (void)showActivityOnView:(UIView *)view;
- (void)removeActivityFromView:(UIView *)view;

- (void)loadPhoneVerificationHash;
- (void)presentSMSPhoneVerification;
- (void)presentPhoneVerificationFlowWithCloseButton:(BOOL)allowClose;
- (void)presentController:(YoBaseViewController *)vc;

- (void)inviteViaFacebook;

@end
