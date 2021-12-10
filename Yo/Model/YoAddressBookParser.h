//
//  YoAddressBookParser.h
//  Yo
//
//  Created by Peter Reveles on 12/29/14.
//
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
@class YoContacts;

typedef NS_ENUM(NSUInteger, YoAddressBookPermission) {
    YoAddressBookPermissionUnDetermined,
    YoAddressBookPermissionDenied,
    YoAddressBookPermissionGranted,
};

@interface YoAddressBookParser : NSObject

+ (void)obtainAddressBookWithCompletionBlock:(void (^)(YoAddressBookPermission permission, ABAddressBookRef addressBook))block;

+ (YoAddressBookPermission) permission;

+ (YoContacts *)extractContactsFromAddressBook:(ABAddressBookRef)addressBook;

+ (void)iterateContactsInAddressBook:(ABAddressBookRef)addressbook iterartionBlock:(void (^)(NSString *name, NSString *phoneNumber))iterationBlock;

@end
