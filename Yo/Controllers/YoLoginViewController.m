//
//  YoLoginViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/15/15.
//
//

#import "YoLoginViewController.h"
#import "YoLoginStoryboardIdentifiers.h"
#import "YoRecoverAccountViewController.h"

typedef NS_ENUM(NSUInteger, YoLoginInputField) {
    YoLoginInputFieldNone,
    YoLoginInputFieldUsername,
    YoLoginInputFieldPassword,
};

@interface YoLoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) UIButton *headerLeftButton;

@property (weak, nonatomic) YoButton *loginButton;
@property (weak, nonatomic) UIButton *recoverAccountButton;

@property (weak, nonatomic) IBOutlet YOTextField *usernameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *popContainerScrollView;
@end

@implementation YoLoginViewController

#pragma mark Life

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self createCells];
    [self setup];
    
    self.usernameTextField.text = [[YoApp currentSession] lastKnownValidUsername];
        
    [self startListeners];
    
    self.navigationItem.title = NSLocalizedString(@"login", nil).capitalizedString;
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
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
    
    // Username Cell
    self.usernameTextField.placeholder = NSLocalizedString(@"ENTER USERNAME", nil).lowercaseString.capitalizedString;
    self.usernameTextField.delegate = self;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.usernameTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.usernameTextField.tintColor = [UIColor whiteColor];
    
    // Password cell
    self.passwordTextField.placeholder = NSLocalizedString(@"enter password", nil).lowercaseString.capitalizedString;
    self.passwordTextField.delegate = self;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.passwordTextField.tintColor = [UIColor whiteColor];
    
    // recover button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"Forgot", nil).capitalizedString
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor]
                 forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(didPressRecoverAccountButton:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.recoverAccountButton = button;
    
    // back button
    [self.headerLeftButton setTitle:NSLocalizedString(@"back", nil).capitalizedString
                           forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if ([self.usernameTextField.text length] < 1) {
        [self.usernameTextField becomeFirstResponder];
    }
    else {
        [self.passwordTextField becomeFirstResponder];
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    if (self.loginButton) {
        [UIView animateWithDuration:0.2 animations:^{
            self.loginButton.bottom = CGRectGetMinY(keyboardBounds);
        }];
    }
    else {
        YoButton *loginButton = [YoButton new];
        loginButton.disableRoundedCorners = YES;
        loginButton.frame = CGRectMake(0.0f,
                                        0.0f,
                                        CGRectGetWidth([[UIScreen mainScreen] bounds]),
                                        50.0f);
        loginButton.bottom = CGRectGetMinY(keyboardBounds);
        loginButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
        [loginButton setTitle:NSLocalizedString(@"login", nil).capitalizedString
                      forState:UIControlStateNormal];
        [loginButton addTarget:self action:@selector(didPressLoginButton:)
               forControlEvents:UIControlEventTouchUpInside];
        loginButton.titleLabel.textColor = [UIColor whiteColor];
        loginButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
        loginButton.titleLabel.minimumScaleFactor = 0.1;
        loginButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:loginButton];
        self.loginButton = loginButton;
        [self toogleCallToActionState];
    }
    
    UIEdgeInsets e = self.popContainerScrollView.contentInset;
    e.bottom = keyboardBounds.size.height + self.loginButton.height;
    [self.popContainerScrollView setScrollIndicatorInsets:e];
    [self.popContainerScrollView setContentInset:e];
}

#pragma mark Internal

- (void)toogleCallToActionState {
    if (self.usernameTextField.text.length &&
        self.passwordTextField.text.length) {
        self.loginButton.enabled = YES;
    }
    else {
        self.loginButton.enabled = NO;
    }
}

- (void)cleanup {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

- (void)displayErrorWithInputField:(YoLoginInputField)field
                           message:(NSString *)message
                       description:(NSString *)description
                       dismissText:(NSString *)dismissText {
    
    switch (field) {
        case YoLoginInputFieldNone:
            // nop
            break;
            
        case YoLoginInputFieldPassword:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case YoLoginInputFieldUsername:
            [self.usernameTextField becomeFirstResponder];
            break;
    }
    
    
    YoAlert *alert = [[YoAlert alloc] initWithTitle:message
                                         desciption:description];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:dismissText tapBlock:nil]];
    [[YoAlertManager sharedInstance] showAlert:alert];
}

- (void)login {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    if (username.length < 1) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoLoginInputFieldUsername
                                 message:@"Yo"
                             description:NSLocalizedString(@"ENTER USERNAME", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    NSLocalizedString(@"maybe its only numbers?", nil).capitalizedString;
    if (password.length < 1) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoLoginInputFieldPassword
                                 message:@"Yo"
                             description:NSLocalizedString(@"enter password", nil).capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    
    if (![APPDELEGATE hasInternet]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoLoginInputFieldNone
                                 message:@"Yo"
                             description:NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"dismiss", nil).capitalizedString];
    }
    else {
        __weak YoLoginViewController *weakSelf = self;
        [[YoApp currentSession] loginWithUsername:username passcode:password completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
            NS_DURING
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            if (result != YoResultSuccess) {
                BOOL wrongCredentials = (statusCode == 401);
                BOOL usernameNotFound = (statusCode == 404);
                
                NSString *alertTitle = NSLocalizedString(@"failed to login", nil).capitalizedString;
                
                NSString *descriptionText = nil;
                if (wrongCredentials) {
                    descriptionText = NSLocalizedString(@"incorrect password", nil).capitalizedString;
                    descriptionText = MakeString(@"%@. %@", descriptionText, NSLocalizedString(@"maybe it only contains numbers?", nil).capitalizedString);
                }
                else if (usernameNotFound) {
                    descriptionText = NSLocalizedString(@"no such user", nil).capitalizedString;
                }
                
                YoAlert *alert = [[YoAlert alloc] initWithTitle:alertTitle
                                                     desciption:descriptionText];
                [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"ok", nil).uppercaseString tapBlock:nil]];
                [[YoAlertManager sharedInstance] showAlert:alert];
            }
            NS_HANDLER
            NS_ENDHANDLER
        }];
    }

    
}

- (void)transitionToRecoverAccount {
    YoRecoverAccountViewController *recoverAcctVC = [self.storyboard instantiateViewControllerWithIdentifier:RecoverAccountViewControllerID];
    recoverAcctVC.keyboardTop = self.loginButton.bottom;
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:recoverAcctVC animated:YES];
    }
    else {
        recoverAcctVC.modalPresentationStyle = UIModalPresentationCustom;
        recoverAcctVC.transitioningDelegate = self.transitioningDelegate;
        [self showBlurredBackgroundWithViewController:recoverAcctVC];
    }
}

#pragma mark Actions

- (IBAction)didPressRecoverAccountButton:(UIButton *)sender {
    [self transitionToRecoverAccount];
}

- (IBAction)didPressBackButton:(UIButton *)sender {
    [self cleanup];
    [self dismissWithCompletionBlock:nil];
}

- (IBAction)didPressLoginButton:(UIButton *)sender {
    [self login];
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
    
    if ([textField isEqual:self.usernameTextField]) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [self login];
    }
    
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self toogleCallToActionState];
}

@end
