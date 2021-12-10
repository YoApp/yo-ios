//
//  YoEditProfileViewController.m
//  Yo
//
//  Created by Peter Reveles on 5/19/15.
//
//

#import "YoEditProfileViewController.h"
#import "YOTextField.h"
#import "YOFacebookManager.h"

@interface YoEditProfileViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *actionsView;

@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@property (weak, nonatomic) IBOutlet UIView *editPasswordView;
@property (weak, nonatomic) IBOutlet UIScrollView *editProfileView;

@property (weak, nonatomic) UIActionSheet *editProfilePictureActionSheet;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet YOTextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *emailAddressLabel;
@property (weak, nonatomic) IBOutlet YOTextField *updatePasswordTextField;
@property (weak, nonatomic) IBOutlet YOTextField *confirmPasswordTextField;


@property (weak, nonatomic) IBOutlet YoButton *saveButton;
@property (weak, nonatomic) IBOutlet YoButton *changePasswordButton;
@property (weak, nonatomic) IBOutlet YoButton *importProfileFromFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet YoButton *updatePhoneNumberButton;

@property (strong, nonatomic) UIColor *transparentBackgroundColor;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyScrollViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyScrollViewHeightConstraint;

@property (assign, nonatomic) YoEditProfileState editingState;
@end

@interface YoEditProfileViewController (TextFieldDelegate) <UITextFieldDelegate>
@end

@interface YoEditProfileViewController (ActionSheetDelegate) <UIActionSheetDelegate>
@end

typedef NS_ENUM(NSUInteger, YoEditProfilePicOption) {
    YoEditProfilePicIndexOptionDelete,
    YoEditProfilePicIndexOptionFacebook,
    YoEditProfilePicIndexOptionTake,
    YoEditProfilePicIndexOptionImport,
};

@implementation YoEditProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self performInitialSetup];
    [self startListeners];
    [self loadPhoneVerificationHash];
}

