//
//  YoContactDataSource.h
//  Yo
//
//  Created by Peter Reveles on 11/26/14.
//
//

#import "YoSearchObject.h"
@class YoUser;

typedef NS_ENUM(NSUInteger, YoContactFilter) {
    YoContactFilter_byUsername,
    YoContactFilter_byFullName,
    YoContactFilter_byPhoneNumber,
    YoContactFilter_byFbid,
};

@interface YoContacts : YoSearchObject

- (instancetype)init;

- (NSArray *)allContacts;
- (NSArray *)filteredcontacts;

- (void)addContact:(YoUser *)contact;

- (void)removeContact:(YoUser *)contact;

/** defaults to fullname */
@property(nonatomic, assign) YoContactFilter filterBy;

@end
