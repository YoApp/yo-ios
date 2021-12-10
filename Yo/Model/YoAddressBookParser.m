//
//  YoAddressBookParser.m
//  Yo
//
//  Created by Peter Reveles on 12/29/14.
//
//

#import "YoAddressBookParser.h"
#import "YoContacts.h"

@implementation YoAddressBookParser

+ (void)iterateContactsInAddressBook:(ABAddressBookRef)addressbook iterartionBlock:(void (^)(NSString *name, NSString *phoneNumber))iterationBlock {
    NSArray *sources =  (__bridge NSArray *)ABAddressBookCopyArrayOfAllSources(addressbook);
    
    for (id obj in sources) {
        ABRecordRef source = (__bridge ABRecordRef)(obj);
        NSArray *allPeople = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressbook, source, kABPersonSortByFirstName);
        
        for(int i = 0; i < [allPeople count]; i++) {
            NS_DURING
            ABRecordRef person = (__bridge ABRecordRef)(allPeople[i]);
            
            NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
            
            NSString *name = MakeString(@"%@", [firstName length] ? firstName : @"");
            if ([lastName length]) name = [name stringByAppendingString:MakeString(@"%@%@", [firstName length] ? @" ":@"", lastName)];
            
            if (![name length]) {
                NSString *organization = (__bridge NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
                
                if ([organization length])
                    name = organization;
                else
                    continue; // peter: user wont be able to dicern who this is, so skip it + it looks bad in tableView
            }
            
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
            
            for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
                NS_DURING
                NSString *phoneNumber = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
                
                if (phoneNumber.length < 2) {
                    continue;
                }
                
                CFStringRef numberTypeLabel = ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
                
                if ([YoAddressBookParser isNotSMSablePhoneLabel:numberTypeLabel]) continue;
                
                // contacts data source
                if (iterationBlock) iterationBlock(name, phoneNumber);
                
                NS_HANDLER
                continue;
                NS_ENDHANDLER
            }
            
            NS_HANDLER
            NS_ENDHANDLER
            
        }
    }
}

+ (YoContacts *)extractContactsFromAddressBook:(ABAddressBookRef)addressBook {
    YoContacts *contacts = [YoContacts new];
    [self iterateContactsInAddressBook:addressBook iterartionBlock:^(NSString *name, NSString *phoneNumber) {
        YoUser *contact = [YoUser new];
        contact.phoneNumber = phoneNumber;
        contact.fullName = name;
        [contacts addContact:contact];
    }];
    return contacts;
}

+ (void)obtainAddressBookWithCompletionBlock:(void (^)(YoAddressBookPermission permission, ABAddressBookRef addressBook))block{
    CFErrorRef *error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    
    if ([YoAddressBookParser permission] == YoAddressBookPermissionUnDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    // First time access has been granted, add the contact
                    if (block) block(YoAddressBookPermissionGranted, addressBook);
                }
                else {
                    if (block)block(YoAddressBookPermissionDenied, addressBook);
                }
            });
        });
    }
    else if ([YoAddressBookParser permission] == YoAddressBookPermissionGranted) {
        block(YoAddressBookPermissionGranted, addressBook);
    }
    else {
        block(YoAddressBookPermissionDenied, addressBook);
    }
}

+ (YoAddressBookPermission)permission{
    YoAddressBookPermission _permission;
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusNotDetermined:
            _permission = YoAddressBookPermissionUnDetermined;
            break;
            
        case kABAuthorizationStatusAuthorized:
            _permission = YoAddressBookPermissionGranted;
            break;
            
        case kABAuthorizationStatusDenied:
            _permission = YoAddressBookPermissionDenied;
            break;
            
        case kABAuthorizationStatusRestricted:
            _permission = YoAddressBookPermissionDenied;
            break;
    }
    return _permission;
}

#pragma mark - Internal

+ (BOOL)isNotSMSablePhoneLabel:(CFStringRef)label{
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

@end