- (void)viewDidAppear {
    if (self.isEditing &&
        ![YoUser me].fullName.length) {
        [self.firstNameTextField becomeFirstResponder];
    }
    [self.editProfileView flashScrollIndicators];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.profileImageView.layer.cornerRadius = 10.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performInitialSetup {
    self.view.backgroundColor = [UIColor clearColor];
    self.contentView.layer.cornerRadius = 10.0f;
    self.contentView.layer.masksToBounds = YES;
    
    self.titleLabel.text = NSLocalizedString(@"edit profile", nil).capitalizedString;
    
    self.contentScrollView.delegate = self;
    
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.profileImageView.layer.borderWidth = 2.0f;
    
    self.importProfileFromFacebookButton.backgroundColor = [UIColor colorWithHexString:FacebookBlue];
    self.updatePhoneNumberButton.backgroundColor = [UIColor colorWithHexString:PETER];
    self.changePasswordButton.backgroundColor = [UIColor colorWithHexString:PETER];
    self.backButton.titleLabel.textColor = [UIColor colorWithHexString:NavigationItemColor];
    
    [self.updatePhoneNumberButton setTitle:NSLocalizedString(@"update phone number", nil).capitalizedString
                                  forState:UIControlStateNormal];
    [self.changePasswordButton setTitle:NSLocalizedString(@"change password", nil).capitalizedString
                               forState:UIControlStateNormal];
    [self.importProfileFromFacebookButton setTitle:NSLocalizedString(@"Fill in with Facebook", nil)
                                          forState:UIControlStateNormal];
    [self.backButton setTitle:NSLocalizedString(@"back", nil).capitalizedString forState:UIControlStateNormal];
    
    [self configureTextFields];
    
    [self configureForUser:[YoApp currentSession].user];
    
    [self.saveButton setTitle:NSLocalizedString(@"save", nil).capitalizedString forState:UIControlStateNormal];
    self.saveButton.disableRoundedCorners = YES;
    self.saveButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
}

- (void)configureTextFields {
    self.emailAddressLabel.delegate = self;
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    self.updatePasswordTextField.delegate = self;
    self.confirmPasswordTextField.delegate = self;
    
    self.firstNameTextField.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.lastNameTextField.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.emailAddressLabel.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.updatePasswordTextField.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.confirmPasswordTextField.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    UIColor *textFieldTintColor = [UIColor whiteColor];
    self.firstNameTextField.tintColor = textFieldTintColor;
    self.lastNameTextField.tintColor = textFieldTintColor;
    self.emailAddressLabel.tintColor = textFieldTintColor;
    self.updatePasswordTextField.tintColor = textFieldTintColor;
    self.confirmPasswordTextField.tintColor = textFieldTintColor;
    
    self.emailAddressLabel.placeholder = NSLocalizedString(@"email address", nil).capitalizedString;
    self.firstNameTextField.placeholder = NSLocalizedString(@"first name", nil).capitalizedString;
    self.lastNameTextField.placeholder = NSLocalizedString(@"last name", nil).capitalizedString;
    self.updatePasswordTextField.placeholder = NSLocalizedString(@"new password", nil).capitalizedString;
    self.confirmPasswordTextField.placeholder = NSLocalizedString(@"confirm password", nil).capitalizedString;
}

- (void)configureForUser:(YoUser *)user {
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:user.photoURL
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    
    [self.profileImageView setImageWithURLRequest:imageRequest
                                 placeholderImage:[self getPlaceHolderProfileImage]
                                          success:nil
                                          failure:nil];
    
    NSString *fullNameText = user.fullName;
    if (!fullNameText.length) {
        fullNameText = NSLocalizedString(@"full name", nil).capitalizedString;
    }
    self.firstNameTextField.text = user.firstName;
    self.lastNameTextField.text = user.lastName;
    self.emailAddressLabel.text = user.email;
}

#pragma mark - Facebook

- (void)importProfileFromFacebook {
    __weak YoEditProfileViewController *weakSelf = self;
    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    [[YoApp currentSession] linkWithFacebookAccountCompletionBlock:^(BOOL success) {
        if (success) {
            [weakSelf configureForUser:[YoUser me]];
        }
        [MBProgressHUD hideHUDForView:weakSelf.contentView animated:YES];
    }];
}

- (void)pullUserProfilePictureFromFacebook {
    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
        [[YOFacebookManager sharedInstance] getFacebookProfileInfoWithCompletionBlock:^(id userInfo) {
            NS_DURING
            NSString *fbID = [userInfo valueForKey:@"id"];
            if (fbID.length) {
                NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", fbID];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:userImageURL]];
                __weak YoEditProfileViewController *vc = self;
                [self.profileImageView setImageWithURLRequest:request
                                             placeholderImage:nil
                                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                          vc.profileImageView.image = image;
                                                          [vc uploadProfilePicture:image];
                                                          [MBProgressHUD hideHUDForView:self.contentView animated:YES];
                                                      }
                                                      failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                          DDLogError(@"%@", error);
                                                          [MBProgressHUD hideHUDForView:self.contentView animated:YES];
                                                      } ];
            }
            NS_HANDLER
            [MBProgressHUD hideHUDForView:self.contentView animated:YES];
            NS_ENDHANDLER
        }];
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage]?:info[UIImagePickerControllerOriginalImage];
    image = [self processImageForUploading:image];
    __weak YoEditProfileViewController *weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [weakSelf uploadProfilePicture:image];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }];
}

#pragma mark - Internal

- (void)processRequestToSaveGeneralProfile {
    if (self.firstNameTextField.text.length && !self.lastNameTextField.text.length) {
        [self.lastNameTextField becomeFirstResponder];
    }
    else if (self.lastNameTextField.text.length && !self.firstNameTextField.text.length) {
        [self.firstNameTextField becomeFirstResponder];
    }
    else {
        [self resignAllTextFields];
        [self save];
    }
}

