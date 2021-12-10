//
//  YoLoginViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/2/15.
//
//

#import "YoLoggedOutViewController.h"
#import <SwipeView/SwipeView.h>
#import "YoLoginStoryboardIdentifiers.h"
#import "YoSignupViewController.h"
#import "YoLoginViewController.h"
#import "YoRecoverAccountViewController.h"
#import "YoMainNavigationController.h"
#import "YoViewContollerTransitionDelegate.h"
#import "YoConfigManager.h"
#import "YoLabel.h"
#import "YoButton.h"
#import "YoCardTransitionAnimator.h"


@interface YoLoggedOutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *desciptionLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *userInputView;

@property (weak, nonatomic) IBOutlet SwipeView *megaBannerSwipeView;
@property (weak, nonatomic) IBOutlet UIPageControl *megaBannerPageControl;
@property (strong, nonatomic) NSTimer *megaBannerTimer;
@property (weak, nonatomic) UIView *actionContainerView;
@property (nonatomic, strong) NSArray *sampleYoImages;
@property (nonatomic, strong) YoViewContollerTransitionDelegate *formTransitioningDelegate;
@property (nonatomic, strong) NSArray *yoWelcomeSlideTitles;
@end

#define kTagImageView 33524
#define kTagLabel 32324
@interface YoLoggedOutViewController (SwipeViewDelegate) <SwipeViewDataSource, SwipeViewDelegate>
- (void)setupMegaBanner;
- (void)reloadBanners;
- (void)pauseBannerAutoScroll;
- (void)resumeBannerAutoScroll;
@end


@interface YoLoggedOutViewController (YoFormDelegate) <YoFormControllerDelegate>
@end

@implementation YoLoggedOutViewController

#pragma mark Lazy Loading

- (YoViewContollerTransitionDelegate *)formTransitioningDelegate {
    if (!_formTransitioningDelegate) {
        _formTransitioningDelegate = [YoViewContollerTransitionDelegate new];
    }
    return _formTransitioningDelegate;
}

#pragma mark Life

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
     [self.navigationController setNavigationBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLoginNotification:) name:kYoUserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidSignupNotification:) name:kYoUserDidSignupNotification object:nil];
    
   /* self.userInputView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    [self setupMenu];
    [self setupMegaBanner];
    [self reloadBanners];
    [self resetTitleAndDescription];
    
    self.yoWelcomeSlideTitles = [[YoConfigManager sharedInstance] getTitlesForWelcomeScreen];
    __weak YoLoggedOutViewController *weakSelf = self;
    [[YoConfigManager sharedInstance] updateWithCompletionHandler:^(BOOL sucess) {
        weakSelf.yoWelcomeSlideTitles = [[YoConfigManager sharedInstance] getTitlesForWelcomeScreen];
        [weakSelf reloadBanners];
        [weakSelf resetTitleAndDescription];
    }];*/
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self resumeBannerAutoScroll];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self pauseBannerAutoScroll];
}

- (void)resetTitleAndDescription {
    NSString *title = [[YoConfigManager sharedInstance] getWelcomeScreenTitle];
    NSString *description = [[YoConfigManager sharedInstance] getWelcomeScreenDescription];
    self.titleLabel.text = title;
    self.desciptionLabel.text = description;
}

