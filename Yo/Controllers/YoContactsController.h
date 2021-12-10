//
//  YoContactsController.h
//  Yo
//
//  Created by Or Arbel on 5/18/15.
//
//

#import <RHAddressBook/AddressBook.h>

#define YoContactsRemovedDuplicatedNotification @"YoContactsRemovedDuplicatedNotification"

enum {
    YoAddMembersSectionYoUsers,
    YoAddMembersSectionRegularContacts
};

@interface YoContactsController : YoBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@property (nonatomic, strong) RHAddressBook *addressBook;

@property (nonatomic, strong) NSMutableDictionary *usernameToContact;
@property (nonatomic, strong) NSMutableDictionary *phoneNumberToContact;

@property (nonatomic, strong) NSMutableArray *allCombined;
@property (nonatomic, strong) NSMutableArray *filteredCombined;

@property (nonatomic, strong) NSMutableArray *allPhoneContactsAsYoContacts;
@property (nonatomic, strong) NSMutableArray *allYoFriendsAsYoContacts;
@property (nonatomic, strong) NSMutableArray *filteredPhoneContactsAsYoContacts;
@property (nonatomic, strong) NSMutableArray *filteredYoFriendsAsYoContacts;

@end