- (void)processRequestToSavePassword {
    if (!self.updatePasswordTextField.text.length) {
        [self.updatePasswordTextField becomeFirstResponder];
    }
    else if (!self.confirmPasswordTextField.text.length) {
        [self.confirmPasswordTextField becomeFirstResponder];
    }
    else if (![self.updatePasswordTextField.text isEqualToString:self.confirmPasswordTextField.text]) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                               desciption:NSLocalizedString(@"The two passwords do not match.", nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
    else {
        [self updateUserPassword];
    }
}

- (void)save {
    NSMutableDictionary *changedProperties = [NSMutableDictionary dictionary];
    
    if (self.emailAddressLabel.text.length > 0) {
        changedProperties[Yo_EMAIL_KEY] = self.emailAddressLabel.text;
    }
    
    BOOL isEditingName = NO;
    if (self.firstNameTextField.text.length &&
        self.lastNameTextField.text.length) {
        changedProperties[YoUserFirstNameKey] = self.firstNameTextField.text;
        changedProperties[YoUserLastNameKey] = self.lastNameTextField.text;
        isEditingName = YES;
    }
    
    if (changedProperties.count > 0) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        __weak YoEditProfileViewController *weakSelf = self;
        [[YoApp currentSession] changeUserProperties:changedProperties completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
            if (result == YoResultSuccess) {
                [[YoUser me] updateWithDictionary:responseObject[@"user"]];
                if (isEditingName) {
                    [weakSelf nameWasEdited];
                }
            }
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            [self close];
        }];
    }
    else {
        [self close];
    }
}

- (void)resignAllTextFields {
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    [self.emailAddressLabel resignFirstResponder];
}

- (void)nameWasEdited {
    
}

- (void)showChangePasswordView {
    [self.contentScrollView scrollRectToVisible:self.editPasswordView.frame animated:YES];
    [self updateBodyScrollViewConstraintsForContentView:self.editPasswordView animated:YES];
}

- (void)showEditProfileView {
    [self.contentScrollView scrollRectToVisible:self.editProfileView.frame animated:YES];
    [self updateBodyScrollViewConstraintsForContentView:self.editProfileView animated:YES];
}

- (void)updateUserPassword {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *newPassword = self.updatePasswordTextField.text;
    if (!newPassword.length) {
        return;
    }
    
    __weak YoEditProfileViewController *weakSelf = self;
    [[YoApp currentSession] changeUserProperties:@{@"password": newPassword}
                               completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
     {
         [MBProgressHUD hideHUDForView:self.view animated:YES];
         [weakSelf.updatePasswordTextField resignFirstResponder];
         [weakSelf.confirmPasswordTextField resignFirstResponder];
         if (result == YoResultSuccess) {
             weakSelf.updatePasswordTextField.text = nil;
             weakSelf.confirmPasswordTextField.text = nil;
             YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                                    desciption:NSLocalizedString(@"password changed", nil).capitalizedString];
             [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:^{
                 [weakSelf showEditProfileView];
             }]];
             [[YoAlertManager sharedInstance] showAlert:yoAlert];
         }
         else {
             YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Failed", nil)
                                                    desciption:NSLocalizedString(@"Try again later", nil)];
             [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:^{
                 [weakSelf showEditProfileView];
             }]];
             [[YoAlertManager sharedInstance] showAlert:yoAlert];
         }
     }];
}

/**
 ContentView must be subView of body scroll view.
 */
