//
//  YoAddMembersController.m
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import "YoAddController.h"
#import <RHAddressBook/AddressBook.h>
#import "YoContactManager.h"
#import "YoUser.h"
#import "YoGroup.h"
#import "YoAddGroupMemberCell.h"
#import "YoTableViewSheetController.h"
#import "YoApp.h"
#import "YoGroupMemberDisplayView.h"
#import "YoContact.h"
#import "NSDate_Extentions.h"

@interface YoAddController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, YoGroupMemberDisplayViewDelegate>

@property (nonatomic, strong) YoContact *selectedMember;
@property (nonatomic, strong) NSMutableOrderedSet *addedMembers;
@property (nonatomic, strong) UIBarButtonItem *createButton;

@property (weak, nonatomic) UIActionSheet *selectPhoneNumberActionSheet;
@property (weak, nonatomic) UIActionSheet *addedGroupMemberActionOptionsSheet;

@property (weak, nonatomic) IBOutlet YoGroupMemberDisplayView *groupMemberDisplayView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupMemberDisplayBottomToScreenConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupMemberDisplayTopToBottomOfScreenConstraint;

@end

@implementation YoAddController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.textField.layer.cornerRadius = 5;
    self.textField.layer.masksToBounds = YES;
    self.textField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.textField.tintColor = [UIColor whiteColor];
    self.textField.delegate = self;
    
    self.groupMemberDisplayView.delegate = self;
    
    self.addedMembers = [NSMutableOrderedSet new];
    
    [self setupOKButton];
    
    switch (self.mode) {
        case YoAddControllerAddToRecentsList: {
            self.navigationItem.title = NSLocalizedString(@"add to friends", nil).capitalizedString;
        }
            break;
        case YoAddControllerCreateGroup: {
            self.navigationItem.title = NSLocalizedString(@"add members", nil).capitalizedString;
        }
            break;
        case YoAddControllerAddToGroup: {
            self.navigationItem.title = NSLocalizedString(@"add members", nil).capitalizedString;
        }
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)setupOKButton {
    UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithTitle:[self getCreateButtonTitle]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(okButtonPressed)];
    UIBarButtonItem *fixedWidth = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidth.width = 5.0f;
    self.navigationItem.rightBarButtonItems = @[fixedWidth, createButton];
    createButton.enabled = NO;
    _createButton = createButton;
    
    [self.navigationItem.backBarButtonItem setTitle:@""];}

#pragma mark - Actions

- (void)addToRecents {
    for (YoContact *member in [self.addedMembers reversedOrderedSet]) {
        NS_DURING
        
        YoUser *user = [YoUser new];
        
        user.username = member.username ? member.username : @"";
        user.fullName = member.fullName;
        user.displayName = member.fullName;
        user.phoneNumber = member.phoneNumber;
        if (member.lastSeenDate) {
            user.lastSeenDate = member.lastSeenDate;
        }
        
        [[[YoUser me] contactsManager] promoteObjectToTop:user];
        [[[YoUser me] contactsManager] addObject:user
                             withCompletionBlock:nil];
        
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    [self closeWithCompletionBlock:^{
        [[APPDELEGATE mainController] animateTopCells:self.addedMembers.count];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:MakeString(@"did.show.first.yo.tip.%@", [YoUser me].username)] == NO) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MakeString(@"should_show_first_yo_tip_for_%@", [YoUser me].username)];
        }
    }];
}

