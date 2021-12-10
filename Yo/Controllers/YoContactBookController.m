//
//  YoContactBookController.m
//  Yo
//
//  Created by Peter Reveles on 11/30/14.
//
//

#import "YoContactBookController.h"
#import "YoContacts.h"
#import "YOFindFriendCell.h"
#import "YOMainController.h"
#import "MBProgressHUD.h"
#import "YOFacebookManager.h"
#import "YoAddressBookParser.h"

#define kTimeForDoubleTap 0.3

typedef NS_ENUM(NSUInteger, YoContactPickerMode) {
    YoContactPickerModeNoContacts,
    YoContactPickerModeOnYo,
    YoContactPickerModeInvite,
    YoContactPickerModeSearch
};

@interface YoContactBookController () <YoSearchObjectDelegate, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UILabel *YoTitle;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noResultsBottomConstraint;

@property (weak, nonatomic) UIView *sendSMSView;
@property (weak, nonatomic) UILabel *sendSMSLabel;

@property(nonatomic, strong) YoContacts *contactsNotOnYo;
@property(nonatomic, strong) YoContacts *contactsOnYo;

@property(nonatomic, strong) NSMutableArray *numbersToSMS;

@property (nonatomic, assign) NSInteger successFullyInvitedFriendsCount;

@property(nonatomic, readwrite) YoContactPickerMode mode;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property(nonatomic, strong) NSString *textToSMS;

@property (nonatomic, strong) NSString *dismissButtonTitle;

@property (nonatomic, strong) NSMutableSet *friendsYod;

@property (nonatomic, strong) NSMutableSet *usernamesToYoAfterSingleTap;

@end

@implementation YoContactBookController

#define BLANK_CONTACT_TO_ADD_TEXT @"_"
#define BLANK_CONTACT_INSTRUCTIONS_TEXT @"Type USERNAME"
#define CONTACT_INSTRUCTIONS_TEXT @"Tap To Yo"

#pragma mark - Lazy Loading

- (NSMutableArray *)numbersToSMS{
    if (!_numbersToSMS) {
        _numbersToSMS = [NSMutableArray new];
    }
    return _numbersToSMS;
}

- (NSMutableSet *)friendsYod {
    if (!_friendsYod) {
        _friendsYod = [NSMutableSet new];
    }
    return _friendsYod;
}

- (NSMutableSet *)usernamesToYoAfterSingleTap {
    if (!_usernamesToYoAfterSingleTap) {
        _usernamesToYoAfterSingleTap = [[NSMutableSet alloc] init];
    }
    return _usernamesToYoAfterSingleTap;
}

#pragma mark - Life

- (instancetype)initWithContactsOnYo:(YoContacts *)contactsOnYo contactsNotOnYo:(YoContacts *)contactsNotOnYo{
    self = [super init];
    if (self) {
        _contactsNotOnYo = contactsNotOnYo;
        _contactsOnYo = contactsOnYo;
        _textToSMS = nil;
    }
    return self;
}