- (void)updateBodyScrollViewConstraintsForContentView:(UIView *)contentView animated:(BOOL)animated {
    [self.contentView layoutIfNeeded];
    
    [self.contentScrollView removeConstraint:self.bodyScrollViewBottomConstraint];
    NSLayoutConstraint *scrollViewBottomConstraint = [NSLayoutConstraint
                                                      constraintWithItem:contentView attribute:NSLayoutAttributeBottom
                                                      relatedBy:NSLayoutRelationEqual
                                                      toItem:self.contentScrollView attribute:NSLayoutAttributeBottom
                                                      multiplier:1.0f constant:0.0f];
    [self.contentScrollView addConstraint:scrollViewBottomConstraint];
    self.bodyScrollViewBottomConstraint = scrollViewBottomConstraint;
    
    [self.contentScrollView removeConstraint:self.bodyScrollViewHeightConstraint];
    NSLayoutConstraint *scrollViewHeightConstraint = [NSLayoutConstraint
                                                      constraintWithItem:self.contentScrollView attribute:NSLayoutAttributeHeight
                                                      relatedBy:NSLayoutRelationEqual
                                                      toItem:contentView attribute:NSLayoutAttributeHeight
                                                      multiplier:1.0f constant:0.0f];
    [self.contentScrollView addConstraint:scrollViewHeightConstraint];
    self.bodyScrollViewHeightConstraint = scrollViewHeightConstraint;
    
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^{
            [self.contentView layoutIfNeeded];
        }];
    }
    else {
        [self.contentView layoutIfNeeded];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.contentScrollView]) {
        if (scrollView.contentOffset.x == self.editPasswordView.frame.origin.x) {
            [self editPasswordViewDidAppear];
        }
        else if (scrollView.contentOffset.x == self.editProfileView.frame.origin.x) {
            [self editProfileViewDidAppear];
        }
    }
}

- (void)editPasswordViewDidAppear {
    self.editingState = YoEditProfileStatePassword;
    self.titleLabel.text = NSLocalizedString(@"password", nil).capitalizedString;
    [self.updatePasswordTextField becomeFirstResponder];
    self.backButton.hidden = NO;
    self.closeButton.hidden = YES;
}

- (void)editProfileViewDidAppear {
    self.editingState = YoEditProfileStateGeneral;
    self.titleLabel.text = NSLocalizedString(@"edit profile", nil).capitalizedString;
    self.backButton.hidden = YES;
    self.closeButton.hidden = NO;
}

#pragma mark - Edit Profile Picture

- (void)deleteProfilePicture {
    [self uploadProfilePicture:nil];
}

- (void)uploadProfilePicture:(UIImage *)profilePicture {
    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    __weak YoEditProfileViewController *weakSelf = self;
    [[YoApp currentSession] uploadUserProfilePicture:profilePicture completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
        if (result == YoResultSuccess) {
            weakSelf.profileImageView.image = [weakSelf getPlaceHolderProfileImage];
            if (profilePicture) {
                weakSelf.profileImageView.image = profilePicture;
            }
        }
        [MBProgressHUD hideAllHUDsForView:weakSelf.contentView animated:YES];
    }];
}

- (UIImage *)processImageForUploading:(UIImage *)image{
    if (image.size.width > 640.0f) {
        image = [image scaledToWidth:640.0f];
    }
    
    return image;
}

- (void)presentImagePickerController {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self presentViewController:picker animated:YES completion:nil];
    }
    else {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                               desciption:NSLocalizedString(@"No Library Found" , nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil) tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}

- (void)presentCameraController {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    BOOL cameraAccessDenied = (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted);
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
        cameraAccessDenied == NO) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self presentViewController:picker animated:YES completion:nil];
    }
    else if (cameraAccessDenied) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                               desciption:NSLocalizedString(@"Please enable camera access in the Settings app" , nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil) tapBlock:nil]];
        if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Settings", nil) tapBlock:^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }]];
        }
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
    else {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                               desciption:NSLocalizedString(@"no camera found" , nil).capitalizedString];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil) tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}

- (UIImage *)getPlaceHolderProfileImage {
    return [UIImage imageNamed:@"new_action_profileedit"];
}

#pragma mark - Gestures

- (IBAction)didTapFullNameLabelWithGesture:(UITapGestureRecognizer *)tapGR {
    [self.firstNameTextField becomeFirstResponder];
}

