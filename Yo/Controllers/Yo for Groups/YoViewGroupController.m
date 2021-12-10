//
//  YoViewGroupController.m
//  Yo
//
//  Created by Or Arbel on 5/13/15.
//
//

#import "YoViewGroupController.h"
#import "YoAddGroupMemberCell.h"
#import "YoAddController.h"

enum {
    YoViewGroupSheetRemoveMember,
    YoViewGroupSheetLeaveGroup
};

enum {
    YoViewGroupSectionAdmins,
    YoViewGroupSectionMembers,
    YoViewGroupSectionCount
};

enum {
    YoViewGroupActionSheetSendYo,
    YoViewGroupActionSheetSendYoLocation,
    YoViewGroupActionSheetRemove
};

@interface YoViewGroupController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UITextFieldDelegate>
@property(nonatomic, strong) YoUser *selectedMember;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@property (nonatomic, strong) IBOutlet YOTextField *groupNameTextField;
@property (nonatomic, strong) IBOutlet UIView *blurView;

@property (nonatomic, strong) IBOutlet UIButton *muteButton;
@end

static void* YoContext = &YoContext;

@implementation YoViewGroupController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.leaveButton setTitle:NSLocalizedString(@"leave", nil).capitalizedString forState:UIControlStateNormal];
    [self.addButton setTitle:NSLocalizedString(@"add", nil).capitalizedString forState:UIControlStateNormal];
    
    //self.groupNameTextField.backgroundColor = [UIColor clearColor];
    self.groupNameTextField.delegate = self;
    
    __weak YoViewGroupController *weakSelf = self;
    [[YoApp currentSession] getGroupWithUsername:self.group.username
                               completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                   if (result == YoResultSuccess) {
                                       NSMutableArray *admins = [NSMutableArray array];
                                       NSArray *rawAdmins = [responseObject objectForKey:@"admins"];
                                       for (NSDictionary *rawAdmin in rawAdmins) {
                                           YoUser *admin = [YoUser objectFromDictionary:rawAdmin];
                                           [admins addObject:admin];
                                       }
                                       weakSelf.group.admins = [admins mutableCopy];
                                       
                                       NSMutableArray *members = [NSMutableArray array];
                                       NSArray *rawMembers = [responseObject objectForKey:@"members"];
                                       for (NSDictionary *rawMember in rawMembers) {
                                           YoUser *user = [YoUser objectFromDictionary:rawMember];
                                           [members addObject:user];
                                       }
                                       weakSelf.group.members = [members mutableCopy];
                                       
                                       weakSelf.groupNameTextField.userInteractionEnabled = [self.group.admins containsObject:[YoUser me]];
                                       [weakSelf.tableView reloadData];
                                   }
                                   else {
                                       [weakSelf closeWithCompletionBlock:^{
                                           YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Failed" desciption:@"Try again later?"];
                                           [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
                                           [[YoAlertManager sharedInstance] showAlert:alert];
                                       }];
                                   }
                                   
                               }];
    
    self.groupNameTextField.text = self.group.name;
    self.muteButton.selected = self.group.isMuted;
    
    [self.group addObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation)) options:NSKeyValueObservingOptionNew context:YoContext];
}

- (void)dealloc {
    NS_DURING
    [self.group removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
    NS_HANDLER
    NS_ENDHANDLER
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.tableView reloadData]; // @or: in case users are added we want to show them when coming back from add members controller
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.groupNameTextField resignFirstResponder];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (IBAction)toggleMute:(id)sender {
    if (self.muteButton.selected) {
        self.muteButton.selected = NO;
        self.group.isMuted = NO;
        [[YoApp currentSession] unmuteObject:self.group completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
            if (result == YoResultFailed) {
                DDLogError(@"%@", responseObject);
                if (result != YoResultSuccess) {
                    self.group.isMuted = YES;
                }
            }
        }];
    }
    else {
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Mute for 8 hours?"
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Mute", nil];
        as.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex){
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [[YoApp currentSession] muteObject:self.group completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                    if (result == YoResultSuccess) {
                        self.muteButton.selected = YES;
                        self.group.isMuted = YES;
                    }
                    else {
                        DDLogError(@"%@", responseObject);
                    }
                }];
            }
        };
        [as showInView:self.view];
    }
}

#pragma marl - Setters

- (void)setGroup:(YoGroup *)group {
    _group = group;
    [self groupDidChange];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isEqual:self.group]) {
        [self groupDidChange];
    }
}

#pragma mark - Internal

- (void)groupDidChange {
    self.muteButton.selected = self.group.isMuted;
}

- (void)closeWithCompletionBlock:(void (^)())block {
    __weak YoViewGroupController *weakSelf = self;
    if (self.groupNameTextField.text.length &&
        ![self.groupNameTextField.text isEqualToString:self.group.name])
    {
        [[YoApp currentSession] updateGroup:self.group
                          updatedProperties:@{@"name": self.groupNameTextField.text}
                          completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                              [weakSelf.group updateWithDictionary:responseObject];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationListChanged object:nil];
                          }];
    }
    [super closeWithCompletionBlock:block];
}

#pragma mark - Gestures

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    if (!CGRectContainsPoint(self.containerView.frame, touchPoint)) {
        [self closeWithCompletionBlock:nil];
    }
}

#pragma mark - Actions

- (IBAction)didTapCloseButton:(UIButton *)sender {
    [self closeWithCompletionBlock:nil];
}

