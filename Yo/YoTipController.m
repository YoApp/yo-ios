//
//  YoTipView.m
//  Yo
//
//  Created by Or Arbel on 6/5/15.
//
//

#import "YoTipController.h"
#import "YOAppDelegate.h"
#import "YoMainNavigationController.h"

@interface YoTipController ()
@property (nonatomic, strong) NSString *tipText;
@property (nonatomic, strong) NSString *tipKey;
@end

@implementation YoTipController

static BOOL alreadyShowingTip = NO;

+ (void)showTipIfNeeded:(NSString *)text {
    NSString *key = MakeString(@"did.see.tip.%@.%@", text, [YoUser me].username);
    if (alreadyShowingTip || [[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        return;
    }
    alreadyShowingTip = YES;
    
    UIViewController *mainViewController = [APPDELEGATE mainController];
    BOOL mainControllerIsVisibleController = ([[APPDELEGATE navigationController].visibleViewController isEqual:mainViewController]);
    
    if (mainControllerIsVisibleController) {
        YoTipController *vc = [[YoTipController alloc] initWithNibName:@"YoTipController" bundle:nil];
        [mainViewController addChildViewController:vc];
        vc.view.frame = CGRectMake(mainViewController.view.right - 50 - 24, 24, 50, 50);
        [mainViewController.view addSubview:vc.view];
        [vc showTipButton];
        vc.tipKey = key;
        vc.tipText = text;
    }
    // else (this tip will be shown when its nexst requested and the maincontroller is on top)
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[APPDELEGATE mainController] viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.okButton.disableRoundedCorners = YES;
    self.okButton.layer.masksToBounds = YES;
    
    self.view.layer.masksToBounds = NO;
    self.view.layer.shadowOffset = CGSizeMake(0.0f, 12.0f);
    self.view.layer.shadowRadius = 3.0f;
    self.view.layer.shadowOpacity = 0.5f;
    self.view.layer.borderColor = self.view.backgroundColor.CGColor;
    self.view.layer.borderWidth = 0.0f;
    self.view.layer.cornerRadius = 5.0;
    
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:self.okButton.bounds
                                     byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                           cornerRadii:CGSizeMake(10.0, 10.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.tipView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.okButton.layer.mask = maskLayer;
    
    self.tipView.layer.masksToBounds = NO;
    self.tipView.layer.shadowOffset = CGSizeMake(0.0f, 12.0f);
    self.tipView.layer.shadowRadius = 3.0f;
    self.tipView.layer.shadowOpacity = 0.5f;
    self.tipView.layer.borderColor = self.view.backgroundColor.CGColor;
    self.tipView.layer.borderWidth = 0.0f;
    self.tipView.layer.cornerRadius = 10.0;
}

- (void)showTipButton {
    [self showView:self.view];
}

- (IBAction)tipButtonTapped:(id)sender {
    YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Yo Tip" desciption:self.tipText];
    alert.userActionRequired = YES;
    [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:^{
        [self okButtonTapped:nil];
    }]];
    UIViewController *vc = [APPDELEGATE mainController];
    [[YoAlertManager sharedInstance] showAlert:alert onViewController:vc completionBlock:nil];
    
    [self hideView:self.view completion:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:self.tipKey];
}

- (void)showView:(UIView *)view {
    view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:2.0
                          delay:0
         usingSpringWithDamping:0.2
          initialSpringVelocity:6.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

- (void)hideView:(UIView *)view completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:0.2
                     animations:^{
                         view.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [view removeFromSuperview];
                         if (completion) {
                             completion(YES);
                         }
                     }];
}

- (IBAction)okButtonTapped:(id)sender {
    [self hideView:self.containerView completion:^(BOOL finished) {
        [self removeFromParentViewController];
        alreadyShowingTip = NO;
    }];
}

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    [self okButtonTapped:self.okButton];
}

@end
