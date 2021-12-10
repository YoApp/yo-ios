//
//  YoSignupViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/14/15.
//
//

#import "YoSignupViewController.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "YoPhoneVerificationBySMSController.h"
#import "YoPhoneVerificationByCodeController.h"

typedef NS_ENUM(NSUInteger, YoSignupInputField) {
    YoSignupInputFieldNone,
    YoSignupInputFieldFirstName,
    YoSignupInputFieldLastName,
    YoSignupInputFieldUsername,
    YoSignupInputFieldPassword,
};

@interface YoSignupViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *popupContainerView;
@property (weak, nonatomic) IBOutlet UIButton *headerLeftButton;

@property (weak, nonatomic) IBOutlet YoButton *signupButton;

@property (weak, nonatomic) IBOutlet YOTextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet YOTextField *usernameTextField;


@property (strong, nonatomic) NSMutableArray *takenUsernames;
@property (weak, nonatomic) IBOutlet UIScrollView *popContainerScrollView;
@end

@implementation YoSignupViewController

#pragma mark Lazy Loading

- (NSMutableArray *)takenUsernames {
    if (!_takenUsernames) {
        _takenUsernames = [NSMutableArray new];
    }
    return _takenUsernames;
}

#pragma mark Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.popupContainerView.layer.masksToBounds = YES;
    self.popupContainerView.layer.cornerRadius = 10.0f;
    
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    [self setup];
    
    [self startListeners];
    
    self.navigationItem.title = NSLocalizedString(@"signup", nil).capitalizedString;
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [self.firstNameTextField addTarget:self
                                action:@selector(textFieldDidChange:)
                      forControlEvents:UIControlEventEditingChanged];
    [self.lastNameTextField addTarget:self
                               action:@selector(textFieldDidChange:)
                     forControlEvents:UIControlEventEditingChanged];
    [self.usernameTextField addTarget:self
                               action:@selector(textFieldDidChange:)
                     forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self
                               action:@selector(textFieldDidChange:)
                     forControlEvents:UIControlEventEditingChanged];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    // UI
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    // First Name
    self.firstNameTextField.placeholder = NSLocalizedString(@"first name", nil).capitalizedString;
    self.firstNameTextField.delegate = self;
    self.firstNameTextField.returnKeyType = UIReturnKeyNext;
    self.firstNameTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.firstNameTextField.tintColor = [UIColor whiteColor];
    
    // First Name
    self.lastNameTextField.placeholder = NSLocalizedString(@"last name", nil).capitalizedString;
    self.lastNameTextField.delegate = self;
    self.lastNameTextField.returnKeyType = UIReturnKeyNext;
    self.lastNameTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.lastNameTextField.tintColor = [UIColor whiteColor];
    
    // Username
    self.usernameTextField.placeholder = NSLocalizedString(@"CHOOSE USERNAME", nil).lowercaseString.capitalizedString;
    self.usernameTextField.delegate = self;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.usernameTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.usernameTextField.tintColor = [UIColor whiteColor];
    
    // Password
    self.passwordTextField.placeholder = NSLocalizedString(@"choose password", nil).capitalizedString;
    self.passwordTextField.delegate = self;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.passwordTextField.tintColor = [UIColor whiteColor];
    
    // back button
    [self.headerLeftButton setTitle:NSLocalizedString(@"back", nil).capitalizedString
                           forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UITextField *firstRespondingTextField = [self getFirstEmptyTextField];
    [firstRespondingTextField becomeFirstResponder];
}

