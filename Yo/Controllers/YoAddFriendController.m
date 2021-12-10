//
//  AddFriendController.m
//  Yo
//
//  Created by Or Arbel on 5/18/15.
//
//

#import "YoAddFriendController.h"
#import "YoThemeManager.h"
#import "YOCell.h"
#import "YoCreateGroupController.h"
#import "YoLabel.h"
#import "YoContact.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface YoAddFriendController () <UITextFieldDelegate, UIScrollViewDelegate>
@end

@implementation YoAddFriendController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textField.layer.cornerRadius = 5;
    self.textField.layer.masksToBounds = YES;
    self.textField.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.textField.tintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.headerView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    YoLabel *label = [[YoLabel alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Yo";//[self.currentContextObject textForTitleBar];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Montserrat-Bold" size:17];
    self.navigationItem.titleView = label;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"Add by username" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:12];
    [button setBackgroundColor:[UIColor colorWithHexString:BELIZE]];
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 3.0f;
    [button addTarget:self action:@selector(addByUsernameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 120, 30);
    
    UIBarButtonItem *fixedWidth = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidth.width = 30.0;
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:button], fixedWidth];
    
    self.tableView.separatorColor = [UIColor colorWithHexString:@"8842A8"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.navigationController.view.layer.cornerRadius = 0.0;
    self.view.layer.cornerRadius = 0.0;
}

- (IBAction)addByUsernameButtonPressed:(id)sender {
    [self.textField resignFirstResponder];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add username"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Add", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    NSString *username = [alertView textFieldAtIndex:0].text;
    void (^usernameDoesNotExistBlock)() = ^(){
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Yo" text:MakeString(NSLocalizedString(@"%@ does not exist", @"{username} does not exist"), username)];
    };
    
    void (^usernameExistsBlock)() = ^(){
        YoUser *user = [YoUser new];
        user.username = username;
        [[[YoUser me] contactsManager] promoteObjectToTop:user];
        
        [self closeWithCompletionBlock:^{
            [[YoAlertManager sharedInstance] showAlertWithTitle:@"Yo"
                                                           text:MakeString(@"%@ has been added to your recents list. Tap their name to Yo them!", username)];
        }];
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
    
    /*YoContact *contact = [YoContact new];
     contact.username = username;
     [self.allCombined insertObject:contact atIndex:0];
     [self.tableView reloadData];
     
     YOCell *cell = (YOCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
     [self sendYoToUserForCell:cell withContact:contact];*/
}

- (IBAction)startGroupButtonPressed:(id)sender {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    YoCreateGroupController *createGroupVC = [mainStoryBoard instantiateViewControllerWithIdentifier:YoCreateGroupControllerID];
    [self.navigationController pushViewController:createGroupVC animated:YES];
}

- (void)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITableView
/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 if (self.allCombined.count == 0 && self.filteredCombined.count == 0) {
 return @[];
 }
 NSArray *arrIndexes = [NSArray arrayWithArray:
 [@"A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
 componentsSeparatedByString:@","]];
 return arrIndexes;
 }
 
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 NSArray *contactsArray = nil;
 if (self.textField.text.length == 0) {
 contactsArray = self.allCombined;
 }
 else {
 contactsArray = self.filteredCombined;
 }
 
 NSInteger newRow = [self indexForFirstChar:title inArray:contactsArray];
 NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
 [tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
 
 return index;
 }
 
 - (NSInteger)indexForFirstChar:(NSString *)character inArray:(NSArray *)array {
 NSUInteger count = 0;
 for (YoContact *contact in array) {
 if ([contact.username hasPrefix:character] || [contact.fullName hasPrefix:character]) {
 return count;
 }
 count++;
 }
 return 0;
 }
 */

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
    
    if (contact.username.length > 0) {
        cell.statusLabel.text = MakeString(@"%@ (from %@)", contact.username, contact.source);
    }
    else if (contact.phoneNumber.length > 0) {
        cell.statusLabel.text = contact.phoneNumber;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YoContact *contact = nil;
    
    if (self.textField.text.length == 0) {
        contact = self.allCombined[indexPath.row];
    }
    else {
        contact = self.filteredCombined[indexPath.row];
    }
    
    if ([contact.userType isEqualToString:@"pseudo_user"]) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Invite to Yo?"
                                               desciption:[NSString stringWithFormat:@"%@ is not on Yo. do you want to invite with a text?", contact.fullName]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Nah", nil)
                                     tapBlock:^{
                                         
                                     }]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:@"Yes"
                                     tapBlock:^{
                                         NSString *text = MakeString(@"Yo from %@.\n\nget the Yo app it's cool", [YoUser me].displayName);
                                         NSString *number = MakeString(@"%@", contact.phoneNumber);
                                         [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:@[number]
                                                                                                        text:text
                                                                                                 resultBlock:^(MessageComposeResult result) {
                                                                                                 }];
                                     }]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
        return;
    }
    
    
    YOCell *cell = (YOCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self sendYoToUserForCell:cell withContact:contact];
    
}

