//
//  YOMenuController.m
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YOMenuController.h"
#import "YOUsernamesPickerController.h"
#import "YoMainController.h"
#import "YoBlockedListViewController.h"
#import "YoEditProfileViewController.h"
#import "YoThisExtensionController.h"
#import "YoContextPickerController.h"

#import <Smooch/Smooch.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import "RavenClient.h"
#import "Appirater.h"
#import "YoContactManager.h"
#import "YoManager.h"
#import "YoCardTransitionAnimator.h"
#import "YoMenuTransitionAnimator.h"
#import "YOShareCell.h"
#import "YODoubleActionCell.h"
#import "YOEditCell.h"
#import "YoMenuFooter.h"
#import "YoMenuCell.h"
#import "MBProgressHUD.h"

#define YoMenuOptionYoStore @"YoMenuOptionYoStore"
#define YoMenuOptionHowTo @"YoMenuOptionHowTo"
#define YoMenuOptionInviteFacebook @"YoMenuOptionInviteFacebook"
#define YoMenuOptionPick @"YoMenuOptionPick"
#define YoMenuOptionBlocked @"YoMenuOptionBlocked"
#define YoMenuOptionChatWithUs @"YoMenuOptionChatWithUs"
#define YoMenuOptionFeedBack @"YoMenuOptionFeedBack"
#define YoMenuOptionDeleteAccount @"YoMenuOptionDeleteAccount"

#define YoMenuOptionBetaMenu @"YoMenuOptionBetaMenu"

#define kTagTextFieldUsername 324

#define CellToWindowHeightRatio 2.0f/18.0f

OptimizelyVariableKeyForString(YO_STORE, @"Yo Store");
OptimizelyVariableKeyForString(INVITE, @"Invite");

@interface YOMenuController () <UITextFieldDelegate, UIActionSheetDelegate>
@property(nonatomic, assign) int usersCount;
@property (nonatomic, assign) NSInteger showFeedbackMenuForIndex;
@property (nonatomic, assign) NSInteger showEditMenuForIndex;
@property (nonatomic, strong) NSArray *menuOptions;
@property (nonatomic, strong) NSMutableArray *blockedUsernames;

@property (weak, nonatomic) IBOutlet UIImageView *userProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userYoCountLabel;
@property (weak, nonatomic) IBOutlet UIView *footerView;

@property (weak, nonatomic) UIActionSheet *logoutActionSheeet;
@end

@interface YOMenuController (CustomTranistioning) <UIViewControllerTransitioningDelegate>
@end

static void *YoContext = &YoContext;

@implementation YOMenuController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    self.showFeedbackMenuForIndex = NSNotFound;
    self.showEditMenuForIndex = NSNotFound;
    
    [self.tableView reloadData];
    
    [self reloadUserData];
    
    [[YoApp currentSession] refreshUserProfileWithCompletionBlock:^(BOOL success) {
        if (success) {
            [self reloadUserData];
        }
    }];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.contentView.layer.masksToBounds = NO;
    self.contentView.layer.cornerRadius = 0.0;
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)setupUI{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"edit", nil).capitalizedString forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(editButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"logout", nil).capitalizedString forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(logoutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.view.layer.masksToBounds = NO;
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.navigationController.navigationBar.backgroundColor = self.view.backgroundColor;
    self.navigationItem.title = self.title;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithHexString:@"8842A8"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    [self addFooterToTableView];
    [self setupUserProfileView];
}

- (void)addFooterToTableView {
    YoMenuFooter *footerContent = LOAD_NIB(@"YoMenuFooter");
    footerContent.translatesAutoresizingMaskIntoConstraints = NO;
    footerContent.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.8f];
    
    CGFloat footerHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]) * 3.0f/36.0f;
    __weak YOMenuController *weakSelf = self;
    footerContent.downArrowPressedBlock = ^{
        [weakSelf close:nil];
    };
    UIEdgeInsets adjustedInsets = self.tableView.contentInset;
    adjustedInsets.bottom += footerHeight;
    self.tableView.contentInset = adjustedInsets;
    [self.footerView addSubview:footerContent];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(footerContent);
    [self.footerView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[footerContent]|"
      options:0 metrics:nil views:views]];
    [self.footerView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[footerContent]|"
      options:0 metrics:nil views:views]];
}

- (NSArray *)menuOptions {
    if (!_menuOptions) {
        NSMutableArray *menuOptions = [@[
                                        // YoMenuOptionYoStore,
                                         YoMenuOptionInviteFacebook,
                                         YoMenuOptionBlocked,
                                         YoMenuOptionHowTo,
                                         //YoMenuOptionChatWithUs,
                                         YoMenuOptionFeedBack,
                                         YoMenuOptionDeleteAccount] mutableCopy];
        
#ifdef IS_BETA
        [menuOptions insertObject:YoMenuOptionBetaMenu atIndex:([menuOptions count]-1)];
#endif
        
        _menuOptions = menuOptions;
    }
    return _menuOptions;
}

