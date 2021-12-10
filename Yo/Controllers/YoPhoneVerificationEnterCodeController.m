//
//  YoPhoneVerificationEnterCodeController.m
//  Yo
//
//  Created by Or Arbel on 6/7/15.
//
//

#import "YoPhoneVerificationEnterCodeController.h"

@interface YoPhoneVerificationEnterCodeController ()

@end

@implementation YoPhoneVerificationEnterCodeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.callToActionButton.enabled = (self.textField.text.length<4)?NO:YES;
    [self.callToActionButton setTitle:NSLocalizedString(@"Submit", nil)
                             forState:UIControlStateNormal];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"Didn't get code", nil).capitalizedString
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor]
                 forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(didntGetCodeTapped) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)didntGetCodeTapped {
    YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Yo", nil)
                                         desciption:NSLocalizedString(@"No worries, verify later 😜", nil)];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:^{
        [self close];
    }]];
    [[YoAlertManager sharedInstance] showAlert:alert];
}

- (void)setupViews {
    [super setupViews];
    self.callToActionButton.bottom = self.callToActionBottom;
    self.instructionsLabel.text = @"Enter the code you've received in the SMS.";
}

- (void)submitVerificationCode {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *code = self.textField.text;
    [[YoApp currentSession] submitCode:code
                   withCompletionBlock:^(BOOL didVerify) {
                       [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                       if (didVerify) {
                           YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Thank You", nil)
                                                                desciption:NSLocalizedString(@"For verifying your account!", nil)];
                           alert.userActionRequired = YES;
                           [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Awesome", nil) tapBlock:^{
                               [self close];
                           }]];
                           [[YoAlertManager sharedInstance] showAlert:alert];
                           [self close];
                       }
                       else {
                           // handle case where code is wrong
                           YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Hello", nil)
                                                                desciption:NSLocalizedString(@"I couldn't verify the code. Maybe check it again?", nil)];
                           [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:nil]];
                           [[YoAlertManager sharedInstance] showAlert:alert];
                       }
                   }];
}

- (IBAction)textFieldTextDidChange {
    self.callToActionButton.enabled = (self.textField.text.length >= 4);
}

- (IBAction)didTapCallToActionButton:(YoButton *)sender {
    [self submitVerificationCode];
}

@end