- (instancetype)initWithShareText:(NSString *)text{
    self = [super init];
    if (self) {
        _contactsOnYo = nil;
        _contactsNotOnYo = nil;
        _textToSMS = text;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupUI];
    
    [self.contactsNotOnYo setFilterBy:YoContactFilter_byFullName];
    [self.contactsOnYo setFilterBy:YoContactFilter_byFullName];
    
    if (!self.contactsOnYo && !self.contactsNotOnYo) {
        // pull contacts
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        
        [YoAddressBookParser obtainAddressBookWithCompletionBlock:^(YoAddressBookPermission permission, ABAddressBookRef addressBook) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (permission == YoAddressBookPermissionGranted) {
                self.contactsNotOnYo = [YoAddressBookParser extractContactsFromAddressBook:addressBook];
                self.searchBar.delegate = self.contactsNotOnYo;
                self.contactsNotOnYo.filterBy = YoContactFilter_byFullName;
                [self filterContactsAndUpdateMode:YES];
                [self.tableView reloadData];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Please enable contacts access", nil)
                                                           desciption:NSLocalizedString(@"Settings -> Privacy -> Contacts -> Yo", nil)];
                    [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
                    if ([[YoiOSAssistant sharedInstance] canOpenYoAppSettings]) {
                        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"open settings", nil).capitalizedString tapBlock:^{
                            [[YoiOSAssistant sharedInstance] openYoAppSettings];
                        }]];
                    }
                    [[YoAlertManager sharedInstance] showAlert:yoAlert];
                });
            }
        }];
        
        [self setupForSMSOnly];
    }
    else {
        if (![[self.contactsOnYo allContacts] count]) {
            self.searchBar.delegate = self.contactsNotOnYo;
            //[self setupForSMSOnly];
        }
        else {
            self.searchBar.delegate = self.contactsOnYo;
        }
        
        [self filterContactsAndUpdateMode:YES];
        [self.tableView reloadData];
    }
    
    if ([self.dismissButtonTitle length])
        [self.backButton setTitle:self.dismissButtonTitle forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)setupForSMSOnly {
    // Back should be done
    if (![self.dismissButtonTitle length])
        [self.backButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    
    // hide On Yo - INVITE toggle switch
    self.segmentedControl.hidden = YES;
    
    // Show Facebook Button
    [self.inviteButton setTitle:NSLocalizedString(@"Facebook", nil) forState:UIControlStateNormal];
    self.inviteButton.layer.cornerRadius = 5.0f;
    self.inviteButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.inviteButton.layer.borderWidth = 1.0f;
    [self.inviteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.inviteButton.hidden = NO;
    
    [self.inviteButton addTarget:self action:@selector(inviteThroughFacebook:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI{
    //self.searchBar.delegate = self.dataSource;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.tintColor = [UIColor colorWithHexString:SUNFLOWER];
    // keeps cancel button a different color than tintcolor
    if (IS_OVER_IOS(7.0)) {
        [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
    }
    self.searchBar.backgroundImage = [UIImage new];
    self.searchBar.translucent = YES;
    self.searchBar.showsSearchResultsButton = NO;

    self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
    
    self.contactsNotOnYo.delegate = self;
    self.contactsOnYo.delegate = self;
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    // rounding back button
    self.backButton.layer.cornerRadius = 5.0f;
    self.backButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.backButton.layer.borderWidth = 1.0f;
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headerViewTapped:)];
    [self.headerView addGestureRecognizer:tapGR];
    
    self.YoTitle.adjustsFontSizeToFitWidth = YES;
    self.YoTitle.minimumScaleFactor = 0.1f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardWillShowNotification:(NSNotification *)note{
    NSValue* keyboardFrameBegin = [[note userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [keyboardFrameBegin CGRectValue];
    
    self.noResultsBottomConstraint.constant = -keyboardRect.size.height;
    
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

#pragma mark - Hack

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    // hack to supress base controller from moving tableview
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - Actions

- (void)inviteThroughFacebook:(UIButton *)button{
    [self inviteViaFacebook];
}

- (void)headerViewTapped:(id)sender{
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

- (IBAction)segmentControlToggled:(id)sender {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            self.mode = YoContactPickerModeOnYo;
            break;
            
        case 1:
            self.mode = YoContactPickerModeInvite;
            break;
            
        case 2:
            self.mode = YoContactPickerModeSearch;
            break;
    }
}

- (void)close {
    [self.contactsOnYo clearFilteredData];
    [self.contactsNotOnYo clearFilteredData];
    
    id delegate = self.delegate;
    NSInteger successFullyInvitedFriendsCount = self.successFullyInvitedFriendsCount;
    NSSet *friendsYod = self.friendsYod;
    [self dismissViewControllerAnimated:YES completion:^{
        if (delegate) {
            if ([delegate respondsToSelector:@selector(yoContactBookDidCloseWithNumberOfFriendsInvited:friendsYod:)]) {
                [delegate yoContactBookDidCloseWithNumberOfFriendsInvited:successFullyInvitedFriendsCount friendsYod:friendsYod];
            }
        }
    }];
}

- (IBAction)backButtonPressed:(id)sender {
    [self close];
}

- (void)sendSMSTapped{
    NSString *text = self.textToSMS?:MakeString(@"Yo\nhttp://justyo.co/%@", [[YoUser me] username]);
    [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:self.numbersToSMS text:text resultBlock:^(MessageComposeResult result) {
        if (result == MessageComposeResultSent) {
            self.successFullyInvitedFriendsCount += [self.numbersToSMS count];
            [self restoreTableView];
        }
    }];
    
    [YoAnalytics logEvent:YoEventInvitedContactsNotOnYo withParameters:@{YoParam_USER_ALIEN_PHONE_NUMBERS:self.numbersToSMS?:@[]}];
}

- (void)showSendSMSViewForCellAtIndexPath:(NSIndexPath *)indexPath{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    if (!self.sendSMSView) {
        UIView *sendSMSView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetHeight(screenRect), CGRectGetWidth(screenRect), 89.0f)];
        sendSMSView.backgroundColor = [UIColor colorWithHexString:WISTERIA];
        sendSMSView.hidden = YES;
        [self.view addSubview:sendSMSView];
        
        UILabel *sendLabel = [UILabel new];
        sendLabel.backgroundColor = [UIColor clearColor];
        sendLabel.translatesAutoresizingMaskIntoConstraints = NO;
        sendLabel.opaque = NO;
        sendLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
        sendLabel.textColor = [UIColor whiteColor];
        sendLabel.textAlignment = NSTextAlignmentCenter;
        sendLabel.text = @"Send (1)";
        
        [sendSMSView addSubview:sendLabel];
        NSDictionary *views = NSDictionaryOfVariableBindings(sendLabel);
        [sendSMSView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sendLabel]|" options:0 metrics:nil views:views]];
        [sendSMSView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sendLabel]|" options:0 metrics:nil views:views]];
        
        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendSMSTapped)];
        [sendSMSView addGestureRecognizer:tapGR];
        
        self.sendSMSView = sendSMSView;
        self.sendSMSLabel = sendLabel;
    }
    
    if (self.sendSMSView.hidden) {
        self.sendSMSView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.sendSMSView.centerY = CGRectGetHeight(screenRect) - self.sendSMSView.height/2.0f;
        }];
        // this is to make sure last cell is visible
        [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                         self.tableView.contentInset.left,
                                                         self.sendSMSView.height,
                                                         self.tableView.contentInset.right)];
        
        YOCell *cell = (YOCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        CGRect cellRectRelativeToSelfDotView = [self.view convertRect:cell.frame fromView:self.tableView];
        
        if (CGRectGetMaxY(cellRectRelativeToSelfDotView) > (CGRectGetMaxY(self.tableView.frame) - self.sendSMSView.height)) {
            CGFloat offsetForOfOffScreenCell = CGRectGetMaxY(cellRectRelativeToSelfDotView) - CGRectGetMaxY(self.tableView.frame);
            
            CGFloat scrollContentOffset_y = self.tableView.contentOffset.y + self.sendSMSView.height +  offsetForOfOffScreenCell;
            
            CGPoint offsetForSmsView = CGPointMake(self.tableView.contentOffset.x, scrollContentOffset_y);
            [self.tableView setContentOffset:offsetForSmsView animated:YES];
        }
    }
}

- (void)hideSendSMSViewForIndexPath:(NSIndexPath *)indexPath{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    if (!self.sendSMSView.hidden) {
        [UIView animateWithDuration:0.3 animations:^{
            self.sendSMSView.centerY = CGRectGetHeight(screenRect) + self.sendSMSView.height/2.0f;
        } completion:^(BOOL finished) {
            self.sendSMSView.hidden = YES;
            [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                             self.tableView.contentInset.left,
                                                             0.0f,
                                                             self.tableView.contentInset.right)];
        }];
        
        if (indexPath) {
            YOCell *cell = (YOCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            CGRect cellRectRelativeToSelfDotView = [self.view convertRect:cell.frame fromView:self.tableView];
            
            if ((CGRectGetMaxY(cellRectRelativeToSelfDotView) > (CGRectGetMaxY(self.tableView.frame) - self.sendSMSView.height)) ||
                ([self.tableView indexPathForCell:self.tableView.visibleCells.lastObject ] == indexPath)) {
                CGPoint offsetForSmsView = CGPointMake(self.tableView.contentOffset.x, MAX(0, (self.tableView.contentOffset.y - self.sendSMSView.height)));
                [self.tableView setContentOffset:offsetForSmsView animated:YES];
            }
        }
    }
}

#pragma mark - Table View

- (void)restoreTableView{
    [self.numbersToSMS removeAllObjects];
    [self hideSendSMSViewForIndexPath:[self.tableView indexPathForCell:[self.tableView.visibleCells firstObject]]];
    [self.tableView reloadData];
}

- (void)configureCell:(YOFindFriendCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    NSString *header = @"";
    NSString *description = @"";
    
    if (self.mode == YoContactPickerModeOnYo) {
        // contact on yo
        YoUser *contact = [self.contactsOnYo filteredData][indexPath.row];
        header = contact.username;
        description = contact.fullName;
    }
    else if (self.mode == YoContactPickerModeInvite) {
        // contact not on yo
        YoUser *contact = [self.contactsNotOnYo filteredData][indexPath.row];
        header = contact.fullName;
        description = contact.phoneNumber;
        
        // shouldnt have to resetup cell profile view. This is a hack to make it work.
        if ([self.numbersToSMS containsObject:[contact phoneNumber]]) {
        }
    }
    
    cell.label.text = header;
    cell.nameLabel.text = description;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YOFindFriendCell *cell = (YOFindFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    YoUser *contact = nil;
    
    if (self.mode == YoContactPickerModeOnYo) {
        cell.label.hidden = YES;
        cell.nameLabel.hidden = YES;
        [cell.aiView startAnimating];
        cell.aiView.hidden = NO;
        
        contact = [self.contactsOnYo filteredData][indexPath.row];
        NSString *username = [contact username];
        
        if ([self.usernamesToYoAfterSingleTap containsObject:username]) {
            [self.usernamesToYoAfterSingleTap removeObject:username];
            [self userDoubleTappedCell:cell];
        }
        else {
            [self.usernamesToYoAfterSingleTap addObject:username];
            double delayInSeconds = kTimeForDoubleTap;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ([self.usernamesToYoAfterSingleTap containsObject:username]) {
                    [self.usernamesToYoAfterSingleTap removeObject:username];
                    [self userSingleTappedCell:cell];
                }
            });
        }
    }
    else if (self.mode == YoContactPickerModeInvite) {
        [self.searchBar resignFirstResponder];
        contact = [self.contactsNotOnYo filteredData][indexPath.row];
        
                
        self.sendSMSLabel.text = MakeString(@"%@ (%i)", NSLocalizedString(@"Send", nil), (int)[self.numbersToSMS count]);
    }
    else if (self.mode == YoContactPickerModeSearch) {
        if (indexPath.row == 0) {
            [self userDidTapManualAddContactCell:cell];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 89.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == YoContactPickerModeSearch) {
        YOFindFriendCell *cell = (YOFindFriendCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        if ([self.searchBar.text length]) {
            [self updateManualAddCell:cell withText:self.searchBar.text];
        }
        else {
            [cell.label setText:BLANK_CONTACT_TO_ADD_TEXT];
            [cell.nameLabel setText:BLANK_CONTACT_INSTRUCTIONS_TEXT];
        }
        [self colorCell:cell withIndexPath:indexPath];
        return cell;
    }
    else {
        YOFindFriendCell *cell = (YOFindFriendCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        [self configureCell:cell withIndexPath:indexPath];
        [self colorCell:cell withIndexPath:indexPath];
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfResultsAvailable = [self numberOfResultsForMode:self.mode];
    [self toggleNoResultsBannerAsNeccessary];
    return numberOfResultsAvailable;
}

#pragma mark - Taps

- (void)userDidTapManualAddContactCell:(YOFindFriendCell *)cell{
    if ([cell.label.text isEqualToString:BLANK_CONTACT_TO_ADD_TEXT]) {
        [self.searchBar becomeFirstResponder];
    }
    else {
        cell.label.hidden = YES;
        cell.nameLabel.hidden = YES;
        [cell.aiView startAnimating];
        cell.aiView.hidden = NO;
        
        NSString *username = cell.label.text;
        __weak YoContactBookController *weakSelf = self;
        
        void (^usernameDoesNotExistBlock)() = ^(){
            NSString  *title = NSLocalizedString(@"No Such User", nil);
            NSString *body = MakeString(NSLocalizedString(@"%@ does not exist", @"{username} does not exist"), username);
            YoAlert *alert = [[YoAlert alloc] initWithTitle:title desciption:body];
            [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil) tapBlock:^{
                if (cell && weakSelf.mode == YoContactPickerModeSearch) {
                    cell.aiView.hidden = YES;
                    cell.label.text = username;
                    cell.nameLabel.hidden = NO;
                    cell.label.hidden = NO;
                    cell.bannerLabel.hidden = YES;
                }
            }]];
            [[YoAlertManager sharedInstance] showAlert:alert];
        };
        
        void (^usernameExistsBlock)() = ^(){
            if ([weakSelf.usernamesToYoAfterSingleTap containsObject:username]) {
                [weakSelf.usernamesToYoAfterSingleTap removeObject:username];
                [weakSelf yoUsername:username withLocation:YES animateCell:cell];
            }
            else {
                [weakSelf.usernamesToYoAfterSingleTap addObject:username];
                double delayInSeconds = kTimeForDoubleTap;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if ([weakSelf.usernamesToYoAfterSingleTap containsObject:username]) {
                        [weakSelf.usernamesToYoAfterSingleTap removeObject:username];
                        [weakSelf yoUsername:username withLocation:NO animateCell:cell];
                    }
                });
            }
        };
        
        [[YoAPIClient new] POST:@"rpc/user_exists" parameters:@{@"username":username} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NS_DURING
            if (![[responseObject valueForKey:@"exists"] boolValue]) {
                usernameDoesNotExistBlock();
                return;
            }
            NS_HANDLER
            NS_ENDHANDLER
            usernameExistsBlock();
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            usernameExistsBlock();
        }];
    }
}