- (void)sendYoToUserForCell:(YOCell *)cell withContact:(YoContact *)contact {
    
    if ( ! [APPDELEGATE hasInternet]) {
        // TODO show no internet
    }
    
    NSString *textOnCell = cell.label.text;
    
    [cell startActivityIndicator];
    cell.userInteractionEnabled = NO;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (contact.fullName.length > 0) {
        parameters[@"name"] = contact.fullName;
    }
    if (contact.username.length > 0) {
        parameters[@"username"] = contact.username;
    }
    if (contact.phoneNumber.length > 0) {
        parameters[@"phone_number"] = contact.phoneNumber;
    }
    if (contact.userType.length > 0) {
        parameters[@"user_type"] = contact.userType;
        parameters[@"is_pseudo"] = @([contact.userType isEqualToString:@"pseudo_user"]);
    }
    if (contact.source.length > 0) {
        parameters[@"source"] = contact.source;
    }
    
    [[YoManager sharedInstance] sendYoWithParams:parameters
                               completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                   [cell endActivityIndicator];
                                   cell.userInteractionEnabled = YES;
                                   
                                   if (result == YoResultSuccess) {
                                       
                                       YoUser *user = [YoUser new];
                                       [user updateWithDictionary:responseObject[@"recipient"]];
                                       [[[YoUser me] contactsManager] promoteObjectToTop:user];
                                       
                                       [cell flashText:@"Sent Yo and added to recents" completionBlock:^{
                                           
                                           cell.label.text = textOnCell;
                                           
                                       }];
                                   }
                                   else {
                                       [cell flashText:@"Failed Yo 😔" completionBlock:^{
                                           
                                           cell.label.text = textOnCell;
                                           
                                       }];
                                   }
                               }];
    
    /*[self.currentContextObject prepareContextParametersWithCompletionBlock:^(NSDictionary *contextParameters) {
     if ( ! contextParameters) {
     [cell endActivityIndicator];
     cell.userInteractionEnabled = YES;
     [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed 😔"];
     return;
     }
     
     [parameters addEntriesFromDictionary:contextParameters];
     
     [[YoManager sharedInstance] sendYoWithParams:parameters
     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
     
     [cell endActivityIndicator];
     cell.userInteractionEnabled = YES;
     
     if (result == YoResultSuccess) {
     
     YoUser *user = [YoUser new];
     [user fillObjectFromDictionary:responseObject[@"recipient"]];
     [[[YoUser me] contactsManager] promoteObjectToTop:user];
     
     [cell flashText:[self.currentContextObject textForSentYo] completionBlock:^{
     
     cell.label.text = textOnCell;
     
     }];
     }
     else {
     [cell flashText:@"Failed Yo 😔" completionBlock:^{
     
     cell.label.text = textOnCell;
     
     }];
     }
     }];
     }];*/
}

@end
