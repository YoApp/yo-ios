//
//  YoUser.h
//  Yo
//
//  Created by Peter Reveles on 1/6/15.
//
//

#import "YoManager.h"
#import "YoContactManager.h"
#import "YoModelObject.h"

@class YoAPIClient;
@class YoInbox;

// NS_AVAILABLE_IOS(6.0)

#define Yo_USER_KEY @"yo_user"
#define Yo_USERNAME_KEY @"username"
#define Yo_FULL_NAME_KEY @"name"
#define Yo_PHONE_NUMBER_KEY @"phone"
#define Yo_EMAIL_KEY @"email"
#define Yo_COUNTRY_CODE_KEY @"country_code"
#define Yo_IS_SERVICE_KEY @"is_subscribable"
#define Yo_NEEDS_LOCATION_KEY @"needs_location"
#define Yo_PHOTO_KEY @"photo"
#define Yo_USER_ID_KEY @"user_id"
#define Yo_BIO_KEY @"bio"
#define Yo_IS_VIP_KEY @"isVIP"
#define Yo_FB_ID_KEY @"fbid"
#define Yo_PROFILE_KEY @"profile"
#define Yo_HAS_VERIFIED_PHONE_NUMBER_KEY @"is_verified"
#define Yo_COUNT_KEY @"yo_count"
#define YoUserFirstNameKey @"first_name"
#define YoUserLastNameKey @"last_name"

// local only, these keys are not apart of remote user profile
#define Yo_HAS_UNSUBSCRIBED_FROM_A_SERVICE_KEY @"HAS_UNSCRIBED_TO_A_SERVICE"
#define Yo_HAS_YOD_IMAGE_KEY @"hasYodImage"
#define Yo_HAS_UNBLOCKED_A_USER_KEY @"has_unblocked_a_user_key"
#define Yo_HAS_BLOCKED_A_USER_KEY @"has_blocked_a_user_key"
#define Yo_HAS_CREATED_GROUP_KEY @"has_created_group"
#define Yo_HAS_OPENED_LOCATION_Yo_KEY @"has_openeded_location_yo_key"
#define Yo_HAS_RECEIVED_LOCATION_Yo_KEY @"has_received_location_yo_key"
#define Yo_HAS_BEEN_THROUGH_ONBOARDING @"has_been_through_onboarding"

#define YoUserHasBeenGrantedYoInbox @"YoUserHasBeenGrantedYoInbox"

@interface YoUser : YoModelObject

+ (YoUser *)me;

- (NSArray *)list;

#pragma mark - API

- (void)grantAPIUsageWithClient:(YoAPIClient *)yoAPIClient;

// if these are changed, setFilterBy method will need updating
#pragma mark Yo Info

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) NSString *photoURLString;
@property (nonatomic, assign) BOOL isService;
@property (nonatomic, assign) BOOL isSubscribable;
@property (nonatomic, assign) BOOL isAPIAccount;
@property (nonatomic, assign) BOOL isVIP;
@property (nonatomic, assign) BOOL hasVerifiedPhoneNumber;
@property (nonatomic, assign) BOOL hasYodImage;
@property (nonatomic, assign) BOOL hasUnSubscribedFromAService;
@property (nonatomic, assign) BOOL hasUnBlockedAnotherUser;
@property (nonatomic, assign) BOOL hasBlockedAnotherUser;
@property (nonatomic, assign) BOOL hasCreatedGroup;
@property (nonatomic, assign) BOOL hasOpendLocationYo;
@property (nonatomic, assign) BOOL hasBeenThroughOnboarding;
@property (nonatomic, assign) NSInteger yoCount;
@property (nonatomic, strong) NSString *fbid;
@property (nonatomic, strong) NSString *defaultContext;

@property (nonatomic, strong) NSString *centerPlusAction;
@property (nonatomic, strong) NSString *emptyListText;

#pragma mark - Contacts

@property (nonatomic, readonly) YoContactManager *contactsManager;

@property (nonatomic, readonly) YoInbox *yoInbox;

- (NSString *)yoCountString;

#pragma mark - External Utility

+ (BOOL)isValidUsername:(NSString *)username;
- (BOOL)isPerson;
- (BOOL)isEqualToUser:(YoUser *)otherUser;

@end