- (void)userSingleTappedCell:(YOFindFriendCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.row != NSNotFound) {
        YoUser *contact = [self.contactsOnYo filteredData][indexPath.row];
        NSString *username = [contact username];
        [self yoUsername:username withLocation:NO animateCell:cell];
    }
}

- (void)userDoubleTappedCell:(YOFindFriendCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.row != NSNotFound) {
        YoUser *contact = [self.contactsOnYo filteredData][indexPath.row];
        NSString *username = [contact username];
        [self yoUsername:username withLocation:YES animateCell:cell];
    }
}

- (void)yoUsername:(NSString *)username withLocation:(BOOL)withLocation animateCell:(YOFindFriendCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    /*[[YoManager sharedInstance] yo:username withCurrentLocation:withLocation completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
        NSString *successText = NSLocalizedString(@"SENT YO!", nil);
        if (result == YoResultSuccess) {
            if (withLocation) {
                successText = NSLocalizedString(@"SENT @YO!", nil);
            }
            [[RavenClient sharedClient] captureMessage:@"Sent Yo from ff" level:kRavenLogLevelDebugInfo];
        }
        else {
            successText = NSLocalizedString(@"FAILED", nil);
            [[RavenClient sharedClient] captureMessage:@"Failed Yo from ff" level:kRavenLogLevelDebugInfo];
        }
        
        if (cell && [[self.tableView indexPathForCell:cell] isEqual:indexPath]) {
            cell.bannerLabel.text = successText;
            cell.bannerLabel.hidden = NO;
            cell.aiView.hidden = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (cell && [[self.tableView indexPathForCell:cell] isEqual:indexPath]) {
                    cell.label.text = username;
                    cell.nameLabel.hidden = NO;
                    cell.label.hidden = NO;
                    cell.bannerLabel.hidden = YES;
                }
            });
        }
    }];*/
    
    // @or: implement when decided how find friends sends location
     
    [self.friendsYod addObject:username];
    
    if (withLocation) {
        [YoAnalytics logEvent:YoEventSentYoLocation withParameters:@{YoParam_USERNAME:username}];
    }
    else {
        [YoAnalytics logEvent:YoEventSentYo withParameters:@{YoParam_USERNAME:username}];
    }
}

