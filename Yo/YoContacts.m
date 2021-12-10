//
//  YoContactDataSource.m
//  Yo
//
//  Created by Peter Reveles on 11/26/14.
//
//

#import "YoContacts.h"
#import "YoContactManager.h"
#import "YoUser.h"

@interface YoContacts ()
//@property (nonatomic, strong) NSMutableDictionary *contactForPhoneNumber;
//@property (nonatomic, strong) NSMutableDictionary *contactForUsername;
@end

@implementation YoContacts

- (instancetype)init{
    self = [super init];
    if (self) {
        // default behavior
        [self setFilterBy:YoContactFilter_byFullName];
    }
    return self;
}

//- (NSMutableDictionary *)contactForPhoneNumber{
//    if (!_contactForPhoneNumber) {
//        _contactForPhoneNumber = [NSMutableDictionary new];
//    }
//    return _contactForPhoneNumber;
//}
//
//- (NSMutableDictionary *)contactForUsername{
//    if (!_contactForUsername) {
//        _contactForUsername = [NSMutableDictionary new];
//    }
//    return _contactForUsername;
//}

- (NSArray *)allContacts{
    return self.originalData;
}
- (NSArray *)filteredcontacts{
    return self.filteredData;
}

- (void)addContact:(YoUser *)contact{
    if (!contact) return;
    if (![self.originalData containsObject:contact]) {
        NSArray *newData = [self.originalData arrayByAddingObject:contact];
        [self setData:newData];
//        if ([contact.phoneNumber length])
//            self.contactForPhoneNumber[contact.phoneNumber] = contact;
    }
}

- (void)removeContact:(YoUser *)contact{
    if (!contact) return;
    NSMutableArray *newData = [self.originalData mutableCopy];
    [newData removeObject:contact];
    [self setData:newData];
//    if ([contact.phoneNumber length])
//        [self.contactForPhoneNumber removeObjectForKey:contact.phoneNumber];
}

//- (YoContact *)contactWithPhoneNumber:(NSString *)phoneNumber{
//    return self.contactForPhoneNumber[phoneNumber];
//}
//
//- (YoContact *)contactWithUsername:(NSString *)username{
//    return self.contactForUsername[username];
//}

- (void)setFilterBy:(YoContactFilter)filterBy{
    switch (filterBy) {
        case YoContactFilter_byFbid:
            self.propertyToFilterBy = @"fbid";
            break;
            
        case YoContactFilter_byFullName:
            self.propertyToFilterBy = @"fullName";
            break;
            
        case YoContactFilter_byPhoneNumber:
            self.propertyToFilterBy = @"phoneNumber";
            break;
            
        case YoContactFilter_byUsername:
            self.propertyToFilterBy = @"username";
            break;
            
        default:
            self.propertyToFilterBy = @"fullName";
            break;
    }
    _filterBy = filterBy;
}

- (NSString *)description {
    return [self allContacts].description;
}

@end
