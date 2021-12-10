//
//  YoConfigManager.h
//  Yo
//
//  Created by Peter Reveles on 12/18/14.
//
//

#import <Foundation/Foundation.h>
@class YoNotification;

@interface YoConfigManager : NSObject
@property (nonatomic, assign) YoLoadingStatus loadingStatus;

+ (instancetype)sharedInstance;

- (void)updateWithCompletionHandler:(void (^)(BOOL sucess))handler;

#pragma mark - Retreiving Data

- (NSString *)serverVersionNumber;

- (BOOL)isUpdateMandatory;

- (NSString *)releaseNotes;

- (NSURL *)onboardingURL;

- (CGFloat)indexVersion;

- (BOOL)shouldEnableFacebook;

- (double)yoDisplayTime;

- (BOOL)addContactShouldAlwaysOpenFindFriends;

- (BOOL)addContactShouldAlwaysPresentKeyboard;

- (NSInteger)getYoAnalayticsDesiredControllerHistoryCount;

- (NSString *)getWelcomeScreenTitle;

- (NSString *)getWelcomeScreenDescription;

- (NSArray *)getTitlesForWelcomeScreen;

#pragma mark - Strings

#pragma mark First On-Boarding
- (NSString *)onboardingSharePrompt;

- (NSString *)onBoardingIndexPrompt;

- (NSString *)onBoardingIndexTitle;

#pragma mark Second On-Boarding
- (NSString *)onBoardingCloseTheAppPrompt;

- (NSString *)onBoardingYoNeedsPushPrompt;

- (NSString *)onBoardingFirstYoPrompt;

- (BOOL)dontSendYoAfterOnBoarding;

- (double)timeBeforeSendingAfterOnBoardingYo;

- (double)timeForShowingStatus;

- (NSURL *)afterOnBoardingYoURL;

- (NSString *)afterOnBoardingYoPrompt;

- (NSString *)theme;

- (NSDictionary *)sampleContextConfiguration;

@end