#pragma mark - Management

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath {
    return @"YOFindFriendCell";
}

- (NSString *)topText {
    return NSLocalizedString(@"TAP NAME TO YO", nil).lowercaseString.capitalizedString;
}

- (NSString *)bottomText {
    return NSLocalizedString(@"DONE", nil).lowercaseString.capitalizedString ;
}

- (void)setMode:(YoContactPickerMode)mode{
    YoContactPickerMode oldMode = self.mode;
    _mode = mode;
    
    BOOL shouldScrollUpAfterReload = [self numberOfResultsForMode:mode];
    
    if (mode == YoContactPickerModeOnYo) {
        [self.segmentedControl setSelectedSegmentIndex:0];
        
        [self.searchBar setText:@""];
        [self.searchBar setPlaceholder:@"Name"];
        [self.searchBar resignFirstResponder];
        self.searchBar.delegate = self.contactsOnYo;
        [self setSearchBar:self.searchBar returnKeyType:UIReturnKeySearch];
        
        self.YoTitle.text = NSLocalizedString(@"Tap Name To Yo", nil);
        self.YoTitle.font = [UIFont fontWithName:@"Montserrat-Bold" size:32];
        [self hideSendSMSViewForIndexPath:nil];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        if (shouldScrollUpAfterReload) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        [self.contactsNotOnYo clearFilteredData];
    }
    else if (mode == YoContactPickerModeNoContacts) {
        [self setMode:YoContactPickerModeSearch];
//        [self.segmentedControl setSelectedSegmentIndex:0];
//        self.YoTitle.text = NSLocalizedString(@"No Contacts", nil);
//        self.YoTitle.font = [UIFont fontWithName:@"Montserrat-Bold" size:32];
    }
    else if (mode == YoContactPickerModeInvite) {
        [self.segmentedControl setSelectedSegmentIndex:1];
        
        [self.searchBar setText:@""];
        [self.searchBar setPlaceholder:@"Name"];
        [self.searchBar resignFirstResponder];
        self.searchBar.delegate = self.contactsNotOnYo;
        [self setSearchBar:self.searchBar returnKeyType:UIReturnKeySearch];
        
        self.YoTitle.text = NSLocalizedString(@"Tap Name To Invite", nil);
        self.YoTitle.font = [UIFont fontWithName:@"Montserrat-Bold" size:30];
        if ([self.numbersToSMS count]) {
            dispatch_after(1.0, dispatch_get_main_queue(), ^{
                [self showSendSMSViewForCellAtIndexPath:[self.tableView indexPathForCell:self.tableView.visibleCells.firstObject]];
            });
        }
        
        UITableViewRowAnimation animation = UITableViewRowAnimationLeft;
        if (oldMode == YoContactPickerModeSearch) {
            animation = UITableViewRowAnimationRight;
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];
        if (shouldScrollUpAfterReload) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        [self.contactsOnYo clearFilteredData];
    }
    else if (self.mode == YoContactPickerModeSearch) {
        [self.segmentedControl setSelectedSegmentIndex:2];
        
        [self.searchBar setText:@""];
        [self.searchBar setPlaceholder:@"USERNAME"];
        [self.searchBar resignFirstResponder];
        self.searchBar.delegate = self;
        
        [self setSearchBar:self.searchBar returnKeyType:UIReturnKeyDone];
        
        self.YoTitle.text = NSLocalizedString(@"Tap Name To Yo", nil);
        self.YoTitle.font = [UIFont fontWithName:@"Montserrat-Bold" size:32];
        [self hideSendSMSViewForIndexPath:nil];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
        if (shouldScrollUpAfterReload) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        
        [self.searchBar becomeFirstResponder];
        
        [self.contactsOnYo clearFilteredData];
    }
}