- (UITextField *)getFirstEmptyTextField {
    NSArray *textFields = @[self.firstNameTextField,
                            self.lastNameTextField,
                            self.usernameTextField,
                            self.passwordTextField];
    for (UITextField *textField in textFields) {
        if (textField.text.length == 0) {
            return textField;
        }
    }
    return self.passwordTextField;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    if (self.signupButton) {
        [UIView animateWithDuration:0.2 animations:^{
            self.signupButton.bottom = CGRectGetMinY(keyboardBounds);
        }];
    }
    else {
        YoButton *signupButton = [YoButton new];
        signupButton.disableRoundedCorners = YES;
        signupButton.frame = CGRectMake(0.0f,
                                        0.0f,
                                        CGRectGetWidth([[UIScreen mainScreen] bounds]),
                                        50.0f);
        signupButton.bottom = CGRectGetMinY(keyboardBounds);
        signupButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
        [signupButton setTitle:NSLocalizedString(@"next", nil).capitalizedString
                      forState:UIControlStateNormal];
        [signupButton addTarget:self action:@selector(didPressSignupButton:)
               forControlEvents:UIControlEventTouchUpInside];
        signupButton.titleLabel.textColor = [UIColor whiteColor];
        signupButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
        signupButton.titleLabel.minimumScaleFactor = 0.1;
        signupButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:signupButton];
        self.signupButton = signupButton;
        [self toogleCallToActionState];
    }
    
    UIEdgeInsets e = self.popContainerScrollView.contentInset;
    e.bottom = keyboardBounds.size.height + self.signupButton.height;
    [self.popContainerScrollView setScrollIndicatorInsets:e];
    [self.popContainerScrollView setContentInset:e];
}

#pragma mark Internal

- (void)toogleCallToActionState {
    if (self.usernameTextField.text.length &&
        self.passwordTextField.text.length &&
        self.firstNameTextField.text.length &&
        self.lastNameTextField.text.length) {
        self.signupButton.enabled = YES;
    }
    else {
        self.signupButton.enabled = NO;
    }
}

- (void)cleanup {
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

- (void)displayErrorWithInputField:(YoSignupInputField)field
                           message:(NSString *)message
                       description:(NSString *)description
                       dismissText:(NSString *)dismissText {
    
    switch (field) {
        case YoSignupInputFieldFirstName:
            [self.firstNameTextField becomeFirstResponder];
            break;
            
        case YoSignupInputFieldLastName:
            [self.lastNameTextField becomeFirstResponder];
            break;
            
        case YoSignupInputFieldPassword:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case YoSignupInputFieldUsername:
            [self.usernameTextField becomeFirstResponder];
            break;
            
        default:
            break;
    }
    
    YoAlert *alert = [[YoAlert alloc] initWithTitle:message
                                         desciption:description];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:dismissText tapBlock:nil]];
    [[YoAlertManager sharedInstance] showAlert:alert];
}

