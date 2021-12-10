//
//  YOEnablePushController.m
//  Yo
//
//  Created by Or Arbel on 3/4/14.
//
//

#import "YOEnablePushController.h"

@interface YOEnablePushController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *ios8View;
@property (weak, nonatomic) IBOutlet UIScrollView *instructionsScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *instructionOneImageView;
@property (weak, nonatomic) IBOutlet UIButton *openSettingsButton;
@property (weak, nonatomic) IBOutlet UIImageView *instructionTwoImageView;
@end

@implementation YOEnablePushController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView reloadData];
    
    self.topLabel.text = NSLocalizedString(@"Enable Push", nil);
    self.topLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
    
    self.bottomLabel.text = NSLocalizedString(@"Close", nil);
    self.bottomLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
    
    [self.openSettingsButton setTitle:NSLocalizedString(@"Open Settings", nil) forState:UIControlStateNormal];
    self.openSettingsButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
    
    self.cell.contentView.backgroundColor = [UIColor colorWithHexString:AMETHYST];
    
    if (IS_OVER_IOS(8.0)) {
        self.ios8View.autoresizingMask = self.view.autoresizingMask;
        [self.view addSubview:self.ios8View];
    }
    
    self.instructionOneImageView.layer.shadowColor = [[UIColor colorWithHexString:ASPHALT] CGColor];
    self.instructionOneImageView.layer.shadowOpacity = 0.5f;
    self.instructionOneImageView.layer.shadowRadius = 3.0f;
    self.instructionOneImageView.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    
    self.instructionTwoImageView.layer.shadowColor = [[UIColor colorWithHexString:ASPHALT] CGColor];
    self.instructionTwoImageView.layer.shadowOpacity = 0.5f;
    self.instructionTwoImageView.layer.shadowRadius = 3.0f;
    self.instructionTwoImageView.layer.shadowOffset = CGSizeMake(0.0, 5.0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.instructionsScrollView flashScrollIndicators];
}

#pragma mark - Listeners

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidRegisterForPushNotifications:) name:@"User_Did_Register_For_Push_Notification" object:nil];
}

- (void)userDidRegisterForPushNotifications:(NSNotification *)note {
    [self dismiss];
}

- (void)stopListening {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self stopListening];
}

#pragma mark - Internal Methods

- (void)dismiss {
    id delegate = self.delegate;
    [self dismissViewControllerAnimated:YES completion:^{
        if (delegate) {
            [delegate enablePushControllerDidDismiss];
        }
    }];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cell;
}

#pragma mark - Actions

- (IBAction)close {
    [self dismiss];
}

- (IBAction)userDidPressOpenSettingButton:(UIButton *)sender {
    [[YoiOSAssistant sharedInstance] openYoAppSettings];
}

@end