- (IBAction)didTapProfilePicture:(UITapGestureRecognizer *)sender {
    UIActionSheet *actionSheeet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"done", nil).capitalizedString
                                                destructiveButtonTitle:[self getTextForEditProfileOption:YoEditProfilePicIndexOptionDelete]
                                                     otherButtonTitles:[self getTextForEditProfileOption:YoEditProfilePicIndexOptionFacebook],
                                   [self getTextForEditProfileOption:YoEditProfilePicIndexOptionTake],
                                   [self getTextForEditProfileOption:YoEditProfilePicIndexOptionImport], nil];
    [actionSheeet showInView:self.view];
}

- (NSString *)getTextForEditProfileOption:(YoEditProfilePicOption)option {
    switch (option) {
        case YoEditProfilePicIndexOptionDelete:
            return NSLocalizedString(@"delete profile picture", nil).capitalizedString;
            break;
            
        case YoEditProfilePicIndexOptionFacebook:
            return NSLocalizedString(@"Import from Facebook", nil);
            break;
            
        case YoEditProfilePicIndexOptionTake:
            return NSLocalizedString(@"take photo", nil).capitalizedString;
            break;
            
        case YoEditProfilePicIndexOptionImport:
            return NSLocalizedString(@"Import from Library", nil);
            break;
            
        default:
            return nil;
            break;
    }
}

#pragma mark - IBAction

- (IBAction)didPressSave:(UIButton *)sender {
    switch (self.editingState) {
        case YoEditProfileStateGeneral:
            [self processRequestToSaveGeneralProfile];
            break;
            
        case YoEditProfileStatePassword:
            [self processRequestToSavePassword];
            break;
    }
}

- (IBAction)didPressDoneButton:(UIButton *)sender {
    [self close];
}

- (IBAction)didTapUpdatePhoneNumberButton:(YoButton *)sender {
    [self presentPhoneVerificationFlowWithCloseButton:YES];
}

- (IBAction)didPressChangePassword:(UIButton *)sender {
    [self showChangePasswordView];
}

- (IBAction)didPressImportFBProfileButton:(UIButton *)sender {
    [self importProfileFromFacebook];
}

- (IBAction)didTapBackButton:(UIButton *)sender {
    [self.updatePasswordTextField resignFirstResponder];
    [self.confirmPasswordTextField resignFirstResponder];
    [self showEditProfileView];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    UIEdgeInsets e = self.scrollView.contentInset;
    e.bottom = keyboardBounds.size.height;
    [self.scrollView setScrollIndicatorInsets:e];
    [self.scrollView setContentInset:e];
    
    CGFloat yOffSet = CGRectGetMaxY(self.contentView.frame) - CGRectGetMinY(keyboardBounds);
    yOffSet = MAX(yOffSet, 0.0f);
    CGPoint adjustedContentOffset = self.scrollView.contentOffset;
    adjustedContentOffset.y = yOffSet;
    [self.scrollView setContentOffset:adjustedContentOffset animated:YES];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    UIEdgeInsets e = self.scrollView.contentInset;
    e.bottom = 0;
    NSNumber *value = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[value doubleValue] animations:^{
        [self.scrollView setScrollIndicatorInsets:e];
        [self.scrollView setContentInset:e];
    }];
}

@end

@implementation YoEditProfileViewController (TextFieldDelegate)

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.firstNameTextField]) {
        [self.lastNameTextField becomeFirstResponder];
    }
    else if ([textField isEqual:self.updatePasswordTextField]) {
        [self.confirmPasswordTextField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    return NO;
}

@end

@implementation YoEditProfileViewController (ActionSheetDelegate)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    YoEditProfilePicOption option = buttonIndex;
    switch (option) {
        case YoEditProfilePicIndexOptionDelete:
            [self deleteProfilePicture];
            break;
            
        case YoEditProfilePicIndexOptionFacebook:
            [self pullUserProfilePictureFromFacebook];
            break;
            
        case YoEditProfilePicIndexOptionTake:
            [self presentCameraController];
            break;
            
        case YoEditProfilePicIndexOptionImport:
            [self presentImagePickerController];
            break;
            
        default:
            break;
    }
}

@end