- (IBAction)addMemberButtonPressed:(id)sender {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    YoAddController *addMembersVC = [mainStoryBoard instantiateViewControllerWithIdentifier:YoAddControllerID];
    addMembersVC.group = self.group;
    addMembersVC.mode = YoAddControllerAddToGroup;
    [self.navigationController pushViewController:addMembersVC animated:YES];
}

- (IBAction)leaveGroupButtonPressed:(id)sender {
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:MakeString(@"%@", self.group.name)
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"Leave Group"
                                              otherButtonTitles:nil];
    sheet.tag = YoViewGroupSheetLeaveGroup;
    [sheet showInView:self.view];
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 69.0f;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return YoViewGroupSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == YoViewGroupSectionAdmins) {
        return self.group.admins.count;
    }
    else if (section == YoViewGroupSectionMembers) {
        return self.group.members.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YoAddGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YoAddGroupMemberCell"];
    if ( ! cell) {
        cell = LOAD_NIB(@"YoAddGroupMemberCell");
        cell.removeButtonImageView.hidden = YES;
    }
    
    YoUser *member = indexPath.section == YoViewGroupSectionAdmins ? self.group.admins[indexPath.row] : self.group.members[indexPath.row];
    cell.nameLabel.text = member.displayName;
    if (indexPath.section == YoViewGroupSectionAdmins) {
        //cell.adminLabel.text = NSLocalizedString(@"admin", nil).capitalizedString;
        cell.showAdminLabel = YES;
    }
    //cell.adminLabel.hidden = indexPath.section == YoViewGroupSectionMembers;
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:member.photoURL
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    
    [cell.profileImageView setImageWithURLRequest:imageRequest
                                 placeholderImage:[UIImage imageNamed:@"new_action_profileedit"]
                                          success:nil
                                          failure:nil];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.groupNameTextField resignFirstResponder];
    
    self.selectedMember = indexPath.section == YoViewGroupSectionAdmins ? self.group.admins[indexPath.row] : self.group.members[indexPath.row];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:MakeString(@"%@", self.selectedMember.displayName)
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send Yo", @"Send Yo 📍", nil];
    
    if ([self.group.admins containsObject:[YoUser me]]) {
        [sheet addButtonWithTitle:@"Remove"];
    }
    sheet.tag = YoViewGroupSheetRemoveMember;
    [sheet showInView:self.view];
}

#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    if (actionSheet.tag == YoViewGroupSheetLeaveGroup) {
        __weak YoViewGroupController *weakSelf = self;
        [[YoApp currentSession] leaveGroupWithUsername:self.group.username
                                     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                         if (result == YoResultSuccess) {
                                             [[[YoUser me] contactsManager] removeObject:self.group localObjectOnly:YES withCompletionBlock:nil];
                                             [weakSelf closeWithCompletionBlock:nil];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationListChanged object:self.group];
                                         }
                                         else {
                                             YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Failed" desciption:@"Try again later?"];
                                             [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
                                             [[YoAlertManager sharedInstance] showAlert:alert];
                                         }
                                         
                                     }];
    }
    else if (actionSheet.tag == YoViewGroupSheetRemoveMember) {
        
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]) {
            [self removeUser:self.selectedMember]; // @or: not the best way to use a string because of translation. maybe fix later.
            return;
        }
        switch (buttonIndex) {
            case YoViewGroupActionSheetSendYo: {
                [[YoManager sharedInstance] yo:self.selectedMember.username
                             completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                 
                             }];
            }
                break;
            case YoViewGroupActionSheetSendYoLocation: {
                [[YoManager sharedInstance] yo:self.selectedMember.username
                           withCurrentLocation:YES
                             completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                 
                             }];
            }
                break;
        }
    }
}

- (void)removeUser:(YoUser *)user {
    NSString *description = MakeString(@"😩\nRemove %@\nfrom group\n( %@ )?",
                                       user.displayName,
                                       self.group.name);
    NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:description
                                                                                              attributes:[YoAlertManager sharedInstance].defaultDescriptionTextAttributes];
    NSDictionary *boldAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Bold" size:22]};
    NSDictionary *bigEmojiAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Bold" size:30]};
    [attributedDescription addAttributes:boldAttributes
                                   range:[attributedDescription.string
                                          rangeOfString:user.displayName]];
    [attributedDescription addAttributes:boldAttributes
                                   range:[attributedDescription.string
                                          rangeOfString:self.group.name]];
    [attributedDescription addAttributes:bigEmojiAttributes
                                   range:[attributedDescription.string
                                          rangeOfString:@"😩"]];
    
    YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"group edit", nil).capitalizedString
                               attributedDesciption:attributedDescription];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"remove", nil).capitalizedString tapBlock:^{
        [[YoApp currentSession] removeFromGroup:self.group
                             memberWithUsername:self.selectedMember.username
                              completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
         {
             if (result == YoResultSuccess) {
                 [self.group.members removeObject:self.selectedMember];
                 [self.group.admins removeObject:self.selectedMember];
                 [self.tableView reloadData];
             }
             else {
                 [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed 😔"];
             }
         }];
    }]];
    [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"nah", nil).capitalizedString tapBlock:nil]];
    [[YoAlertManager sharedInstance] showAlert:alert];
}

#pragma mark - UITextField

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (!textField.text.length) {
        textField.text = self.group.name;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