- (void)createGroup {
    NSMutableArray *rawGroupMembers = [[NSMutableArray alloc] init];
    for (YoContact *member in self.addedMembers) {
        NS_DURING
        NSMutableDictionary *rawMember = [NSMutableDictionary dictionary];
        [rawMember setObject:member.userType forKey:@"user_type"];
        if (member.fullName) {
            [rawMember setObject:member.fullName forKey:@"name"];
        }
        if (member.username) {
            [rawMember setObject:member.username forKey:@"username"];
        }
        if (member.phoneNumber) {
            [rawMember setObject:member.phoneNumber forKey:@"phone_number"];
        }
        [rawGroupMembers addObject:rawMember];
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    
    UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [aiView startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiView];
    self.createButton.enabled = NO;
    
    [[YoApp currentSession] createGroupWithName:self.group.name
                             andMemberUsernames:rawGroupMembers
                              completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                  self.navigationItem.rightBarButtonItem = self.createButton;
                                  if (result == YoResultSuccess) {
                                      YoGroup *group = [YoGroup objectFromDictionary:responseObject[@"group"]];
                                      [[[YoUser me] contactsManager] promoteObjectToTop:group];
                                      [self closeWithCompletionBlock:^{
                                          [[APPDELEGATE mainController] animateTopCells:1];
                                      }];
                                  }
                                  else {
                                      self.createButton.enabled = YES;
                                      YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Failed" desciption:@"Try again later?"];
                                      [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
                                      [[YoAlertManager sharedInstance] showAlert:alert];
                                  }
                              }];
}

- (void)addToGroup {
    
    NSMutableArray *membersAsUsers = [[NSMutableArray alloc] init];
    for (YoContact *member in self.addedMembers) {
        
        NS_DURING
        
        YoUser *user = [YoUser new];
        
        user.username = member.username;
        user.fullName = member.fullName;
        user.displayName = member.fullName;
        user.phoneNumber = member.phoneNumber;
        if (member.lastSeenDate) {
            user.lastSeenDate = member.lastSeenDate;
        }
        
        [membersAsUsers addObject:user];
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
        
    }
    [[YoApp currentSession] addMembersToGroup:self.group
                          multipleUserObjects:membersAsUsers
                            completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                if (result == YoResultSuccess) {
                                    [self closeWithCompletionBlock:^{
                                    }];
                                }
                                else {
                                    self.createButton.enabled = YES;
                                    YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Failed" desciption:@"Try again later?"];
                                    [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
                                    [[YoAlertManager sharedInstance] showAlert:alert];
                                }
                            }];
}

- (void)okButtonPressed {
    [self.textField resignFirstResponder];
    
    switch (self.mode) {
        case YoAddControllerAddToRecentsList:
            [self addToRecents];
            break;
        case YoAddControllerCreateGroup:
            [self createGroup];
            break;
        case YoAddControllerAddToGroup:
            [self addToGroup];
            break;
    }
}

#pragma mark Utility

- (NSString *)getCreateButtonTitle {
    return MakeString(NSLocalizedString(@"(%lu) OK", @"the variable is a number"),
                      self.addedMembers.count);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YOCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YOCell"];
    if (cell == nil) {
        cell = LOAD_NIB(@"YOCell");
        cell.label.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
        cell.label.textColor = [UIColor whiteColor];
    }
    
    cell.contentView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    YoContact *contact = nil;
    
    if (self.textField.text.length == 0) {
        contact = self.allCombined[indexPath.row];
    }
    else {
        if (indexPath.row < self.filteredCombined.count) {
            contact = self.filteredCombined[indexPath.row];
        }
        else { // @or: last row show add by username
            cell.label.text = [self.textField.text uppercaseString];
            cell.statusLabel.text = @"Tap to add by username";
            return cell;
        }
    }
    
    if ([contact.fullName isEqualToString:contact.username]) {
        cell.label.text = contact.fullName;
    }
    else {
        if (contact.fullName.length > 0) {
            cell.label.text = MakeString(@"%@", contact.fullName);
        }
        else {
            cell.label.text = MakeString(@"%@", contact.username);
        }
    }
    
    cell.contentView.backgroundColor = [self colorForRow:indexPath.row];
    
    if ([contact.source isEqualToString:@"address_book_on_yo"] ||
        [contact.source isEqualToString:@"recent"] ||
        [contact.source isEqualToString:@"facebook"]) {
        NSString *lastSeenString = [contact.lastSeenDate agoString] ? [contact.lastSeenDate agoString] : @"Way back";
        cell.statusLabel.text = MakeString(@"On Yo as %@ - Last seen: %@", contact.username, lastSeenString);
    }
    else {
        cell.statusLabel.text = MakeString(@"Not on Yo - %@", contact.phoneNumber);
    }
    
    return cell;
}

- (UIColor *)colorForRow:(NSUInteger)row {
    switch (row % 7) {
        case 0:
            return [UIColor colorWithHexString:TURQUOISE];
            
        case 1:
            return [UIColor colorWithHexString:EMERALD];
            
        case 2:
            return [UIColor colorWithHexString:PETER];
            
        case 3:
            return [UIColor colorWithHexString:ASPHALT];
            
        case 4:
            return [UIColor colorWithHexString:GREEN];
            
        case 5:
            return [UIColor colorWithHexString:SUNFLOWER];
            
        case 6:
            return [UIColor colorWithHexString:BELIZE];
            
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    YoContact *member = nil;
    if (self.textField.text.length == 0) {
        member = self.allCombined[indexPath.row];
    }
    else {
        if (indexPath.row < self.filteredCombined.count) {
            member = self.filteredCombined[indexPath.row];
        }
        else {
            [self addByUsername];
            return;
        }
    }
    
    [self addGroupMember:member];
    
    self.textField.text = @"";
    [self.tableView reloadData];
    [self.textField resignFirstResponder];
}

#pragma mark - YoGroupMemberDisplayViewDelegate

- (void)yoGroupMemberDisplayView:(YoGroupMemberDisplayView *)view
                 didSelectMember:(YoContact *)member
{
    self.selectedMember = member;
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:member.fullName
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"done", nil).capitalizedString
                                         destructiveButtonTitle:[self getRemoveTextFromMode:self.mode]
                                              otherButtonTitles:nil];
    [sheet showInView:self.view];
    self.addedGroupMemberActionOptionsSheet = sheet;
}

