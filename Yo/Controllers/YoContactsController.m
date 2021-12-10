//
//  YoContactsController.m
//  Yo
//
//  Created by Or Arbel on 5/18/15.
//
//

#import "YoContactsController.h"
#import "YOFacebookManager.h"
#import "YoContactManager.h"
#import "YoAlertManager.h"
#import "YoUser.h"
#import "YoGroup.h"
#import "YoAddGroupMemberCell.h"
#import "YoApp.h"
#import "YoContact.h"
#import "YoPermissionsInstructionView.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface YoContactsController ()
@property (weak, nonatomic) YoPermissionsInstructionView *permissionsView;
@end

@implementation YoContactsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithHexString:AMETHYST];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.textField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    
    self.addressBook = [[RHAddressBook alloc] init];
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
        
        //request authorization
        [self.addressBook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self processContacts];
                }
                else {
                    [self addPermissionsBannerToTableViewAnimated:YES];
                }
            });
        }];
    }
    else {
        if ([self shouldShouldPermissionsBanner]) {
            [self addPermissionsBannerToTableViewAnimated:NO];
        }
        [self processContacts];;
    }
}

- (void)processContacts {
    NSMutableArray *allPhoneContactsAsYoContacts = [NSMutableArray array];
    NSMutableArray *allCombined = [NSMutableArray array];
    NSMutableDictionary *usernameToContact = [NSMutableDictionary dictionary];
    
    self.phoneNumberToContact = [NSMutableDictionary dictionary];
    
    NSArray *phoneContacts = [self.addressBook people];
    
    NSMutableArray *allPhoneNumbers = [NSMutableArray array];
    
    for (RHPerson *person in phoneContacts) {
        
        NSArray *phoneNumbers = (__bridge NSArray *)(ABMultiValueCopyArrayOfAllValues(person.phoneNumbers.multiValueRef));
        
        for (NSString *phone in phoneNumbers) {
            YoContact *member = [YoContact new];
            member.source = @"address_book_not_on_yo";
            if (person.firstName && person.lastName) {
                member.fullName = MakeString(@"%@ %@", person.firstName, person.lastName);
            }
            else if (person.firstName) {
                member.fullName = MakeString(@"%@", person.firstName);
            }
            else if (person.lastName) {
                member.fullName = MakeString(@"%@", person.lastName);
            }
            else {
                continue;
            }
            
            member.userType = @"pseudo_user";
            member.phoneNumber = phone;
            
            self.phoneNumberToContact[phone] = member;
            
            [allPhoneNumbers addObject:phone];
            [allPhoneContactsAsYoContacts addObject:member];
            [allCombined addObject:member];
            
        }
    }
    
    /*
     allPhoneNumbers = "All phone numbers from address book"
     allPhoneContactsAsYoContacts = "All your address book contacts as YoContact objects"
     allCombined = allPhoneContactsAsYoContacts
     */
    
    NSMutableArray *allYoFriendsAsYoContacts = [NSMutableArray array];
    NSArray *allYoContacts = [[YoUser me] list];
    for (YoModelObject *object in allYoContacts) {
        if ([object isKindOfClass:[YoUser class]]) {
            YoUser *user = (YoUser *)object;
            if ( ! [user.objectType isEqualToString:@"pseudo_user"] && [user isPerson]) {
                
                YoContact *member = [YoContact new];
                [member fillWithUser:user];
                member.source = @"recent";
                
                [allYoFriendsAsYoContacts addObject:member];
                [allCombined addObject:member];
                [usernameToContact setObject:member forKey:user.username];
            }
        }
    }
    
    /*
     allYoFriendsAsYoContacts = "All the contacts on your list as YoContact objects"
     allCombined = allPhoneContactsAsYoContacts + allYoFriendsAsYoContacts
     usernameToContact = kayValuePairsFrom(allYoFriendsAsYoContacts)
     */
    
    
    
    self.allYoFriendsAsYoContacts = [[allYoFriendsAsYoContacts sortedArrayUsingDescriptors:[self sortDescriptors]] mutableCopy];
    self.allPhoneContactsAsYoContacts = [[allPhoneContactsAsYoContacts sortedArrayUsingDescriptors:[self sortDescriptors]] mutableCopy];
    self.allCombined = [[allCombined sortedArrayUsingDescriptors:[self sortDescriptors]] mutableCopy];
    self.usernameToContact = usernameToContact;
    
    [self.tableView reloadData];
    
    if (allPhoneNumbers.count < 2000) { // @or: for now i don't want to get the ui stuck for people with thousands of contacts. i've seen it happen.
        [[YoApp currentSession] findFriendsFromPhoneNumbers:allPhoneNumbers
                                            completionBlock:^(NSArray *friendDictionaries) {
                                                
                                                [self parseUserDictionaries:friendDictionaries source:@"address_book_on_yo"];
                                                [self fetchFacebookFriends];
                                                
                                            }];
    }
}