- (void)setupUserProfileView {
    self.userProfileImageView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapProfileViewWithGesture:)];
    [self.userProfileView addGestureRecognizer:tapGR];
    
    tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapProfileViewWithGesture:)];
    [self.navigationController.navigationBar addGestureRecognizer:tapGR];
}

- (void)reloadUserData {
    [self.userProfileImageView setImageWithURL:[YoApp currentSession].user.photoURL
                              placeholderImage:[self getPlaceholderImage]];
    self.userNameLabel.text = [YoUser me].displayName;
    self.userUsernameLabel.text = [YoUser me].username;
    self.userYoCountLabel.text = [[YoUser me] yoCountString];
}

- (UIImage *)getPlaceholderImage {
    return [UIImage imageNamed:@"new_action_profileedit"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.userProfileImageView.layer.masksToBounds = YES;
    self.userProfileImageView.layer.cornerRadius = 7.0;
    self.userProfileImageView.layer.borderColor = [UIColor colorWithHexString:@"8842A8"].CGColor;
    self.userProfileImageView.layer.borderWidth = 2.0;
}

#pragma mark UITableView

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.tag == kTagTextFieldUsername) {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:[string uppercaseString]];
        
        if (newText.length == 1) {
            NSCharacterSet *alphaSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"];
            BOOL valid = [[newText stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
            if ( ! valid) {
                return NO;
            }
        }
        
        NSCharacterSet *alphaNumericSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"];
        BOOL valid = [[newText stringByTrimmingCharactersInSet:alphaNumericSet] isEqualToString:@""];
        if ( ! valid) {
            return NO;
        }
        
        textField.text = newText;
        return NO;
    }
    return YES;
}

- (YODoubleActionCell *)createYOActionCellForIndexPath:(NSIndexPath *)indexPath {
    YODoubleActionCell *cell = LOAD_NIB(@"YODoubleActionCell");
    
    if (indexPath.row == [self.menuOptions indexOfObject:YoMenuOptionFeedBack]) {
        [cell.leftButton setTitle:NSLocalizedString(@"MAIL", nil).lowercaseString.capitalizedString forState:UIControlStateNormal];
        [cell.rightButton setTitle:NSLocalizedString(@"RATE", @"As to rate, rating, review").lowercaseString.capitalizedString forState:UIControlStateNormal];
    }
    __weak YOMenuController *weakSelf = self;
    cell.leftBlock = ^{
        if (indexPath.row == [weakSelf.menuOptions indexOfObject:YoMenuOptionFeedBack]) {
            weakSelf.showFeedbackMenuForIndex = NSNotFound;
            weakSelf.showFeedbackMenuForIndex = NSNotFound;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            [weakSelf feedback];
        }
    };
    
    cell.rightBlock = ^{
        if (indexPath.row == [weakSelf.menuOptions indexOfObject:YoMenuOptionFeedBack]) {
            weakSelf.showFeedbackMenuForIndex = NSNotFound;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                                   desciption:NSLocalizedString(@"Do you like the Yo app?", nil)];
            [yoAlert addAction:
             [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Nah", nil)
                                         tapBlock:^{
                                             [weakSelf feedbackWithBodyText:NSLocalizedString(@"Tell us how we can improve:", nil)];
                                         }]];
            [yoAlert addAction:
             [[YoAlertAction alloc] initWithTitle:MakeString(@"%@%@", NSLocalizedString(@"Yes", nil), @"!")
                                         tapBlock:^{
                                             [Appirater rateApp];
                                         }]];
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
        }
    };
    
    UISwipeGestureRecognizer *swipeGr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightDetected:)];
    [swipeGr setDirection:UISwipeGestureRecognizerDirectionRight];
    [cell addGestureRecognizer:swipeGr];
    
    return cell;
}

- (void)swipeRightDetected:(UISwipeGestureRecognizer *)swipeGr {
    NS_DURING
    YOCell *cell = (YOCell *)swipeGr.view;
    
    self.showShareMenuForIndexPath = nil;
    self.showEditMenuForIndex = NSNotFound;
    self.showFeedbackMenuForIndex = NSNotFound;
    NSInteger index = [self.tableView indexPathForCell:cell].row;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    NS_HANDLER
    NS_ENDHANDLER
}

- (IBAction)close:(id)sender {
    [self closeWithCompletionBlock:nil];
}

