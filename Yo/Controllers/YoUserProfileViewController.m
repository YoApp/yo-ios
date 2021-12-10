//
//  YoUserProfileController.m
//  Yo
//
//  Created by Or Arbel on 5/15/15.
//
//

#import "YoUserProfileViewController.h"
#import "NSDate_Extentions.h"

@interface YoUserProfileViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet YoLabel *yoCountLabel;
@property (weak, nonatomic) IBOutlet YoLabel *lastReceivedYoTitleLabel;
@property (weak, nonatomic) IBOutlet YoLabel *lastReceivedYoDateLabel;

@property (weak, nonatomic) IBOutlet YoButton *hideButton;
@property (weak, nonatomic) IBOutlet YoButton *blockButton;


@property (weak, nonatomic) UIActionSheet *blockActionSheet;
@property (weak, nonatomic) UIActionSheet *hideActionSheet;
@end

@implementation YoUserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self performInitialSetup];
}

- (void)performInitialSetup {
    self.view.backgroundColor = [UIColor clearColor];
    
    self.blockButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    self.blockButton.disableRoundedCorners = YES;
    self.hideButton.disableRoundedCorners = YES;
    
    self.lastReceivedYoTitleLabel.text = NSLocalizedString(@"last yo:", nil).capitalizedString;
    
    [self configureForUser:self.user];
    
    [[YoUser me].contactsManager fetchProfileForUsername:self.user.username withCompletionBlock:^(NSDictionary *rawObject) {
        if (rawObject) {
            YoUser *user = [YoUser objectFromDictionary:rawObject];
            [self configureForUser:user];
        }
        else {
            DDLogError(@"Failed to fetch user with username: %@", self.user.username);
        }
    }];
}

- (void)configureForUser:(YoUser *)user {
    [self.profileImageView setImageWithURL:user.photoURL
                          placeholderImage:[UIImage imageNamed:@"new_action_profileedit"]];
    NSString *fullNameText;
    if (user.fullName.length > 0) {
        fullNameText = user.fullName;
    }
    else if (user.firstName && user.lastName) {
        fullNameText = MakeString(@"%@ %@", user.firstName, user.lastName);
    }
    else if (user.firstName) {
        fullNameText = MakeString(@"%@", user.firstName);
    }
    else if (user.firstName) {
        fullNameText = MakeString(@"%@", user.lastName);
    }
    else {
        fullNameText = NSLocalizedString(@"---", nil).capitalizedString;
    }
    self.fullNameLabel.text = fullNameText;
    self.usernameLabel.text = user.username;
    self.yoCountLabel.text = [user yoCountString];
    if (user.lastYoStatus && user.lastYoDate) {
        self.lastReceivedYoDateLabel.text = MakeString(@"%@ %@", [[user getStatusStringForStatus:user.lastYoStatus] capitalizedString], [user.lastYoDate agoString]);
    }
    
    self.lastReceivedYoTitleLabel.verticalAlignment = YoLabelVerticalAlignmentBottom;
    self.lastReceivedYoDateLabel.verticalAlignment = YoLabelVerticalAlignmentTop;
}

#pragma mark - Gestures

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    if (!CGRectContainsPoint(self.userProfileView.frame, touchPoint)) {
        [self close];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.destructiveButtonIndex == buttonIndex) {
        if ([actionSheet isEqual:self.blockActionSheet]) {
            [self blockUser];
        }
        else if ([actionSheet isEqual:self.hideActionSheet]) {
            [self hideUser];
        }
    }
}

#pragma mark - IBActions

- (IBAction)didPressCloseButton:(UIButton *)sender {
    [self close];
}

- (IBAction)didTapHideButton:(UIButton *)sender {
    NSString *title = NSLocalizedString(@"Hide %@ from your recents list?", nil);
    title = MakeString(title, self.user.displayName.length?self.user.displayName:self.user.username);
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"cancel", nil).capitalizedString
                                               destructiveButtonTitle:NSLocalizedString(@"Hide", nil)
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    self.hideActionSheet = actionSheet;
}

- (IBAction)didTapBlockButton:(UIButton *)sender {
    NSString *title = NSLocalizedString(@"Are you sure you want to block\n%@?", nil);
    title = MakeString(title, self.user.fullName.length?self.user.fullName:self.user.username);
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"cancel", nil).capitalizedString
                                               destructiveButtonTitle:NSLocalizedString(@"block", nil).capitalizedString
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    self.blockActionSheet = actionSheet;
}

#pragma mark - User Actions

- (void)blockUser {
    [[YoUser me].contactsManager removeObject:self.user localObjectOnly:YES withCompletionBlock:nil]; // @or: for better user experience, if calls fails we silently fail.
    [[YoUser me].contactsManager blockObject:self.user withCompletionBlock:nil]; // @or: TODO handle failure later
    [self close];
}

- (void)hideUser {
    [[YoUser me].contactsManager removeObject:self.user localObjectOnly:YES withCompletionBlock:nil]; // @or: for better user experience, if calls fails we silently fail.
    [[YoUser me].contactsManager removeObject:self.user withCompletionBlock:nil];  // @or: TODO handle failure later
    [self close];
}

#pragma mark - Setters

- (void)setUser:(YoUser *)user {
    _user = user;
    if (self.isViewLoaded) {
        [self configureForUser:user];
    }
}

@end