- (void)setupMenu {
    CGFloat menuWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat menuHeight = 8.0f/18.0f * CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGFloat menuYCoordinate = CGRectGetMaxY([[UIScreen mainScreen] bounds]) - menuHeight;
    CGRect menuFrame = CGRectMake(0.0f, menuYCoordinate, menuWidth, menuHeight);
    
    UIView *menuContainerView = [[UIView alloc] initWithFrame:menuFrame];
    menuContainerView.backgroundColor = [UIColor clearColor];
    
    // signup button
    YoButton *signupButton = [YoButton new];
    signupButton.translatesAutoresizingMaskIntoConstraints = NO;
    signupButton.backgroundColor = [UIColor colorWithHexString:PETER];
    signupButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:18.0f];
    signupButton.titleLabel.textColor = [UIColor whiteColor];
    [signupButton setTitle:NSLocalizedString(@"signup", nil).capitalizedString forState:UIControlStateNormal];
    [signupButton addTarget:self action:@selector(signUpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuContainerView addSubview:signupButton];
    
    // login button
    YoButton *loginButton = [YoButton new];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    loginButton.backgroundColor = [UIColor colorWithHexString:PETER];
    loginButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:18.0f];
    loginButton.titleLabel.textColor = [UIColor whiteColor];
    [loginButton setTitle:NSLocalizedString(@"login", nil).capitalizedString forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuContainerView addSubview:loginButton];
    
    // login button
    YoButton *loginWithFacebookButton = [YoButton new];
    loginWithFacebookButton.translatesAutoresizingMaskIntoConstraints = NO;
    loginWithFacebookButton.backgroundColor = [UIColor colorWithHexString:FacebookBlue];
    loginWithFacebookButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:18.0f];
    loginWithFacebookButton.titleLabel.textColor = [UIColor whiteColor];
    [loginWithFacebookButton setTitle:NSLocalizedString(@"Continue with Facebook", nil) forState:UIControlStateNormal];
    [loginWithFacebookButton addTarget:self action:@selector(loginWithFacebookButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuContainerView addSubview:loginWithFacebookButton];
    
    // forgot password button
    YoButton *forgotPasswordButton = [YoButton new];
    forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
    forgotPasswordButton.backgroundColor = [UIColor clearColor];
    forgotPasswordButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:18.0f];
    forgotPasswordButton.titleLabel.textColor = [UIColor whiteColor];
    [forgotPasswordButton setTitle:NSLocalizedString(@"forgot password?", nil).capitalizedString forState:UIControlStateNormal];
    [forgotPasswordButton addTarget:self action:@selector(forgotPasswordButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuContainerView addSubview:forgotPasswordButton];
    
    // constraints
    CGFloat bottomPadding = menuHeight / 8.0f;
    CGFloat buttonPadding = 16.0f;
    //CGFloat buttonHeight = 50.0f;
    CGFloat buttonSidePadding = 30.0f;
    NSDictionary *metrics = @{@"bottomPadding":@(bottomPadding),
                              @"buttonPadding":@(buttonPadding),
                              /* @"buttonHeight":@(buttonHeight), */
                              @"buttonSidePadding":@(buttonSidePadding)};
    
    NSDictionary *views = NSDictionaryOfVariableBindings(signupButton, loginButton, loginWithFacebookButton, forgotPasswordButton);
    
    [menuContainerView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|-(buttonSidePadding)-[signupButton]-(buttonSidePadding)-|"
      options:0 metrics:metrics views:views]];
    
    [menuContainerView addConstraint:
     [NSLayoutConstraint
      constraintWithItem:signupButton attribute:NSLayoutAttributeHeight
      relatedBy:NSLayoutRelationEqual
      toItem:menuContainerView attribute:NSLayoutAttributeHeight
      multiplier:3.0f/16.0f constant:0.0f]];
    
    [menuContainerView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:[signupButton]-(buttonPadding)-[loginButton(signupButton)]-(buttonPadding)-[loginWithFacebookButton(signupButton)]-(buttonPadding)-[forgotPasswordButton(signupButton)]-(bottomPadding)-|"
      options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
      metrics:metrics views:views]];
    
    [self.view addSubview:menuContainerView];
    self.actionContainerView = menuContainerView;
}

#pragma mark - Notifications

- (void)userDidLoginNotification:(NSNotification *)notification {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidSignupNotification:(NSNotification *)notification {
//    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
//        [APPDELEGATE.navigationController presentPhoneVerificationFlow];
//    }];
}

#pragma mark Internal Navigation

- (void)transitionToControllerState:(YoViewControllerState)controllerState withCompletionBlock:(void (^)())block {
    void (^replyToBlock)() = ^() {
        if (block) {
            block();
        }
    };
    
    if (self.controllerState == controllerState) {
        replyToBlock();
        return;
    }
    
    _controllerState = controllerState;
    
    switch (controllerState) {
        case YoViewControllerStateActive:
        {
            self.view.userInteractionEnabled = YES;
            
            // scroll to active section
            [self.scrollView setContentOffset:CGPointZero animated:YES];
            
            // bring back menu options
            [self showMenu];
        }
            break;
            
        case YoViewControllerStateIdle:
        {
            self.view.userInteractionEnabled = NO;
            
            // hide menu options
            [self hideMenu];
            
            // scroll to idle section
            [self.scrollView setContentOffset:self.userInputView.origin animated:YES];
        }
            break;
    }
    
    // calculate delay based on scroll speed and height of megatron view
    NSTimeInterval duration = 0.3;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        replyToBlock();
    });
}

- (void)showMenu {
    self.actionContainerView.hidden = NO;
    
    CGFloat menuCenterX = self.actionContainerView.center.x;
    CGFloat menuCenterY = CGRectGetMaxY([[UIScreen mainScreen] bounds]) - self.actionContainerView.height/2.0f;
    
    __weak YoLoggedOutViewController *weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:0.6 options:0 animations:^{
        weakSelf.actionContainerView.center = CGPointMake(menuCenterX, menuCenterY);
    } completion:nil];
}

- (void)hideMenu {
    CGFloat menuHiddenCenterX = self.actionContainerView.center.x;
    CGFloat menuHiddenCenterY = CGRectGetMaxY([[UIScreen mainScreen] bounds]) + self.actionContainerView.height/2.0f;
    
    __weak YoLoggedOutViewController *weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:0.6 options:0 animations:^{
        weakSelf.actionContainerView.center = CGPointMake(menuHiddenCenterX, menuHiddenCenterY);
    } completion:^(BOOL finished) {
        weakSelf.actionContainerView.hidden = YES;
    }];
}

