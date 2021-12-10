//
//  YoRecoverAccountViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/15/15.
//
//

#import "YoRecoverAccountViewController.h"

typedef NS_ENUM(NSUInteger, YoRecoverAcctInputField) {
    YoRecoverAcctInputFieldNone,
    YoRecoverAcctInputFieldUsername,
};

@interface YoRecoverAccountViewController () <UITextFieldDelegate>
@property (weak, nonatomic) UIButton *headerLeftButton;

@property (weak, nonatomic) IBOutlet YOTextField *usernameTextField;
@property (weak, nonatomic) IBOutlet YOTextField *emailTextField;
@property (weak, nonatomic) IBOutlet YOTextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *popContainerScrollView;
@property (strong, nonatomic) IBOutlet YoButton *recoverButton;
@end

@implementation YoRecoverAccountViewController

#pragma mark Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self createCells];
    [self setup];
    
    self.usernameTextField.text = [[YoApp currentSession] lastKnownValidUsername];
    
    self.recoverButton = [YoButton new];
    self.recoverButton.disableRoundedCorners = YES;
    self.recoverButton.frame = CGRectMake(0.0f,
                                          0.0f,
                                          self.view.width,
                                          50.0f);
    self.recoverButton.bottom = self.keyboardTop;
    self.recoverButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
    [self.recoverButton setTitle:NSLocalizedString(@"recover password", nil).capitalizedString
                        forState:UIControlStateNormal];
    [self.recoverButton addTarget:self action:@selector(didPressRecoverButton:) forControlEvents:UIControlEventTouchUpInside];
    self.recoverButton.titleLabel.textColor = [UIColor whiteColor];
    self.recoverButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
    self.recoverButton.titleLabel.minimumScaleFactor = 0.1;
    self.recoverButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:self.recoverButton];
    [self toogleCallToActionState];
    
    
    [self startListeners];
    
    self.navigationItem.title = NSLocalizedString(@"recover", nil).capitalizedString;
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [self.usernameTextField addTarget:self
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
    self.usernameTextField.returnKeyType = UIReturnKeyGo;
    //    self.usernameTextField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.usernameTextField.tintColor = [UIColor whiteColor];
    
    // signup button
    [self.recoverButton setTitle:NSLocalizedString(@"recover account", nil).capitalizedString
                        forState:UIControlStateApplication];
    
    // back button
    [self.headerLeftButton setTitle:NSLocalizedString(@"back", nil).capitalizedString
                           forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.emailTextField becomeFirstResponder];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.recoverButton.bottom = CGRectGetMinY(keyboardBounds);
    }];
    
    UIEdgeInsets e = self.popContainerScrollView.contentInset;
    e.bottom = keyboardBounds.size.height + self.recoverButton.height;
    [self.popContainerScrollView setScrollIndicatorInsets:e];
    [self.popContainerScrollView setContentInset:e];
}

#pragma mark Internal

- (void)toogleCallToActionState {
    if (self.usernameTextField.text.length ||
        self.emailTextField.text.length ||
        self.phoneTextField.text.length) {
        
        self.recoverButton.enabled = YES;
    }
    else {
        self.recoverButton.enabled = NO;
    }
}

- (void)cleanup {
    [self.usernameTextField resignFirstResponder];
}

- (void)displayErrorWithInputField:(YoRecoverAcctInputField)field
                           message:(NSString *)message
                       description:(NSString *)description
                       dismissText:(NSString *)dismissText {
    
    switch (field) {
        case YoRecoverAcctInputFieldNone:
            // nop
            break;
            
        case YoRecoverAcctInputFieldUsername:
            [self.usernameTextField becomeFirstResponder];
            break;
    }
    
    
    YoAlert *alert = [[YoAlert alloc] initWithTitle:message
                                         desciption:description];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:dismissText tapBlock:nil]];
    [[YoAlertManager sharedInstance] showAlert:alert];
}

- (void)recoverAccount {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *username = self.usernameTextField.text;
    NSString *email = self.emailTextField.text;
    NSString *phone = self.phoneTextField.text;
    
    if (username.length == 0 && email.length == 0 && phone.length == 0) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoRecoverAcctInputFieldUsername
                                 message:@"Yo"
                             description:NSLocalizedString(@"Enter one of the fields", nil).capitalizedString
                             dismissText:NSLocalizedString(@"ok", nil).uppercaseString];
        return;
    }
    
    if (![APPDELEGATE hasInternet]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self displayErrorWithInputField:YoRecoverAcctInputFieldUsername
                                 message:@"Yo"
                             description:NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", nil).lowercaseString.capitalizedString
                             dismissText:NSLocalizedString(@"dismiss", nil).capitalizedString];
    }
    else {
        
        NSMutableDictionary *userDetails = [NSMutableDictionary dictionary];
        if (username.length) {
            userDetails[@"username"] = username;
        }
        if (email.length) {
            userDetails[@"email"] = email;
        }
        if (phone.length) {
            userDetails[@"phone"] = phone;
        }
        
        __weak YoRecoverAccountViewController *weakSelf = self;
        [[YoApp currentSession] recoverPasscodeWithUserDetails:userDetails
                                             completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                                
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            if (result == YoResultSuccess) {
                [weakSelf cleanup];
            }
                                                 
        }];
    }
}

#pragma mark Actions

- (IBAction)didPressBackButton:(UIButton *)sender {
    [self cleanup];
    [self dismissWithCompletionBlock:nil];
}

- (IBAction)didPressRecoverButton:(UIButton *)sender {
    [self recoverAccount];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range
                                                                withString:string.uppercaseString];
    
    if (textField == self.usernameTextField) {
        
        BOOL textFieldShouldReturn = NO;
        
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
        
        return textFieldShouldReturn;
        
    }
    else {
        textField.text = newText;
        [self textFieldDidChange:textField];
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(YOTextField *)textField {
    if (textField.text.length < 1) {
        return NO;
    }
    
    if ([textField isEqual:self.usernameTextField] ||
        [textField isEqual:self.emailTextField] ||
        [textField isEqual:self.phoneTextField]
        ) {
        [self recoverAccount];
    }
    
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self toogleCallToActionState];
}

@end