- (void)doFetchFacebookFriends {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me/friends?limit=5000"
                                  parameters:@{@"fields": @"id, name, email"}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSArray *data = result[@"data"];
        NSArray *ids = [data valueForKey:@"id"];
        
        if (ids) {
            [[YoApp currentSession] findFriendsFromFacebook:ids
                                            completionBlock:^(NSArray *friendDictionaries) {
                                                [self parseUserDictionaries:friendDictionaries source:@"facebook"];
                                            }];
        }
    }];
}

- (void)fetchFacebookFriends {
    
    if ([YOFacebookManager isLoggedIn]) {
        [self doFetchFacebookFriends];
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
        
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Facebook?"
                                                       text:@"Find friends from Facebook? (We never post on your wall)"
                                             yesButtonTitle:@"YASS"
                                              noButtonTitle:@"nah"
                                                   yesBlock:^{
                                                       
                                                       [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
                                                           if (isLoggedIn) {
                                                               
                                                               [[YoApp currentSession].yoAPIClient POST:@"rpc/link_facebook_account"
                                                                                             parameters:@{@"facebook_token":[[YOFacebookManager sharedInstance] accessToken]}
                                                                                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                                    DDLogDebug(@"linked");
                                                                                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                                    DDLogDebug(@"error linking");
                                                                                                }];
                                                               
                                                               
                                                               [self doFetchFacebookFriends];
                                                           }
                                                       }];
                                                   }];
    }
}

- (void)parseUserDictionaries:(NSArray *)dictionaries source:(NSString *)source {
    if (dictionaries.count > 0) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            @synchronized(self) {
                
                NSMutableArray *contactMatchesFromServer = [NSMutableArray array];
                
                for (NSDictionary *contactDictionary in dictionaries) {
                    YoContact *contact = [YoContact new];
                    [contact fillWithDictionary:contactDictionary];
                    contact.source = source;
                    
                    
                    if (self.phoneNumberToContact[contact.phoneNumber]) {
                        YoContact *existing = [self.phoneNumberToContact objectForKey:contact.phoneNumber];
                        if (existing.username.length == 0) {
                            [self.allCombined removeObject:existing];
                        }
                        contact.fullName = existing.fullName;
                        //contact.lastSeenDate = existing.lastSeenDate;
                        self.usernameToContact[contact.username] = contact;
                        [contactMatchesFromServer addObject:contact];
                    }
                    else if ([self.usernameToContact objectForKey:contact.username]) {
                        YoContact *existing = [self.usernameToContact objectForKey:contact.username];
                        existing.phoneNumber = contact.phoneNumber;
                        existing.fullName = contact.fullName;
                        existing.source = source;
                        existing.yoCount = contact.yoCount;
                        existing.lastSeenDate = contact.lastSeenDate;
                    }
                    else {
                        self.usernameToContact[contact.username] = contact;
                        [contactMatchesFromServer addObject:contact];
                    }
                    
                }
                
                [self.allCombined addObjectsFromArray:contactMatchesFromServer];
                // Peter: Becuase of this ^ lets not sort allYoFriendsAsYoContacts
                // until after this point
                
                NSMutableArray *unique = [NSMutableArray array];
                for (id obj in [self.allCombined copy]) {
                    if (! [unique containsObject:obj]) {
                        [unique addObject:obj];
                    }
                }
                
                self.allCombined = [[unique sortedArrayUsingDescriptors:[self sortDescriptors]] mutableCopy];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
}

- (NSArray *)sortDescriptors {
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"fullName"
                                                                    ascending:YES
                                                                   comparator:^NSComparisonResult(id obj1, id obj2) {
                                                                       return [obj1 caseInsensitiveCompare:obj2];
                                                                   }];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"username"
                                                                    ascending:YES
                                                                   comparator:^NSComparisonResult(id obj1, id obj2) {
                                                                       return [obj1 caseInsensitiveCompare:obj2];
                                                                   }];
    return @[sortDescriptor1, sortDescriptor2];
}