#pragma mark Navigation

- (void)showNewAccountFormWithCompletionBlock:(void (^)())block {
    [self performSegueWithIdentifier:YoSegueToSignup sender:self];
}

- (void)showLoginFormWithCompletionBlock:(void (^)())block {
    [self performSegueWithIdentifier:YoSegueToLogin sender:self];
}

- (void)showRecoverAccountFormWithCompletionBlock:(void (^)())block {
    [self performSegueWithIdentifier:YoSegueToRecoverAccount sender:self];
}

- (void)presentFormController:(UIViewController *)viewController completionBlock:(void (^)())block {
    if (self.controllerState != YoViewControllerStateActive) {
        DDLogWarn(@"%@ | Error - Attempt to present form while in idle state", NSStringFromClass([self class]));
        return;
    }
        
    __weak YoLoggedOutViewController *weakSelf = self;
    [self transitionToControllerState:YoViewControllerStateIdle withCompletionBlock:^{
        viewController.modalTransitionStyle = UIModalPresentationCustom;
        viewController.transitioningDelegate = self;
        [weakSelf showBlurredBackgroundWithViewController:viewController];
    }];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:YoSegueToSignup] ||
        [segue.identifier isEqualToString:YoSegueToLogin] ||
        [segue.identifier isEqualToString:YoSegueToRecoverAccount]) {
        UIViewController *desinationViewController = [segue destinationViewController];
        if ([desinationViewController isKindOfClass:[UINavigationController class]]) {
            desinationViewController = [[(UINavigationController *)desinationViewController viewControllers] firstObject];
        }
        if ([desinationViewController isKindOfClass:[YoFormViewController class]]) {
            YoFormViewController *formViewController = (YoFormViewController *)desinationViewController;
            formViewController.delegate = self;
        }
    }
}

//- (IBAction)unwindToLoginViewController:(UIStoryboardSegue *)segue {
//    // take any needed data from the outgoing view controller
//}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    YoTransitionAnimator *transitionAnimator = nil;
    UIViewController *keyViewController = presented;
    if ([keyViewController isKindOfClass:[UINavigationController class]]) {
        keyViewController =  [[(UINavigationController *)keyViewController viewControllers] firstObject];
    }
    if ([keyViewController isKindOfClass:[YoFormViewController class]]) {
        transitionAnimator = [YoCardTransitionAnimator new];
    }
    [transitionAnimator setTransition:YoPresentatingTransition];
    return transitionAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    YoTransitionAnimator *transitionAnimator = nil;
    UIViewController *keyViewController = dismissed;
    if ([keyViewController isKindOfClass:[UINavigationController class]]) {
        keyViewController =  [[(UINavigationController *)keyViewController viewControllers] firstObject];
    }
    if ([keyViewController isKindOfClass:[YoFormViewController class]]) {
        transitionAnimator = [YoCardTransitionAnimator new];
    }
    [transitionAnimator setTransition:YoDismissingTransition];
    return transitionAnimator;
}

#pragma mark Actions

- (IBAction)signUpButtonTapped:(UIButton *)sender {
    [self showNewAccountFormWithCompletionBlock:nil];
}

- (IBAction)loginButtonTapped:(UIButton *)sender {
    [self showLoginFormWithCompletionBlock:nil];
}

- (IBAction)loginWithFacebookButtonTapped:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak YoLoggedOutViewController *weakSelf = self;
    [[YoApp currentSession] loginWithFacebookCompletionBlock:^(BOOL success) {
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
    }];
}

- (IBAction)forgotPasswordButtonTapped:(UIButton *)sender {
    [self showRecoverAccountFormWithCompletionBlock:nil];
}

#pragma mark Getters

- (NSArray *)sampleYoImages {
    if (!_sampleYoImages) {
        _sampleYoImages = @[[UIImage imageNamed:@"speechBubble-00"],
                            [UIImage imageNamed:@"speechBubble-01"],
                            [UIImage imageNamed:@"speechBubble-02"],
                            [UIImage imageNamed:@"speechBubble-03"],
                            [UIImage imageNamed:@"speechBubble-04"]];
    }
    return _sampleYoImages;
}

@end

#pragma mark - YoFormControllerDelegate
@implementation YoLoggedOutViewController (YoFormDelegate)

- (void)formControllerDidDismiss:(YoFormViewController *)formController {
    if (![[YoApp currentSession] isLoggedIn]) {
        __weak YoLoggedOutViewController *weakSelf = self;
        [self transitionToControllerState:YoViewControllerStateActive withCompletionBlock:^{
            [weakSelf resumeBannerAutoScroll];
        }];
    }
}