- (void)closeWithCompletionBlock:(void (^)())block {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (block) {
            block();
        }
    }];
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight([[UIScreen mainScreen] bounds]) * CellToWindowHeightRatio;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.showFeedbackMenuForIndex == indexPath.row) {
        return [self createYOActionCellForIndexPath:indexPath];
    }
    
    YoMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YoMenuCell"];
    if (cell == nil) {
        cell = LOAD_NIB(@"YoMenuCell");
        cell.contentView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (IS_OVER_IOS(8.0)) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }
    
    NSString *menuOption = [self.menuOptions objectAtIndex:indexPath.row];
    
    if ([menuOption isEqualToString:YoMenuOptionHowTo]) {
        cell.menuTitle = NSLocalizedString(@"FAQ", nil);
    }
    else if ([menuOption isEqualToString:YoMenuOptionYoStore]) {
        cell.menuTitle = [Optimizely stringForKey:YO_STORE];;
    }
    else if ([menuOption isEqualToString:YoMenuOptionInviteFacebook]) {
        cell.menuTitle = [Optimizely stringForKey:INVITE];
    }
    else if ([menuOption isEqualToString:YoMenuOptionBlocked]) {
        cell.menuTitle = NSLocalizedString(@"UNBLOCK", nil).lowercaseString.capitalizedString;
    }
    else if ([menuOption isEqualToString:YoMenuOptionChatWithUs]) {
        cell.menuTitle = NSLocalizedString(@"chat with us", nil).capitalizedString;
    }
    else if ([menuOption isEqualToString:YoMenuOptionFeedBack]) {
        cell.menuTitle = NSLocalizedString(@"FEEDBACK", nil).lowercaseString.capitalizedString;
    }
    else if ([menuOption isEqualToString:YoMenuOptionDeleteAccount]) {
        cell.menuTitle = NSLocalizedString(@"Delete Account", nil).lowercaseString.capitalizedString;
    }
    else if ([menuOption isEqualToString:YoMenuOptionBetaMenu]) {
        cell.menuTitle = @"Version Info";
    }
    else if ([menuOption isEqualToString:YoMenuOptionPick]) {
        cell.menuTitle = @"Pick Yo Types";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performActionForCellAtIndexPath:indexPath];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:YoSegueToUnblock]) {
        YoBlockedListViewController *vc = [segue destinationViewController];
        vc.blockedUsernames = self.blockedUsernames;
    }
}

- (void)performActionForCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *YoMenuOption = [self.menuOptions objectAtIndex:indexPath.row];
    
    if ([YoMenuOption isEqualToString:YoMenuOptionHowTo]) {
        [self presentBrowserWithURLString:@"http://faq.justyo.co"];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionPick]) {
        [self showYoPicker];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionInviteFacebook]) {
        [Optimizely trackEvent:@"User Tapped Invite"];
        [self inviteTapped];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionYoStore]) {
        [Optimizely trackEvent:@"User Tapped Yo Store"];
        [self showYoStore];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionChatWithUs]) {
        [SKTUser currentUser].firstName = [[YoUser me] username];
        [Smooch show];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionBlocked]) {
        ButtonTapped(@"unblock");
        YoBlockedListViewController *unblockVC = [self.storyboard instantiateViewControllerWithIdentifier:YoBlockedControllerID];
        unblockVC.modalPresentationStyle = UIModalPresentationCustom;
        unblockVC.transitioningDelegate = self;
        unblockVC.blockedUsernames = self.blockedUsernames;
        [self showBlurredBackgroundWithViewController:unblockVC];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionFeedBack]) {
        self.showFeedbackMenuForIndex = indexPath.row;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
    else if ([YoMenuOption isEqualToString:YoMenuOptionDeleteAccount]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete your account?", nil)
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil).capitalizedString
                                                   destructiveButtonTitle:NSLocalizedString(@"DELETE", nil).lowercaseString.capitalizedString
                                                        otherButtonTitles:nil];
        actionSheet.tag = 3;
        [actionSheet showInView:self.view];
    }
    
    
    else if ([YoMenuOption isEqualToString:YoMenuOptionBetaMenu]) {
        NSString *title = @"Yo Beta";
        NSString *clientVersionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        clientVersionNumber = MakeString(@"Version Number: %@", clientVersionNumber);
        NSString *internalVersionNumber = MakeString(@"Internal Version Number: %@", INTERNAL_VERSION_NUMBER);
        NSString *releaseCandidateNumber = MakeString(@"Release Candidate Number: %@", RELEASE_CANDIDATE_NUMBER);
        NSString *description = MakeString(@"%@\n%@\n%@", clientVersionNumber, internalVersionNumber, releaseCandidateNumber);
        
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:title desciption:description];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Dismiss", nil)
                                     tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}

- (void)logoutButtonPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to logout?", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"cancel", nil).capitalizedString
                                               destructiveButtonTitle:NSLocalizedString(@"LOGOUT", nil).lowercaseString.capitalizedString
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    self.logoutActionSheeet = actionSheet;
}

