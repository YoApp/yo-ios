//
//  YoPhoneVerificationByCodeController.m
//  Yo
//
//  Created by Peter Reveles on 6/6/15.
//
//

#import "YoPhoneVerificationByCodeController.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "YoPhoneVerificationEnterCodeController.h"

@interface YoPhoneVerificationByCodeController () <UIScrollViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *countryPicker;

@end

@implementation YoPhoneVerificationByCodeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.showsCloseButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:NSLocalizedString(@"Close", nil).capitalizedString
                forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:NavigationItemColor]
                     forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    self.view.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    
    self.textFieldContainerView.layer.cornerRadius = 5.0;
    self.textFieldContainerView.layer.masksToBounds = YES;
    
    self.callToActionButton = [YoButton new];
    self.callToActionButton.disableRoundedCorners = YES;
    self.callToActionButton.frame = CGRectMake(0.0f,
                                               0.0f,
                                               self.view.width,
                                               50.0f);
    self.callToActionButton.bottom = self.callToActionBottom;
    self.callToActionButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
    [self.callToActionButton setTitle:NSLocalizedString(@"", nil).capitalizedString
                             forState:UIControlStateNormal];
    [self.callToActionButton addTarget:self action:@selector(didTapCallToActionButton:)
                      forControlEvents:UIControlEventTouchUpInside];
    self.callToActionButton.titleLabel.textColor = [UIColor whiteColor];
    self.callToActionButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
    self.callToActionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.callToActionButton setTitle:@"Verify" forState:UIControlStateNormal];
    [self.view addSubview:self.callToActionButton];
    self.self.callToActionButton = self.callToActionButton;
    self.self.callToActionButton.enabled = NO;
    
    [self startListeners];
    [self setupViews];
    [self setupCountryCodePicker];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews {
    
    self.countryCodeButton.disableRoundedCorners = YES;
    self.textField.tintColor = [UIColor whiteColor];
    self.instructionsLabel.text = self.textForLabel ? self.textForLabel : @"Just enter your phone number instead to verify your account.";
    
    [self.textField addTarget:self
                       action:@selector(textFieldTextDidChange)
             forControlEvents:UIControlEventEditingChanged];
    
}

#pragma mark - Internal

- (void)close {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Verification

- (void)requestVerificationCode {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *countryCode = self.countryCodeButton.titleLabel.text;
    [[YoApp currentSession] setPossible_country_code:countryCode];
    
    NSString *number = [[self.textField.text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"*#,;"]]
                        componentsJoinedByString:@""];
    
    NSString *numberWithCountryCode = MakeString(@"%@%@", countryCode, number);
    
    [[YoApp currentSession] requestVerificationCodeForNumber:numberWithCountryCode
                                         withCompletionBlock:^(BOOL didSend)
     {
         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
         if (didSend) {
             [self showEnterVerificationCode];
         }
         else {
             YoAlert *alert = [[YoAlert alloc] initWithTitle:nil
                                                  desciption:NSLocalizedString(@"An error occured in verifying your phone number.", nil)];
             [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:nil]];
             [[YoAlertManager sharedInstance] showAlert:alert];
         }
     }];
}


#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.self.callToActionButton.bottom = CGRectGetMinY(keyboardBounds);
    }];
    
}

- (void)showEnterVerificationCode {
    [self performSegueWithIdentifier:@"YoSegueEnterVerificationCode" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"YoSegueEnterVerificationCode"]) {
        YoPhoneVerificationByCodeController *destViewController = segue.destinationViewController;
        destViewController.callToActionBottom = self.callToActionButton.bottom;
    }
}

#pragma mark - Actions

- (IBAction)didTapCallToActionButton:(YoButton *)sender {
    [self requestVerificationCode];
}

- (IBAction)textFieldTextDidChange {
    self.self.callToActionButton.enabled = self.textField.text.length?YES:NO;
}

#pragma mark - Country Code Support