@end

#pragma mark - SwipeViewDelegate
@implementation YoLoggedOutViewController (SwipeViewDelegate)

#pragma mark Utility
- (void)setupMegaBanner {
    self.megaBannerSwipeView.pagingEnabled = YES;
    self.megaBannerSwipeView.delegate = self;
    self.megaBannerSwipeView.dataSource = self;
    self.megaBannerSwipeView.itemsPerPage = 1;
    self.megaBannerSwipeView.wrapEnabled = YES;
    self.megaBannerSwipeView.backgroundColor = [UIColor clearColor];
}

- (void)reloadBanners {
    self.megaBannerPageControl.numberOfPages = self.yoWelcomeSlideTitles.count;
    self.megaBannerPageControl.hidden = (self.megaBannerPageControl.numberOfPages<2)?YES:NO;
    [self resetBannerTimer];
    [self.megaBannerSwipeView reloadData];
}

- (void)resetBannerTimer {
    [self.megaBannerTimer invalidate];
    self.megaBannerTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(nextBanner) userInfo:nil repeats:YES];
}

- (void)nextBanner {
    if (!self.megaBannerSwipeView.isScrolling) {
        NSInteger currentItemIndex = self.megaBannerSwipeView.currentItemIndex;
        [self.megaBannerSwipeView scrollToItemAtIndex:(currentItemIndex + 1) duration:0.6];
    }
}

#pragma mark External Utiltiy

- (void)pauseBannerAutoScroll {
    [self.megaBannerTimer invalidate];
}

- (void)resumeBannerAutoScroll {
    [self resetBannerTimer];
}

#pragma mark Internal

- (NSString *)getTitleForSlideAtIndex:(NSInteger)index {
    NSArray *titles = self.yoWelcomeSlideTitles;
    NSString *title = nil;
    if (titles.count) {
        title = titles[index%titles.count];
    }
    return (index<titles.count)?title:nil;
}

#pragma mark Delegate
- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView {
    // pull yo descriptions form web. Present speach bubbles to the user
    // according the number of speach bubbles available.
    return self.yoWelcomeSlideTitles.count;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    swipeView.alignment = SwipeViewAlignmentEdge;
    if (!view) {
        view = [[UIView alloc] initWithFrame:self.megaBannerSwipeView.frame];
        view.autoresizingMask = self.megaBannerSwipeView.autoresizingMask;
        view.backgroundColor = [UIColor clearColor];
        
        CGFloat screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        
        CGFloat height = screenHeight * 3.0f/18.0f;
        CGFloat width = height * 8.0f/3.0f;
        CGFloat yCoordinate = view.height * 2.0f/5.0f;
        CGFloat xCoordinate = screenWidth/2.0f - width/2.0f;
        CGRect imageFrame = CGRectMake(xCoordinate, yCoordinate, width, height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageFrame];
        imageView.autoresizingMask = view.autoresizingMask;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.tag = kTagImageView;
        
        YoLabel *speechBubbleLabel = [YoLabel new];
        speechBubbleLabel.text = [self getTitleForSlideAtIndex:index];
        speechBubbleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:13.0f];
        speechBubbleLabel.numberOfLines = 0;
        speechBubbleLabel.textAlignment = NSTextAlignmentCenter;
        speechBubbleLabel.textColor = [UIColor whiteColor];
        speechBubbleLabel.adjustsFontSizeToFitWidth = YES;
        speechBubbleLabel.minimumScaleFactor = 0.1f;
        speechBubbleLabel.edgeInsets = UIEdgeInsetsMake(12.0f,
                                                        12.0f,
                                                        12.0f,
                                                        12.0f);
        CGFloat speechBubbleWidth = imageView.width;
        CGFloat speechBubbleHeight = imageView.height * 2.0f/3.0f;
        speechBubbleLabel.frame = CGRectMake(0.0f,
                                             0.0f,
                                             speechBubbleWidth,
                                             speechBubbleHeight);
        speechBubbleLabel.autoresizingMask = imageView.autoresizingMask;
        speechBubbleLabel.tag = kTagLabel;
        [imageView addSubview:speechBubbleLabel];
        
        [view addSubview:imageView];
    }
    
    UIImageView *imageView = (UIImageView *)[view viewWithTag:kTagImageView];
    NSInteger relativeIndex = index%self.sampleYoImages.count;
    UIImage *image = self.sampleYoImages[relativeIndex];
    [imageView setImage:image];
    
    UILabel *speechBubbleLabel = (UILabel *)[view viewWithTag:kTagLabel];
    NSString *text = [self getTitleForSlideAtIndex:index];
    speechBubbleLabel.text = text;
    
    return view;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView {
    self.megaBannerPageControl.currentPage = swipeView.currentItemIndex;
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView {
    [self resetBannerTimer];
}

@end