#pragma mark - Permissions Banner

- (void)addPermissionsBannerToTableViewAnimated:(BOOL)animated {
    [self.tableView reloadData];
}

- (YoPermissionsInstructionView *)permissionsView {
    if (!_permissionsView) {
        YoPermissionsInstructionView *permissionsView = LOAD_NIB(@"YoPermissionsInstructionView");
        permissionsView.instructionImageView.image = [UIImage imageNamed:YoInstructionImageContacts];
        BOOL canOpenYoAppSettings = NO;
        if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
            canOpenYoAppSettings = YES;
        }
        NSString *instructionsText = @"Yo all your friends by allowing Yo access to your contacts in the Settings App.";
        if (canOpenYoAppSettings) {
            [permissionsView.actionButton setTitle:NSLocalizedString(@"Tap to Open Settings", nil)
                                          forState:UIControlStateNormal];
            [permissionsView.actionButton addTarget:self action:@selector(didTapPermissionsBanner:)
                                   forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            [permissionsView.actionButton removeFromSuperview];
        }
        permissionsView.textLabel.text = instructionsText;
        // Compute Height based on Subviews
        permissionsView.width = CGRectGetWidth([[UIScreen mainScreen] bounds]); // intended tableview width;
        [permissionsView updateHeightToFitSubviews];
        _permissionsView = permissionsView;
    }
    return _permissionsView;
}

- (void)didTapPermissionsBanner:(id)sender {
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else {
        DDLogWarn(@"Error: Attempted to open settings when opening settings is unavailble");
    }
}

- (BOOL)shouldShouldPermissionsBanner {
    BOOL shouldDisplayPermissionsBanner = NO;
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusDenied ||
        [RHAddressBook authorizationStatus] == RHAuthorizationStatusRestricted) {
        shouldDisplayPermissionsBanner = YES;
    }
    return shouldDisplayPermissionsBanner;
}

#pragma mark - UITextField

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *text = [NSString stringWithString:textField.text];
    
    self.filteredCombined = [NSMutableArray array];
    
    for (YoContact *potentialMember in self.allCombined) {
        if (potentialMember.fullName && [potentialMember.fullName rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.filteredCombined addObject:potentialMember];
        }
        else if (potentialMember.username && [potentialMember.username rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.filteredCombined addObject:potentialMember];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.textField resignFirstResponder];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 &&
        [self shouldShouldPermissionsBanner]) {
        return self.permissionsView.height;
    }
    else {
        return 0.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 &&
        [self shouldShouldPermissionsBanner]) {
        return self.permissionsView;
    }
    else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.textField.text.length == 0) {
        return self.allCombined.count;
    }
    else {
        return self.filteredCombined.count + 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // @or: to be implemented in subclass
    return nil;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
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

@end
