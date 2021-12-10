//
//  YoApp.h
//  Yo
//
//  Created by Peter Reveles on 1/13/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YoUser.h"
#import "YoGroup.h"
#import "YoNotificationManager.h"

#ifdef IS_BETA
#define Yo_GROUP_KEY @"group.com.orarbel.yo"
#else
#define Yo_GROUP_KEY @"group.com.yo"
#endif

#define Yo_INDEX_URL_STRING @"http://index.justyo.co"
#define Yo_INDEX_URL [NSURL URLWithString:Yo_INDEX_URL_STRING]
#define Yo_FEEDBACK_EMAIL_ADDRESS @"feedback@justyo.co"

#define kYoUserDidLoginNotification @"LoggedInNotification"
#define kYoUserDidSignupNotification @"UserDidSignupNotification"
#define kYoUserSessionRestoredNotification @"UserSessionRestoredNotification"
#define kYoUserLoginDidFailNotification @"LoginDidFailNotification"

#define YoAppDidUpdateUsersLocation @"YoAppDidUpdateUsersLocation"

@interface YoApp : NSObject

+ (instancetype)currentSession; // singlton instance

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) YoAPIClient *yoAPIClient;

#pragma mark - Device

- (void)grantAbilityToReceivePushNotificationsWithPushToken:(NSString *)pushToken;

@property (nonatomic, strong) NSString *possible_country_code;

+ (BOOL)isBeta;

@property (nonatomic, readonly) BOOL keyboardIsVisible;

+ (UIImage *)takeScreenShot NS_AVAILABLE_IOS(6_0) NS_EXTENSION_UNAVAILABLE("Not available in extension");

+ (NSString *)description;

#pragma mark - Yos

@property (nonatomic, readonly) YoNotificationManager *notificationManager;

#pragma mark - Find Friends

- (void)findFriendsFromPhoneNumbers:(NSArray *)numbers completionBlock:(void (^)(NSArray *friendDictionaries))block;

- (void)findFriendsFromFacebook:(NSArray *)friendIds completionBlock:(void (^)(NSArray *friendDictionaries))block;

#pragma mark - User

@property (nonatomic, readonly) NSString *lastKnownValidUsername;

@property(nonatomic, readonly) YoUser *user;

- (void)refreshUserProfileWithCompletionBlock:(void (^)(BOOL success))block; // will also resfresh Yo Count

- (void)changeUserProperties:(NSDictionary *)properties completionHandler:(YoResponseBlock)block;

- (void)uploadUserProfilePicture:(UIImage *)profilePicture completionHandler:(YoResponseBlock)block;

- (void)clearUserPhoneNumberValidation;

- (void)muteObject:(YoModelObject *)object completionHandler:(YoResponseBlock)block;

- (void)unmuteObject:(YoModelObject *)object completionHandler:(YoResponseBlock)block;

- (void)fetchEasterEggWithCompletionHandler:(YoResponseBlock)block;

- (void)fetchWebContextWithPath:(NSString *)path completionHandler:(YoResponseBlock)block;

- (NSInteger)openCountForUser:(NSString *)username;

#ifndef IS_APP_EXTENSION
#pragma mark - Phone Verification

- (void)getPhoneVerificationHashWithCompletionBlock:(void (^)(NSString *hash))block;

- (void)verifyUserPhoneNumberWithHash:(NSString *)hash
                      completionBlock:(void (^)(MessageComposeResult result))block;

- (void)requestVerificationCodeForNumber:(NSString *)phoneNumber
                     withCompletionBlock:(void (^)(BOOL didSend))block;

- (void)submitCode:(NSString *)code withCompletionBlock:(void (^)(BOOL didVerify))block;

#endif

#pragma mark - Groups 

- (void)createGroupWithName:(NSString *)groupName andMemberUsernames:(NSArray *)memberUsernames completionHandler:(YoResponseBlock)block;

- (void)getGroupWithUsername:(NSString *)groupUserame completionHandler:(YoResponseBlock)block;

- (void)updateGroup:(YoGroup *)group updatedProperties:(NSDictionary *)updatedProperties completionHandler:(YoResponseBlock)block;

- (void)leaveGroupWithUsername:(NSString *)groupUserame completionHandler:(YoResponseBlock)block;

- (void)addToGroup:(YoGroup *)group userObject:(YoUser *)object completionHandler:(YoResponseBlock)block;

- (void)addMembersToGroup:(YoGroup *)group multipleUserObjects:(NSArray *)userObjects completionHandler:(YoResponseBlock)block;
    
- (void)removeFromGroup:(YoGroup *)group memberWithUsername:(NSString *)userame completionHandler:(YoResponseBlock)block;

#pragma mark Location

@property (nonatomic, readonly) CLLocation *lastKnownLocation;

- (void)updateCurrentLocationWithCompletionBlock:(void (^)(BOOL success))block;

#pragma mark - Login & Signup

@property (nonatomic, readonly) BOOL isLoggedIn;

- (void)load;

- (void)signupWithUsername:(NSString *)username
                  passcode:(NSString *)passcode
               profileInfo:(NSDictionary *)profileInfo
         completionHandler:(YoResponseBlock)block;


- (void)loginWithUsername:(NSString *)username
                 passcode:(NSString *)passcode
        completionHandler:(YoResponseBlock)block;

- (void)loginWithFacebookCompletionBlock:(void (^)(BOOL success))block;

- (void)linkWithFacebookAccountCompletionBlock:(void (^)(BOOL success))block;

- (void)logout;

#pragma mark Recover

- (void)recoverPasscodeWithUserDetails:(NSDictionary *)userDetails completionHandler:(YoResponseBlock)block NS_EXTENSION_UNAVAILABLE("(void)recoverPass... unavialable in app extension") ;

@end
