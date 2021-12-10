//
//  YoPhoneVerificationBySMSController.m
//  Yo
//
//  Created by Peter Reveles on 6/6/15.
//
//

#import "YoPhoneVerificationBySMSController.h"

@interface YoPhoneVerificationBySMSController ()
@property (weak, nonatomic) IBOutlet YoLabel *titleLabel;
@property (weak, nonatomic) IBOutlet YoLabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet YoButton *sendSMSButton;

@property (assign, nonatomic) YoLoadingStatus hashLoadingStatus;
@property (strong, nonatomic) NSString *phoneVerificationHash;
@property (assign, nonatomic) BOOL shouldPresentPhoneVerificationFlowOnHashLoad;
@end

@implementation YoPhoneVerificationBySMSController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.closeButtonText != nil) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:self.closeButtonText
                forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor]
                     forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    ((YoNavigationController *)self.navigationController).allowCustomBarColor = YES;
    ((YoNavigationController *)self.navigationController).navigationBar.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    self.view.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.view.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    
    self.navigationItem.title = @"Text Us";
    self.navigationItem.hidesBackButton = YES;
    
    self.titleLabel.text = NSLocalizedString(@"☎️", nil);
    self.descriptionLabel.text = NSLocalizedString(@"Just send a simple SMS to verify your account and you’re in!", nil);
    
    [self loadPhoneVerificationHash];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.timesViewed++;
    if (self.timesViewed >= 3) {
        YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Yo", nil)
                                             desciption:NSLocalizedString(@"No worries, verify later 😜", nil)];
        [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }]];
        [[YoAlertManager sharedInstance] showAlert:alert];
    }
}

- (void)close {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)didTapSendSMSButton:(YoButton *)sender {
    [self presentSMSPhoneVerification];
}

#pragma mark - Verification

- (void)loadPhoneVerificationHash {
    self.hashLoadingStatus = YoLoadingStatusInProgress;
    [[YoApp currentSession] getPhoneVerificationHashWithCompletionBlock:^(NSString *hash) {
        if (hash) {
            self.phoneVerificationHash = hash;
            self.hashLoadingStatus = YoLoadingStatusComplete;
        }
        else {
            self.hashLoadingStatus = YoLoadingStatusFailed;
        }
        
        if (self.shouldPresentPhoneVerificationFlowOnHashLoad) {
            self.shouldPresentPhoneVerificationFlowOnHashLoad = NO;
            [self presentSMSPhoneVerification];
        }
    }];
}

- (void)showEnterPhoneNumber {
    [self performSegueWithIdentifier:YoSegueToPhoneVerificationByCodeControllerID sender:self];
}

- (void)presentSMSPhoneVerification {
    if (self.hashLoadingStatus == YoLoadingStatusComplete &&
        self.phoneVerificationHash.length) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[YoApp currentSession] verifyUserPhoneNumberWithHash:self.phoneVerificationHash
                                              completionBlock:^(MessageComposeResult result)
         {
             [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
             if (result == MessageComposeResultSent) {
                 YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Thank You", nil)
                                                      desciption:NSLocalizedString(@"For verifying your account!", nil)];
                 alert.userActionRequired = YES;
                 [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Awesome", nil) tapBlock:^{
                     [self close];
                 }]];
                 [[YoAlertManager sharedInstance] showAlert:alert];
             }
             else if (result == MessageComposeResultCancelled) {
                 [self showEnterPhoneNumber];
             }
             else if (result == MessageComposeResultFailed) {
                 [self showEnterPhoneNumber];
             }
         }];
    }
    else if (self.hashLoadingStatus == YoLoadingStatusFailed) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Yo"
                                             desciption:NSLocalizedString(@"an error occured.", nil).capitalizedString];
        alert.userActionRequired = YES;
        [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil)
                                                     tapBlock:^
                          {
                              [self performSegueWithIdentifier:YoSegueToPhoneVerificationByCodeControllerID sender:self];
                          }]];
        [[YoAlertManager sharedInstance] showAlert:alert];
    }
    else if (self.hashLoadingStatus == YoLoadingStatusInProgress) {
        self.shouldPresentPhoneVerificationFlowOnHashLoad = YES;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    else {
        self.shouldPresentPhoneVerificationFlowOnHashLoad = YES;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self loadPhoneVerificationHash];
    }
}

@end