- (void)setSearchBar:(UISearchBar *)searchBar returnKeyType:(UIReturnKeyType)type {
    for(UIView *subView in [self.searchBar subviews]) {
        if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
            [(UITextField *)subView setReturnKeyType:type];
        } else {
            for(UIView *subSubView in [subView subviews]) {
                if([subSubView conformsToProtocol:@protocol(UITextInputTraits)]) {
                    [(UITextField *)subSubView setReturnKeyType:type];
                }
            }
        }
    }
}

- (void)updateMode{
    BOOL thereAreContactsOnYo = [[self.contactsOnYo filteredData] count];
    BOOL thereAreContactsNotOnYo = [[self.contactsNotOnYo filteredData] count];
    
    if (!thereAreContactsNotOnYo && !thereAreContactsOnYo) {
        self.mode = YoContactPickerModeNoContacts;
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:2];
    }
    else if (!thereAreContactsOnYo) {
        self.mode = YoContactPickerModeInvite;
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:1];
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:2];
    }
    else if (!thereAreContactsNotOnYo) {
        self.mode = YoContactPickerModeOnYo;
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:0];
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:2];
    }
    else
        self.mode = YoContactPickerModeOnYo;
}

#pragma mark - YoDataSourceDelegate

- (void)filterContactsAndUpdateMode:(BOOL)updateMode{
    if (updateMode) [self updateMode];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)numberOfResultsForMode:(YoContactPickerMode)mode{
    NSInteger numberResultsAvailable = 0;
    switch (self.mode) {
        case YoContactPickerModeNoContacts:
            numberResultsAvailable = 0;
            break;
            
        case YoContactPickerModeOnYo:
            numberResultsAvailable = [[self.contactsOnYo filteredData] count];
            break;
            
        case YoContactPickerModeInvite:
            numberResultsAvailable = [[self.contactsNotOnYo filteredData] count];
            break;
            
        case YoContactPickerModeSearch:
            numberResultsAvailable = 1;
            break;
            
        default:
            numberResultsAvailable = 0;
            break;
    }
    return numberResultsAvailable;
}