- (NSString *)getRemoveTextFromMode:(YoAddControllerMode)mode {
    switch (mode) {
        case YoAddControllerAddToGroup:
            return NSLocalizedString(@"Remove", nil);
            break;
            
        case YoAddControllerAddToRecentsList:
            return NSLocalizedString(@"Remove", nil);
            break;
            
        case YoAddControllerCreateGroup:
            return NSLocalizedString(@"Remove from Group", nil);
            break;
    }
}

#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    if ([actionSheet isEqual:self.selectPhoneNumberActionSheet]) {
        self.selectedMember.phoneNumber = [actionSheet buttonTitleAtIndex:buttonIndex];
        [self addGroupMember:self.selectedMember];
        self.selectedMember = nil;
    }
    else if ([actionSheet isEqual:self.addedGroupMemberActionOptionsSheet]) {
        [self removeGroupMember:self.selectedMember];
        self.selectedMember = nil;
    }
}

#pragma mark - Animations

- (void)showGroupMembersDisplayViewWithCompletionBlock:(void (^)())block {
    [self.view layoutIfNeeded];
    
    [self.view removeConstraint:self.groupMemberDisplayTopToBottomOfScreenConstraint];
    self.groupMemberDisplayBottomToScreenConstraint = [NSLayoutConstraint
                                                       constraintWithItem:self.groupMemberDisplayView attribute:NSLayoutAttributeBottom
                                                       relatedBy:NSLayoutRelationEqual
                                                       toItem:self.view attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0f constant:0.0f];
    [self.view addConstraint:self.groupMemberDisplayBottomToScreenConstraint];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (block) {
            block();
        }
    }];
}

