//
//  YOUsernamesPickerController.m
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YOUsernamesPickerController.h"

@interface YOUsernamesPickerController () <UITextFieldDelegate>

@end

@implementation YOUsernamesPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.allUsernames = nil;
    //self.selectedUsernames = [NSMutableArray array];
    //[self.tableView reloadData];
}

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath {
    return @"YOCell";
}

- (NSString *)topText {
    return NSLocalizedString(@"SELECT USERNAMES TO SHARE", nil);
}

- (NSString *)bottomText {
    return MakeString(@"%@!", NSLocalizedString(@"Share", nil));
}

//- (void)configureCell:(YOCell *)cell withIndexPath:(NSIndexPath *)indexPath {
//    cell.contentView.backgroundColor = [self.selectedUsernames containsObject:cell.label.text] ? [UIColor colorWithHexString:EMERALD] : [UIColor colorWithHexString:PETER];
//}

#pragma mark - UITableView

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    DDLogVerbose(@"%@",[@(self.allUsernames.count) stringValue]);
//    return 2 + self.allUsernames.count;
//}
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YOCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifierForIndexPath:indexPath]];
    if (cell == nil) {
        cell = LOAD_NIB([self cellIdentifierForIndexPath:indexPath]);
    }
    [self colorCell:cell withIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.label.text = [self topText];
    }
    else {
        [self configureCell:cell withIndexPath:indexPath];
    }
    return cell;
}
//
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (indexPath.row == 0) {
//            [self dismissViewControllerAnimated:YES completion:nil];
//            return;
//        }
//        else if (indexPath.row == [self.tableView numberOfRowsInSection:0] - 1) {
//            [[RavenClient sharedClient] captureMessage:[NSString stringWithFormat:@"%@ shared list (%lu)", [[YoUser me] username], (unsigned long)self.selectedUsernames.count] level:kRavenLogLevelDebugInfo];
//            [self dismissViewControllerAnimated:YES completion:^{
//                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Tap to add to your Yo: http://justyo.co/%@\n(if you don't have Yo app get it here %@)", nil), [self.selectedUsernames componentsJoinedByString:@"+"], DOWNLOAD_URL];
//                [[iOSAcct sharedInstance] openWhatsAppToShareText:message];
//            }];
//            return;
//        }
//        NSString *username = self.allUsernames[indexPath.row - 1];
//        if ([self.selectedUsernames containsObject:username]) {
//            [self.selectedUsernames removeObject:username];
//        }
//        else {
//            [self.selectedUsernames addObject:username];
//        }
//        [self.tableView reloadData];
//    });
//}

#pragma mark - Utilitly

- (BOOL)isNotSMSablePhoneLabel:(CFStringRef)label{
    NSString *labelAsString = (__bridge_transfer NSString *)label;
    static NSArray *badKeyWords;
    if (!badKeyWords) badKeyWords = @[@"FAX", @"Pager"];
    for (NSString *badKeyWord in badKeyWords) {
        if ([labelAsString rangeOfString:badKeyWord].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isPreferredPhoneLabel:(CFStringRef)label{
    NSString *labelAsString = (__bridge_transfer NSString *)label;
    static NSArray *keyWords;
    if (!keyWords) keyWords = @[@"Mobile", @"iPhone"];
    for (NSString *keyWord in keyWords) {
        if ([labelAsString rangeOfString:keyWord].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (void)obtainAddressBookPermissionWithCompletionBlock:(void (^)(BOOL success, ABAddressBookRef addressBook))block{
    CFErrorRef *error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    // First time access has been granted, add the contact
                    if (block) block(YES, addressBook);
                }
                else {
                    if (block)block(NO, addressBook);
                }
            });
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        block(YES, addressBook);
    }
    else {
        block(NO, addressBook);
    }
}

@end
