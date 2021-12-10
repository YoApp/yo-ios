//
//  YoContact.h
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import <Foundation/Foundation.h>

// @or: a YoContact can be either a Yo user or just a phone contact
// this class is used to present the list in add friends and add group members

@interface YoContact : NSObject

extern NSString *const YoUserTypeRegular;
extern NSString *const YoUserTypePseudo;

@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *userType; // @or: "user" or "pseudo_user"
@property (nonatomic, strong) NSString *source;
@property (nonatomic, assign) NSInteger yoCount;
@property (nonatomic, strong) NSDate *lastSeenDate;


- (void)fillWithUser:(YoUser *)user;
- (void)fillWithDictionary:(NSDictionary *)contactDictionary;

@end