- (IBAction)editButtonPressed:(id)sender {
    [self presentEditProfileView];
}

- (void)showYoPicker {
    YoContextPickerController *vc = [[YoContextPickerController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)inviteTapped {
    YoThisExtensionController *shareSheet = [YoThisExtensionController new];
    
    NSString *message = MakeString(@"Yo get this app and add me www.justyo.co");
    
    if ([[YoiOSAssistant sharedInstance] canOpenWhatsApp]) {
        YoTableViewAction *shareOnWhatsApp = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"WhatsApp", nil) tapBlock:^{
            [shareSheet dissmiss];
            [[YoiOSAssistant sharedInstance] openWhatsAppToShareText:message];
            [YoAnalytics logEvent:YoEventInvited withParameters:@{YoParam_SHARE_OPTION:@"whatsapp"}];
        }];
        
        [shareSheet addAction:shareOnWhatsApp];
    }
    
    if ([[YoiOSAssistant sharedInstance] canSendSMSText]) {
        
        YoTableViewAction *action = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"SMS", nil) tapBlock:^{
            [shareSheet dissmiss];
            [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:@[]
                                                                           text:message
                                                                    resultBlock:nil];
            [YoAnalytics logEvent:YoEventInvited withParameters:@{YoParam_SHARE_OPTION:@"sms"}];
        }];
        
        [shareSheet addAction:action];
    }
    
    YoTableViewAction *action = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Facebook", nil) tapBlock:^{
        [shareSheet dissmiss];
        [self inviteViaFacebook];
        [YoAnalytics logEvent:YoEventInvited withParameters:@{YoParam_SHARE_OPTION:@"facebook"}];
    }];
    
    [shareSheet addAction:action];
    [shareSheet showOnView:self.view];
}

- (void)showYoStore {
    if ([APPDELEGATE hasInternet]) {
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoStoreStoryboard bundle:nil];
        UIViewController *storeController = [mainStoryBoard instantiateInitialViewController];
        YoNavigationController *navController = [[YoNavigationController alloc] initWithRootViewController:storeController];
        storeController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:navController animated:YES completion:nil];
    }
    else {
        [APPDELEGATE checkInternet];
    }
}

- (void)feedback {
    [self feedbackWithBodyText:@""];
}

- (void)feedbackWithBodyText:(NSString *)body{
    [[YoiOSAssistant sharedInstance] presentEmailControllerWithRecipients:@[@"feedback@justyo.co"] subject:NSLocalizedString(@"Yo - I got some feedback", nil) body:body?:@"" resultBlock:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 3) {
        [[[YoApp currentSession] yoAPIClient] POST:@"rpc/delete_my_account"
                                        parameters:nil
                                           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                                               [UIAlertView showWithTitle:nil
                                                                  message:@"Your account is now deleted."
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:@[]
                                                                 tapBlock:nil];
            [[YoApp currentSession] logout];
        } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            
        }];
    }
    else if ([actionSheet isEqual:self.logoutActionSheeet] &&
        actionSheet.destructiveButtonIndex == buttonIndex) {
        [[YoApp currentSession] logout];
    }
}

#pragma mark Actions

- (void)userDidTapProfileViewWithGesture:(UIGestureRecognizer *)tapGR {
    if (self.navigationController && [self.navigationController.topViewController isEqual:self] == NO) {
        return;
    }
    [self presentEditProfileView];
}

- (void)presentEditProfileView {
    YoEditProfileViewController *editProfileVC = [self.storyboard instantiateViewControllerWithIdentifier:YoEditProfileViewControllerID];
    editProfileVC.modalPresentationStyle = UIModalPresentationCustom;
    editProfileVC.transitioningDelegate = self;
    [self showBlurredBackgroundWithViewController:editProfileVC];
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        CGFloat maxOffset = 80.0f + self.tableView.contentInset.bottom/2.0f;
        if (scrollView.contentOffset.y > maxOffset) {
            [self close:nil];
        }
    }
}

@end


@implementation YOMenuController (CustomTranistioning)

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    YoTransitionAnimator *transitionAnimator = nil;
    if ([source isKindOfClass:[YOMenuController class]]) {
        transitionAnimator = [YoCardTransitionAnimator new];
    }
    else {
        transitionAnimator = [YoMenuTransitionAnimator new];
    }
    [transitionAnimator setTransition:YoPresentatingTransition];
    return transitionAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    YoTransitionAnimator *transitionAnimator = nil;
    UIViewController *keyViewController = dismissed;
    if ([keyViewController isKindOfClass:[YoNavigationController class]]) {
        transitionAnimator = [YoMenuTransitionAnimator new];
    }
    else {
        transitionAnimator = [YoCardTransitionAnimator new];
    }    [transitionAnimator setTransition:YoDismissingTransition];
    return transitionAnimator;
}

@end