- (void)setupCountryCodePicker {
    
    self.countryPicker.delegate = self;
    self.countryPicker.dataSource = self;
    
    self.countries = [NSMutableArray array];
    self.countryCodeArray = [NSMutableArray new];
    self.countryNameArray = [NSMutableArray new];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"countries"
                                                     ofType:@"csv"];
    NSString *fileDataString = [NSString stringWithContentsOfFile:path
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
    NSArray *rawCountries = [fileDataString componentsSeparatedByString:@"\n"];
    int i = 0;
    for (NSString *c in rawCountries) {
        if (i == 0) {
            i++;
            continue;
        }
        i++;
        NSArray *rawCountry = [c componentsSeparatedByString:@","];
        NSString *phoneCode = rawCountry[1];
        NSString *name = rawCountry[2];
        
        NSDictionary *dict = @{@"code": phoneCode,
                               @"name": name};
        [self.countries addObject:dict];
        [self.countryCodeArray addObject:phoneCode];
        [self.countryNameArray addObject:name];
    }
    
    NSString *countryCode = @"US";
    NSString *countryNumber = @"+1";
    NS_DURING
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    countryCode = [[[networkInfo subscriberCellularProvider] isoCountryCode] uppercaseString];
    
    if (!countryCode || [countryCode isEqualToString:@"ZZ"]) {
        NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
        countryCode = [[currentLocale objectForKey:NSLocaleCountryCode] uppercaseString];
    }
    if (!countryCode || [countryCode isEqualToString:@"ZZ"]) {
        countryCode = @"US";
    }
    
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"phone" ofType:@"json"]];
    NSDictionary *countryCodeToPhoneCode = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    countryNumber = [countryCodeToPhoneCode objectForKey:countryCode];
    if ( ! countryNumber || [countryNumber isEqualToString:@"+0"]) {
        countryNumber = @"+1";
    }
    
    if ( ! [countryNumber hasPrefix:@"+"]) {
        countryNumber = [NSString stringWithFormat:@"+%@", countryNumber];
    }
    
    [[YoApp currentSession] setPossible_country_code:countryNumber];
    NS_HANDLER
    countryNumber = @"+1";
    NS_ENDHANDLER
    
    //self.pickerView.bottom = self.view.bottom;
    self.countryPicker.delegate = self;
    [self.countryPicker reloadAllComponents];
    
    NSInteger positionOfDefaultedCountry = [self.countryCodeArray indexOfObject:[countryNumber stringByReplacingOccurrencesOfString:@"+" withString:@""]];
    if (positionOfDefaultedCountry != NSNotFound) {
        NSInteger finalIndex = positionOfDefaultedCountry;
        [self.countryCodeButton setTitle:countryNumber
                                forState:UIControlStateNormal];
        NSString *countryName = [self.countryNameArray objectAtIndex:positionOfDefaultedCountry];
        if ([countryNumber isEqualToString:@"+1"]) {
            countryName = @"United States";
        }
        else if ([countryNumber isEqualToString:@"+44"]) {
            countryName = @"United Kingdom";
        }
        finalIndex = [self.countryNameArray indexOfObject:countryName];
        [self.countryPicker selectRow:finalIndex inComponent:0 animated:NO];
    }
    else {
        [self.countryPicker selectRow:196 inComponent:0 animated:NO]; // @or: US
        [self.countryCodeButton setTitle:countryNumber
                                forState:UIControlStateNormal];
    }
}

- (IBAction)didTapCountryCodeButton:(UIButton *)sender {
    NSString *countryName = self.countryCodeButton.titleLabel.text;
    NSInteger positionOfChosenCounty = [self.countryNameArray indexOfObject:countryName];
    if (positionOfChosenCounty == NSNotFound) {
        NSInteger row = [self.countryPicker selectedRowInComponent:0];
        [self.countryCodeButton setTitle:MakeString(@"+%@", [self.countries[row] objectForKey:@"code"])
                                forState:UIControlStateNormal];
    }
    
    [self.textField resignFirstResponder];
}

#pragma mark UIPickerDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.countries.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view

{
    UILabel* tView = (UILabel *)view;
    if (!tView) {
        tView = [[UILabel alloc] init];
        tView.font = [UIFont fontWithName:@"Montserrat-Bold" size:32];
        tView.textColor = [UIColor whiteColor];
        tView.textAlignment = NSTextAlignmentCenter;
        tView.backgroundColor = [UIColor clearColor];
    }
    
    NSString *countryName = [self.countries[row] objectForKey:@"name"];
    tView.text = countryName;
    
    return tView;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [self.countries[row] objectForKey:@"name"];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    [self.countryCodeButton setTitle:MakeString(@"+%@", [self.countries[row] objectForKey:@"code"])
                            forState:UIControlStateNormal];
}

@end