- (void)signup {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *wantedUsernamed = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    NSString *firstName = self.firstNameTextField.text;
    firstName = [firstName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *lastName = self.lastNameTextField.text;
    lastName = [lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (firstName.length < 1) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldFirstName
                                 message:@"Yo"
                             description:NSLocalizedString(@"missing first name", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    if (lastName.length < 1) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldLastName
                                 message:@"Yo"
                             description:NSLocalizedString(@"missing last name", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    if ([self.takenUsernames containsObject:wantedUsernamed]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldUsername
                                 message:NSLocalizedString(@"USERNAME TAKEN", nil).lowercaseString.capitalizedString
                             description:NSLocalizedString(@"CHOOSE ANOTHER", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    if (wantedUsernamed.length == 0) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldUsername
                                 message:@"Yo"
                             description:NSLocalizedString(@"SELECT A USERNAME", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    if (password.length < 1) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldPassword
                                 message:@"Yo"
                             description:NSLocalizedString(@"select longer password", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    
    if (![APPDELEGATE hasInternet]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoSignupInputFieldNone
                                 message:@"Yo"
                             description:NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"dismiss", nil).capitalizedString];
        return;
    }
    
    NSDictionary *profile = @{YoUserFirstNameKey:firstName,
                              YoUserLastNameKey:lastName};
    
    __weak YoSignupViewController *weakSelf = self;
    [[YoApp currentSession] signupWithUsername:wantedUsernamed
                                      passcode:password
                                   profileInfo:profile
                             completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
     {
         NS_DURING
         [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
         if (result == YoResultSuccess) {
             
             CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
             NSString *countryCode = [[[networkInfo subscriberCellularProvider] isoCountryCode] uppercaseString];
             
             if (!countryCode || [countryCode isEqualToString:@"ZZ"]) {
                 NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
                 countryCode = [[currentLocale objectForKey:NSLocaleCountryCode] uppercaseString];
             }
             
             UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
             if ([countryCode isEqualToString:@"US"]) {
                 YoPhoneVerificationBySMSController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoPhoneVerificationBySMSControllerID"];
                 vc.closeButtonText = NSLocalizedString(@"Skip", nil);
                 vc.navigationItem.hidesBackButton = YES;
                 [self.navigationController pushViewController:vc animated:YES];
             }
             else {
                 YoPhoneVerificationByCodeController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoPhoneVerificationByCodeControllerID"];
                 vc.showsCloseButton = NO;
                 vc.callToActionBottom = self.signupButton.bottom;
                 vc.textForLabel = @"Just enter your phone number to verify your account and you're in!";
                 vc.navigationItem.hidesBackButton = YES;
                 [self.navigationController pushViewController:vc animated:YES];
             }
         }
         else {
             BOOL usernameTaken = (statusCode == 422);
             if (usernameTaken) {
                 [weakSelf.takenUsernames addObject:wantedUsernamed];
                 
                 [weakSelf displayErrorWithInputField:YoSignupInputFieldUsername
                                              message:NSLocalizedString(@"USERNAME TAKEN", nil).lowercaseString.capitalizedString
                                          description:NSLocalizedString(@"CHOOSE ANOTHER", nil).lowercaseString.capitalizedString
                                          dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
             }
             else {
                 [weakSelf displayErrorWithInputField:YoSignupInputFieldNone
                                              message:@"Yo"
                                          description:NSLocalizedString(@"FAILED", nil).lowercaseString.capitalizedString
                                          dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
             }
         }
         NS_HANDLER
         NS_ENDHANDLER
     }];
}

#pragma mark Actions

- (IBAction)didPressBackButton:(UIButton *)sender {
    [self cleanup];
    [self dismissWithCompletionBlock:nil];
}

- (IBAction)didPressSignupButton:(UIButton *)sender {
    [self signup];
    [YoAnalytics logEvent:YoEventTappedSignUp withParameters:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    BOOL textFieldShouldReturn = YES;
    
    if ([textField isEqual:self.usernameTextField]) {
        textFieldShouldReturn = NO;
        
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                    withString:string.uppercaseString];
        NSRange rangeOfNewLine = [newText rangeOfString:@"\n"];
        if (rangeOfNewLine.location != NSNotFound) {
            //[textField resignFirstResponder];
            [self performSelector:@selector(textFieldShouldReturn:) withObject:textField afterDelay:0.0];
            return NO;
        }
        
        if (newText.length == 1) {
            NSCharacterSet *alphaSet = [NSCharacterSet characterSetWithCharactersInString:@"#ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"];
            BOOL isValidText = [[newText stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
            if (!isValidText) {
                return NO;
            }
        }
        
        newText = [newText stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSCharacterSet *alphaNumericSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"];
        
        BOOL isValidText = [[newText stringByTrimmingCharactersInSet:alphaNumericSet] isEqualToString:@""];
        if (!isValidText) {
            return NO;
        }
        else {
            textField.text = newText;
            [self textFieldDidChange:textField];
        }
    }
    
    return textFieldShouldReturn;
}

- (BOOL)textFieldShouldReturn:(YOTextField *)textField {
    if (textField.text.length < 1) {
        return NO;
    }
    
    if ([textField isEqual:self.firstNameTextField]) {
        [self.lastNameTextField becomeFirstResponder];
    }
    else if ([textField isEqual:self.lastNameTextField]) {
        [self.usernameTextField becomeFirstResponder];
    }
    else if ([textField isEqual:self.usernameTextField]) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [self signup];
    }
    
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self toogleCallToActionState];
}

@end