- (void)hideGroupMembersDisplayViewWithCompletionBlock:(void (^)())block {
    [self.view layoutIfNeeded];
    
    [self.view removeConstraint:self.groupMemberDisplayBottomToScreenConstraint];
    self.groupMemberDisplayTopToBottomOfScreenConstraint = [NSLayoutConstraint
                                                            constraintWithItem:self.groupMemberDisplayView attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.view attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0f constant:0.0f];
    [self.view addConstraint:self.groupMemberDisplayTopToBottomOfScreenConstraint];
    
    [UIView animateWithDuration:0.4 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (block) {
            block();
        }
    }];
}

#pragma mark - Internal

- (void)addedMembersDidChange {
    self.createButton.enabled = (self.addedMembers.count > 0);
    [self.createButton setTitle:[self getCreateButtonTitle]];
    [self.tableView reloadData];
}

- (void)addGroupMember:(YoContact *)member {
    
    if ([member.userType isEqualToString:@"pseudo_user"]) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Invite to Yo?"
                                               desciption:[NSString stringWithFormat:@"%@ is not on Yo. do you want to invite with a text?", member.fullName]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Nah", nil)
                                     tapBlock:^{
                                         
                                     }]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:@"Yes"
                                     tapBlock:^{
                                         NSString *text = MakeString(@"Yo from %@.\n\nget the Yo app it's cool", [YoUser me].displayName);
                                         NSString *number = MakeString(@"+%@", member.phoneNumber);
                                         [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:@[number]
                                                                                                        text:text
                                                                                                 resultBlock:^(MessageComposeResult result) {
                                                                                                 }];
                                     }]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
        return;
    }
    
    void (^addMember)() = ^(YoContact *member){
        [self.addedMembers addObject:member];
        [self.groupMemberDisplayView addMember:member];
        [self.allCombined removeObject:member];
        [self.filteredCombined removeObject:member];
        [self addedMembersDidChange];
    };
    if (self.addedMembers.count == 0) {
        [self showGroupMembersDisplayViewWithCompletionBlock:^{
            addMember(member);
        }];
    }
    else {
        addMember(member);
    }
}

- (void)removeGroupMember:(YoContact *)member {
    [self.addedMembers removeObject:member];
    [self.groupMemberDisplayView removeMember:member];
    [self.allCombined addObject:member];
    [self.filteredCombined addObject:member];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fullName"
                                                                   ascending:YES
                                                                  comparator:^NSComparisonResult(id obj1, id obj2) {
                                                                      return [obj1 caseInsensitiveCompare:obj2];
                                                                  }];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"username"
                                                                    ascending:YES
                                                                   comparator:^NSComparisonResult(id obj1, id obj2) {
                                                                       return [obj1 caseInsensitiveCompare:obj2];
                                                                   }];
    self.allCombined = [[self.allCombined sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    self.filteredCombined = [[self.filteredCombined sortedArrayUsingDescriptors:@[sortDescriptor, sortDescriptor2]] mutableCopy];
    [self addedMembersDidChange];
    
    if (self.addedMembers.count == 0) {
        [self hideGroupMembersDisplayViewWithCompletionBlock:nil];
    }
}

- (void)addByUsername {
    NSString *username = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    void (^usernameDoesNotExistBlock)() = ^(){
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Yo" text:MakeString(NSLocalizedString(@"%@ does not exist", @"{username} does not exist"), username)];
    };
    
    void (^usernameExistsBlock)() = ^(){
        YoContact *member = [YoContact new];
        member.username = username;
        member.userType = YoUserTypeRegular;
        [self addGroupMember:member];
        self.textField.text = @"";
        [self.tableView reloadData];
        [self.textField resignFirstResponder];
    };
    
    [[YoAPIClient new] POST:@"rpc/user_exists" parameters:@{@"username":username}
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NS_DURING
                        if (![[responseObject valueForKey:@"exists"] boolValue]) {
                            usernameDoesNotExistBlock();
                            return;
                        }
                        usernameExistsBlock();
                        NS_HANDLER
                        usernameExistsBlock();
                        NS_ENDHANDLER
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        usernameExistsBlock();
                    }];
}

@end