- (void)toggleNoResultsBannerAsNeccessary{
        
    NSInteger numberResultsAvailable = [self numberOfResultsForMode:self.mode];
    
    if (!numberResultsAvailable) {
        // no results
        if (self.noResultsLabel.hidden) {
            self.noResultsLabel.alpha = 0.0f;
            self.noResultsLabel.hidden = NO;
            [UIView animateWithDuration:0.2 animations:^{
                self.noResultsLabel.alpha = 1.0f;
            }];
        }
    }
    else {
        // there are results
        if (!self.noResultsLabel.hidden) {
            [UIView animateWithDuration:0.1 animations:^{
                self.noResultsLabel.alpha = 0.0f;
            } completion:^(BOOL finished) {
                self.noResultsLabel.hidden = YES;
            }];
        }
        //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)dataWasUpdated{
    [self filterContactsAndUpdateMode:NO];
}

#pragma mark - UISearchBarDelegate 

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (self.mode == YoContactPickerModeSearch) {
        YOFindFriendCell *cell = (YOFindFriendCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self updateManualAddCell:cell withText:searchText];
    }
}

- (void)updateManualAddCell:(YOFindFriendCell *)cell withText:(NSString *)text {
    if ([text length]) {
        NSString *validUsername = text;
        NSCharacterSet *illegalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"-/:;()$&@\".,?!\' "];
        validUsername = [[validUsername componentsSeparatedByCharactersInSet:illegalCharacterSet] componentsJoinedByString:@""];
        validUsername = validUsername.uppercaseString;
        [cell.label setText:validUsername];
        [cell.nameLabel setText:CONTACT_INSTRUCTIONS_TEXT];
    }
    else {
        [cell.label setText:BLANK_CONTACT_TO_ADD_TEXT];
        [cell.nameLabel setText:BLANK_CONTACT_INSTRUCTIONS_TEXT];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    [self searchBar:searchBar textDidChange:@""];
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
