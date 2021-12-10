//
//  YOUsernamesPickerController.h
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YoBaseTableViewController.h"
#import <AddressBookUI/AddressBookUI.h>

@interface YOUsernamesPickerController : YoBaseTableViewController <UITableViewDataSource>

//@property(nonatomic, strong) NSMutableArray *allUsernames;
//@property(nonatomic, strong) NSMutableArray *selectedUsernames;

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (void)configureCell:(YOCell *)cell withIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Utilitly

- (BOOL)isNotSMSablePhoneLabel:(CFStringRef)label;

- (BOOL)isPreferredPhoneLabel:(CFStringRef)label;

- (void)obtainAddressBookPermissionWithCompletionBlock:(void (^)(BOOL success, ABAddressBookRef addressBook))block;

@end
