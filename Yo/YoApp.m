//
//  YoApp.m
//  Yo
//
//  Created by Peter Reveles on 1/13/15.
//
//

#import "YoApp.h"
#import <SSKeychain/SSKeychain.h>
#import "TSTapstream.h"
#import <Social/Social.h>
#import "YoInbox.h"
#import "YoGroup.h"
#import "YoMainNavigationController.h"
#import "YoLocationManager.h"
#import "YoDataAccessManager.h"

#define Yo_PUSH_TOKEN_KEY @"push_token"
#define Yo_UDID_KEY @"udid"
#define Yo_DEVICE_TYPE_KEY @"device_type"
#define Yo_ACCESS_TOKEN_KEY @"tok"
#define Yo_PASSCODE_KEY @"password"
#define Yo_OPEN_COUNT_DIC_KEY @"open_count_dic"
#define Yo_OPEN_COUNT_KEY @"open_count"

#define YoFBAccessTokenKey @"facebook_token"

#ifndef IS_APP_EXTENSION
#import "YOFacebookManager.h"
#import "YoConfigManager.h"
#import "YoBannerNotificationPresentationManager.h"
#import "Yo.h"
#import "YoWebBrowserController.h"
#import "YoMapController.h"
#import "YoTwitterHandleManager.h"
#import "YoPopupAlertViewController.h"
#import "YOLocationManager.h"
#import "YoiOSAssistant.h"
#import "YoTipController.h"
#endif

@interface YoApp ()
@property(nonatomic, strong) YoUser *user;

@property (nonatomic, strong) CLLocation *lastKnownLocation;

@property (nonatomic, strong) NSDictionary *keyForProperty;

@property (nonatomic, strong) NSString *lastKnownValidUsername;

@property (nonatomic, strong) NSString *pushToken;

@property (nonatomic, assign) BOOL keyboardIsVisible;

- (NSString *)groupLastKnownValidUsername NS_AVAILABLE_IOS(7_0);
- (void)setGroupLastKnownValidUsername:(NSString *)groupLastKnownValidUsername NS_AVAILABLE_IOS(7_0);
- (void)userDidTakeScreenShot NS_EXTENSION_UNAVAILABLE("-(void)userDidTakeScreenShot unavailable in app extension");

@property (nonatomic, strong) YoNotificationManager *notificationManager;

@end

@implementation YoApp

@synthesize isLoggedIn = _isLoggedIn;

#pragma mark - Shared Data

- (BOOL)isLoggedIn {
    BOOL isLoggedIn = [self accessToken]?YES:NO;
    return isLoggedIn;
}

#pragma mark - Life Cycle

+ (instancetype)currentSession {
    
    static YoApp *_currentSession = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentSession = [[self alloc] init];
    });
    
    return _currentSession;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // setup
        [self setup];
#ifndef IS_APP_EXTENSION
        [self startListners];
#endif
    }
    return self;
}

- (void)setup{
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAlways];
}

#ifndef IS_APP_EXTENSION
- (void)startListners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidhideNotification:) name:UIKeyboardDidHideNotification object:nil];
    
    if (IS_OVER_IOS(7.0)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenShot) name:UIApplicationUserDidTakeScreenshotNotification
                                                   object:nil];
    }
    
    __weak YoApp *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:YoNotificaitonLocationServicesAuthorizied
                                                      object:[YoLocationManager sharedInstance]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
     {
         [weakSelf updateCurrentLocationWithCompletionBlock:nil];
     }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#endif

#ifndef IS_APP_EXTENSION
- (void)appDidBecomeActive {
    if ([self isLoggedIn]) {
        [APPDELEGATE registerForPushNotifications];
    }
}

- (void)appDidFinishLaunching {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        // if app was launched in background, do not start a session.
        //[self sessionStarted];
    }
}

- (void)appWillEnterForeground {
    [self updateOpenCount];
    [self loadCurrentUser];
}

- (void)appDidEnterBackground {
    if (self.isLoggedIn) {
        /* dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
         [[YoTwitterHandleManager sharedInstance] updateWithCompletionBlock:nil];
         });*/
    }
}

- (void)keyboardDidShowNotification:(NSNotification *)note {
    self.keyboardIsVisible = YES;
}

- (void)keyboardDidhideNotification:(NSNotification *)note {
    self.keyboardIsVisible = NO;
}

- (BOOL)canDisplayScreenShotSharePromptOn:(UIViewController *)vc {
    BOOL canDisplay = YES;
    if (self.keyboardIsVisible) {
        canDisplay = NO;
        return canDisplay;
    }
    NSArray *classesToNotDisplayOn = @[[UIActivityViewController class],
                                       [MFMailComposeViewController class],
                                       [MFMessageComposeViewController class]];
    for (Class class in classesToNotDisplayOn) {
        if ([vc isKindOfClass:class]) {
            canDisplay = NO;
            break;
        }
    }
    return canDisplay;
}

- (void)userDidTakeScreenShot {
    DDLogInfo(@"User took screen shot");
    
    UIImage *screenShot = [YoApp takeScreenShot];
    
    NSURL *yoMeURL = [NSURL URLWithString:MakeString(@"http://www.justyo.co/%@", self.user.username)];
    
    NSArray *sharingItems = @[yoMeURL, screenShot];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [APPDELEGATE.topVC presentViewController:activityController animated:YES completion:nil];
    
    /*if (self.isLoggedIn && [self canDisplayScreenShotSharePromptOn:[APPDELEGATE topVC]]) {
        UIImage *screenShot = [YoApp takeScreenShot];
        
        NSURL *yoMeURL = [NSURL URLWithString:MakeString(@"http://www.justyo.co/%@", self.user.username)];
        
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Share", nil) image:screenShot desciption:nil];
        
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Facebook", nil) tapBlock:^{
            [YOFacebookManager shareURL:[yoMeURL bitlyWraped] image:screenShot];
            [YoAnalytics logEvent:YoEventSharedScreenShot withParameters:@{YoParam_SHARE_OPTION:@"facebook"}];
        }]];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Twitter", nil) tapBlock:^{
            [[YoiOSAssistant sharedInstance] presentTweetSheetWithText:@"Yo" image:screenShot url:yoMeURL];
            [YoAnalytics logEvent:YoEventSharedScreenShot withParameters:@{YoParam_SHARE_OPTION:@"twitter"}];
        }]];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"More", nil) tapBlock:^{
            NSArray *sharingItems = @[yoMeURL, screenShot];
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
            [APPDELEGATE.topVC presentViewController:activityController animated:YES completion:nil];
            [YoAnalytics logEvent:YoEventSharedScreenShot withParameters:@{YoParam_SHARE_OPTION:@"more"}];
        }]];
        
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }*/
    
    [YoAnalytics logEvent:YoEventScreenShotTaken withParameters:nil];
}

+ (UIImage *)takeScreenShot {
    CGFloat width = CGRectGetWidth(APPDELEGATE.window.bounds);
    CGFloat height = CGRectGetHeight(APPDELEGATE.window.bounds);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    if (IS_OVER_IOS(7.0)) {
        [APPDELEGATE.topVC.view drawViewHierarchyInRect:CGRectMake(0.0f, 0.0f, width, height) afterScreenUpdates:YES];
    }
    else {
        [APPDELEGATE.topVC.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
#endif

#ifndef IS_APP_EXTENSION
- (void)updateOpenCount {
    [self incrementOpenCountForCurrentUser];
}
#endif

+ (NSString *)description {
    NSString *lastValidUsername = [[YoApp currentSession] lastKnownValidUsername];
    NSString *lastValidUsernameForGroup = @"";
    if (IS_OVER_IOS(7.0)) {
        lastValidUsernameForGroup = [[YoApp currentSession] groupLastKnownValidUsername];
    }
    
    NSString *lastUsernames = MakeString(@"Last Known Valid User \nMain_App Username: %@ \nApp_Extension Username: %@", lastValidUsername, lastValidUsernameForGroup);
    NSString *userOpenCount = MakeString(@"Open Count: %li", (long)[[YoApp currentSession] openCountForUser:lastValidUsername]);
    
    NSString *desrciption = MakeString(@"%@\n%@", lastUsernames, userOpenCount);
    
    return desrciption;
}

#pragma mark - Session Status

- (void)load{
    if (self.accessToken) {
        [self.yoAPIClient setAccessToken:self.accessToken];
        [YoDataAccessManager sharedDataManager].accessToken = self.accessToken;
        [self loadCurrentUser];
    }
    else {
        [self loginFailed];
    }
    
#ifndef IS_APP_EXTENSION
    
    [self sessionRestored];
    
    self.notificationManager = [YoNotificationManager new]; // this must always
    // be loaded immediately during launch so that notification work correctly
    // Yo Notificaiton manager is dependant on uiapplicationdidfinishlaunching.
#endif
}

- (void)loginFailed {
    [[NSNotificationCenter defaultCenter] postNotificationName:kYoUserLoginDidFailNotification object:self];
}

- (void)sessionRestored {
    
#ifndef IS_APP_EXTENSION
    [self updateOpenCount];
    [[YoConfigManager sharedInstance] updateWithCompletionHandler:^(BOOL sucess) {
        NSInteger openCount = [[YoApp currentSession] openCountForUser:self.user.username];
        if (openCount > 2) { // @or: more than 3 to support existing users with high open count. tip controller makes sure a tip only shows once.
            [YoTipController showTipIfNeeded:@"Pull down for profile settings 😝"];
        }
    }];
    
    [[YoABTestingFrameWork sharedInstance] loadWithCompletionBlock:nil];
    [[YoABTestingFrameWork sharedInstance] updateWithCompletionBlock:nil];
    [[YoActivityManager sharedInstance] startSession];
    [[YoActivityManager sharedInstance] setUsername:[YoUser me].username];
    
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        [self updateCurrentLocationWithCompletionBlock:nil];
    }
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kYoUserSessionRestoredNotification object:self];
}

- (void)userDidSignup {
    [[NSNotificationCenter defaultCenter] postNotificationName:kYoUserDidSignupNotification object:self];
}

- (void)userDidLogin {
    [[NSNotificationCenter defaultCenter] postNotificationName:kYoUserDidLoginNotification object:self];
}

- (void)loadCurrentUser {
    if (self.isLoggedIn) {
        if (self.user == nil) {
            self.user = [[YoUser alloc] init];
        }
        [self.user grantAPIUsageWithClient:self.yoAPIClient];
        self.user.username = self.lastKnownValidUsername;
    }
    else {
        self.user = nil;
    }
}

#ifndef IS_APP_EXTENSION
- (void)updateCurrentLocationWithCompletionBlock:(void (^)(BOOL success))block {
    void (^replyToBlock)(BOOL success) = ^(BOOL success) {
        if (block) {
            block(success);
        }
    };
    __weak YoApp *weakSelf = self;
    if ([[YoLocationManager sharedInstance] locationServicesDenied] == NO) {
        [[YoLocationManager sharedInstance] requestLocationWithDesiredAccuracy:YoLocationAccuracyBlock
                                                                       timeout:60.0
                                                               completionBlock:^(CLLocation *currentLocation, YoLocationAccuracy achievedAccuracy, YoLocationStatus status)
         {
             if (currentLocation) {
                 if (achievedAccuracy > YoLocationAccuracyNone) {
                     if (status == YoLocationStatusSuccess ||
                         status == YoLocationStatusTimedOut ||
                         status == YoLocationStatusError) {
                         weakSelf.lastKnownLocation = currentLocation;
                         [[NSNotificationCenter defaultCenter] postNotificationName:YoAppDidUpdateUsersLocation
                                                                             object:self];
                         replyToBlock(YES);
                         return;
                     }
                 }
             }
             
             replyToBlock(NO);
         }];
    }
    else {
        replyToBlock(NO);
    }
}
#endif

- (NSString *)lastKnownValidUsername {
#ifndef IS_APP_EXTENSION
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#else
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
#endif
    NSString *lastKnownValidUsername = [defaults objectForKey:Yo_USERNAME_KEY];
    return lastKnownValidUsername;
}

- (void)setLastKnownValidUsername:(NSString *)lastKnownValidUsername {
#ifndef IS_APP_EXTENSION
    [[NSUserDefaults standardUserDefaults] setObject:lastKnownValidUsername?:@""
                                              forKey:Yo_USERNAME_KEY];
#else
    DDLogWarn(@"Extension not allowed to write useranme to file");
#endif
}

#pragma mark - Access Token

@synthesize accessToken = _accessToken;

- (void)setAccessToken:(NSString *)accessToken {
    _accessToken = accessToken;
    [self.yoAPIClient setAccessToken:accessToken];
    [YoDataAccessManager sharedDataManager].accessToken = accessToken;
    [self.user grantAPIUsageWithClient:self.yoAPIClient];
    if (accessToken == nil) {
        [SSKeychain deletePasswordForService:@"yo" account:@"yo"];
    }
    else {
        NSError *error = nil;
        [SSKeychain setPassword:accessToken forService:@"yo" account:@"yo" error:&error];
        if (error) {
            DDLogError(@"%@", error);
        }
    }
}

- (NSString *)accessToken {
    NSError *error = nil;
    NSString *accessToken = [SSKeychain passwordForService:@"yo" account:@"yo" error:&error];
    if (error) {
        DDLogError(@"%@", error);
    }
    return accessToken;
}

#pragma mark - Push Token

- (void)setPushToken:(NSString *)pushToken {
    if (pushToken == nil) {
        return;
    }
    else {
        NSError *error = nil;
        [SSKeychain setPassword:pushToken forService:@"yo_push" account:@"yo" error:&error];
        if (error) {
            DDLogError(@"%@", error);
        }
    }
}

- (NSString *)pushToken {
    NSString *pushToken = [SSKeychain passwordForService:@"yo_push" account:@"yo"];
    return pushToken;
}

#pragma mark - Login & Signup

- (void)signupWithUsername:(NSString *)username
                  passcode:(NSString *)passcode
               profileInfo:(NSDictionary *)profileInfo
         completionHandler:(YoResponseBlock)block
{
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[Yo_USERNAME_KEY] = username;
    parameters[Yo_PASSCODE_KEY] = passcode;
    parameters[Yo_UDID_KEY] = [YOUDID value];
    parameters[Yo_DEVICE_TYPE_KEY] = @"ios";
    [parameters addEntriesFromDictionary:profileInfo];
    
    [self.yoAPIClient POST:@"rpc/sign_up"
                parameters:parameters
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       self.lastKnownValidUsername = username;
                       
                       NSString *accessToken = [responseObject objectForKey:Yo_ACCESS_TOKEN_KEY];
                       self.accessToken = accessToken;
                       
                       [self loadCurrentUser];
                       //[[NSNotificationCenter defaultCenter] postNotificationName:@"LoggedInNotification" object:nil]; // login is not signup? (not sure if this effects anything, it shouldnt)
                       
                       [self performSelectorInBackground:@selector(sendServerUDIDForCurrentUser) withObject:nil];
                       
                       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"updated_pass"]; //@avishay: so we won't ask user to update pass
                       [[NSUserDefaults standardUserDefaults] synchronize];
                       
                       // conversion tracking with Tap Stream
                       TSEvent *e = [TSEvent eventWithName:@"User created an account" oneTimeOnly:NO];
                       [[TSTapstream instance] fireEvent:e];
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, responseObject);
                       [self registerDeviceWithPushToken:self.pushToken];
                       
                       [self userDidSignup];
                       
                       [YoAnalytics logEvent:YoEventSuccesfullySignedUp withParameters:nil];
                       
                       NS_HANDLER
                       if (block) block(YoResultFailed, operation.response.statusCode, responseObject);
                       [self registerDeviceWithPushToken:self.pushToken];
                       NS_ENDHANDLER
                       
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to login");
                       
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)loginWithUsername:(NSString *)username
                 passcode:(NSString *)passcode
        completionHandler:(YoResponseBlock)block
{
    YoResponseBlock replyToBlock = ^(YoResult result, NSInteger statusCode, id responseObject)
    {
        if (block) {
            block(result, statusCode, responseObject);
        }
    };
    [self.yoAPIClient POST:@"rpc/login"
                parameters:@{Yo_USERNAME_KEY: username,
                             Yo_PASSCODE_KEY: passcode}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       NS_DURING
                       
                       self.lastKnownValidUsername = username;
                       
                       [self processUserLoginWithResponseObject:responseObject];
                       
                       replyToBlock(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       
                       NS_HANDLER
                       DDLogError(@"%@", localException);
                       replyToBlock(YoResultFailed, operation.response.statusCode, operation.responseObject);
                       [self registerDeviceWithPushToken:self.pushToken];
                       NS_ENDHANDLER
                       
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       
                       DDLogError(@"ERROR on Login: %@", error);
                       
                       BOOL usernameNotFound = (operation.response.statusCode == 404);
                       
                       if (usernameNotFound && [self.lastKnownValidUsername length] && [self.lastKnownValidUsername isEqualToString:username]) {
                           self.lastKnownValidUsername = nil;
                       }
                       
                       replyToBlock(YoResultFailed, operation.response.statusCode, operation.responseObject);
                       
                   }];
}

- (void)processUserLoginWithResponseObject:(id)responseObject {
    NSString *accessToken = [responseObject objectForKey:Yo_ACCESS_TOKEN_KEY];
    self.accessToken = accessToken;
    
    [self loadCurrentUser];
    
    [self.user updateWithDictionary:responseObject];
    
    [self performSelectorInBackground:@selector(sendServerUDIDForCurrentUser) withObject:nil];
#ifndef IS_APP_EXTENSION
    [APPDELEGATE registerForPushNotifications];
#endif
    
    [self registerDeviceWithPushToken:self.pushToken];
    
    [self userDidLogin];
}
#ifndef IS_APP_EXTENSION
- (void)loginWithFacebookCompletionBlock:(void (^)(BOOL success))block {
    void (^replyToBlock)(BOOL success) = ^(BOOL success){
        if (block) {
            block(success);
        }
    };
    
    [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
        NSString *FBAccessToken = [[YOFacebookManager sharedInstance] accessToken];
        if (FBAccessToken.length > 0) {
            [self loginWithFacebookAccessToken:FBAccessToken completionBlock:^(BOOL success) {
                replyToBlock(success);
            }];
        }
        else {
            replyToBlock(NO);
        }
    }];
}

- (void)linkWithFacebookAccountCompletionBlock:(void (^)(BOOL success))block {
    void (^replyToBlock)(BOOL success) = ^(BOOL success){
        if (block) {
            block(success);
        }
    };
    __weak YoApp *weakSelf = self;
    [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
        NSString *FBAccessToken = [[YOFacebookManager sharedInstance] accessToken];
        if (FBAccessToken.length > 0) {
            [weakSelf.yoAPIClient POST:@"rpc/link_facebook_account"
                            parameters:@{YoFBAccessTokenKey:FBAccessToken}
                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                   if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                       [self.user updateWithDictionary:responseObject];
                                   }
                                   replyToBlock(YES);
                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                   replyToBlock(NO);
                               }];
        }
        else {
            replyToBlock(NO);
        }
    }];
}

- (void)loginWithFacebookAccessToken:(NSString *)FBAccessToken completionBlock:(void (^)(BOOL success))block {
    void (^replyToBlock)(BOOL success) = ^(BOOL success){
        if (block) {
            block(success);
        }
    };
    if (FBAccessToken.length > 0) {
        [self.yoAPIClient POST:@"rpc/login_with_facebook_token"
                    parameters:@{YoFBAccessTokenKey:FBAccessToken}
                       success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NS_DURING
             [self processUserLoginWithResponseObject:responseObject];
             replyToBlock(YES);
             NS_HANDLER
             replyToBlock(NO);
             NS_ENDHANDLER
         } failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             replyToBlock(NO);
         }];
    }
}
#endif

#ifndef IS_APP_EXTENSION

- (void)logout {
    [self.yoAPIClient POST:@"rpc/logout" parameters:nil success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogWarn(@"Failed to logout with operation:\n%@ error:\n%@", operation, error);
    }];
    
    [self.user.yoInbox clearInbox];
    
    self.accessToken = nil;
    
    [self.user.contactsManager clearStoredData];
    
    self.user = nil;
    
    [[YoActivityManager sharedInstance] setUsername:nil];
    
    [[YOFacebookManager sharedInstance] logout];
    
    [self loginFailed];
}


- (void)recoverPasscodeWithUserDetails:(NSDictionary *)userDetails completionHandler:(YoResponseBlock)block NS_EXTENSION_UNAVAILABLE("(void)recoverPass... unavialable in app extension") {
    
    void (^presentRecoverThroughEmailController)() = ^void() {
        NSString *emailBody = NSLocalizedString(@"Just hit Send", nil);
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userDetails
                                                           options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                             error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [[YoiOSAssistant sharedInstance] presentEmailControllerWithRecipients:@[@"recover@justyo.co"]
                                                                      subject:@"Recover Password"
                                                                         body:[NSString stringWithFormat:@"%@.\n\nUsername: %@\n\n\n\n", emailBody, jsonString]
                                                                  resultBlock:^(MFMailComposeResult emailSent) {
                                                                      if (emailSent == MFMailComposeResultSent) {
                                                                          YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:MakeString(@"%@!", NSLocalizedString(@"Sent", nil))
                                                                                                                 desciption:NSLocalizedString(@"You'll receive a link to change your password shortly.", nil)];
                                                                          [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
                                                                          [[YoAlertManager sharedInstance] showAlert:yoAlert];
                                                                      }
                                                                  }];
    };
    
    void (^lastResort)() = ^void() {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Email Us", nil)
                                               desciption:NSLocalizedString(@"Please send us an email and we'll recover your account.", nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) tapBlock:nil]];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Send Email", nil) tapBlock:^{
            presentRecoverThroughEmailController();
        }]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    };
    
    [self.yoAPIClient POST:@"rpc/recover"
                parameters:userDetails
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       NSLog(@"Successfull Recovery: %@", responseObject);
                       
                       if (userDetails[@"username"]) {
                           self.lastKnownValidUsername = userDetails[@"username"];
                       }
                       
                       NSString *result = responseObject[@"result"];
                       if (result && result.length) {
                           NSString *cellSecureText = result;
                           NSString *meansOfContact = @"";
                           if ([result.lowercaseString rangeOfString:@"email"].location != NSNotFound) {
                               meansOfContact = @"Email";
                               cellSecureText = NSLocalizedString(@"EMAIL SENT", nil).lowercaseString.capitalizedString;
                           }
                           else if ([result.lowercaseString rangeOfString:@"text sent"].location != NSNotFound) {
                               meansOfContact = @"Text";
                               cellSecureText = NSLocalizedString(@"TEXT SENT", nil).lowercaseString.capitalizedString;
                           }
                           YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:[NSString stringWithFormat:@"%@!", cellSecureText.capitalizedString]
                                                                  desciption:NSLocalizedString(@"You'll receive a link to change your password shortly.", nil)];
                           [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
                           [[YoAlertManager sharedInstance] showAlert:yoAlert];
                       }
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed Recovery: %@", operation.responseObject);
                       
                       NS_DURING
                       
                       if (operation.response.statusCode == 404) {
                           // least desireable case: (user emails us because we dont have their info)
                           YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Email Us", nil)
                                                                  desciption:NSLocalizedString(@"We don't have a phone number or email listed for this account. Please send us an email and we'll recover your account.", nil)];
                           [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) tapBlock:nil]];
                           [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Send Email", nil) tapBlock:^{
                               presentRecoverThroughEmailController();
                           }]];
                           [[YoAlertManager sharedInstance] showAlert:yoAlert];
                       }
                       else
                           lastResort();
                       
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                       
                       NS_HANDLER
                       lastResort();
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }];
}
#endif

#pragma mark - Device

+ (BOOL)isBeta {
    BOOL isBeta = NO;
#ifdef IS_BETA
    isBeta = YES;
#endif
    return isBeta;
}

+ (BOOL)isDevelopment {
    BOOL isDevelopment = NO;
#ifdef IS_DEVELOPMENT
    isDevelopment = YES;
#endif
    return isDevelopment;
}

- (void)grantAbilityToReceivePushNotificationsWithPushToken:(NSString *)pushToken {
    self.pushToken = pushToken;
    [[YoApp currentSession] registerDeviceWithPushToken:pushToken];
}

- (void)registerDeviceWithPushToken:(NSString *)pushToken {
    if (![pushToken length]) {
        DDLogWarn(@"Cannot register device without pushtoken");
        return;
    }
    
    // beta
    NSString *deviceType = @"ios";
    if ([YoApp isDevelopment]) {
        deviceType = [deviceType stringByAppendingString:@"-development"];
    }
    else if ([YoApp isBeta]) {
        deviceType = [deviceType stringByAppendingString:@"-beta"];
    }
    
    [self.yoAPIClient POST:@"rpc/register_device"
                parameters:@{Yo_PUSH_TOKEN_KEY: pushToken,
                             Yo_DEVICE_TYPE_KEY: deviceType}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       DDLogWarn(@"SuccessFully registered device for push");
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"%@", error);
                   }];
}

//- (void)unRegisterDeviceWithPushToken:(NSString *)pushToken {
//    if (![pushToken length]) {
//        DDLogWarn(@"Cannot register device without pushtoken");
//        return;
//    }
//    [self.yoAPIClient POST:@"rpc/unregister_device"
//                parameters:@{Yo_PUSH_TOKEN_KEY: pushToken,
//                             Yo_DEVICE_TYPE_KEY: @"ios"}
//                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                       DDLogWarn(@"Successfully unregistered device for push by server");
//                   }
//                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                       DDLogError(@"%@", error);
//                   }];
//}

- (void)sendServerUDIDForCurrentUser {
    [self.yoAPIClient POST:@"rpc/set_me"
                parameters:@{Yo_UDID_KEY:[YOUDID value]}
                   success:nil
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       //
                       DDLogWarn(@"Failed to update UDID");
                   }];
}

- (void)setPossible_country_code:(NSString *)possible_country_code {
    possible_country_code = [possible_country_code stringByReplacingOccurrencesOfString:@" " withString:@""];
    possible_country_code = [possible_country_code stringByReplacingOccurrencesOfString:@"+" withString:@""];
    [[NSUserDefaults standardUserDefaults] setObject:possible_country_code forKey:Yo_COUNTRY_CODE_KEY];
}

- (NSString *)possible_country_code {
    NSString *possible_country_code = [[NSUserDefaults standardUserDefaults] objectForKey:Yo_COUNTRY_CODE_KEY];
    possible_country_code = [possible_country_code stringByReplacingOccurrencesOfString:@" " withString:@""];
    possible_country_code = [possible_country_code stringByReplacingOccurrencesOfString:@"+" withString:@""];
    return possible_country_code;
}

- (NSInteger)incrementOpenCountForCurrentUser {
    
    if ( ! self.user)
        return 0;
    
    NSString *currentUserUniqueIdentifier = self.user.username;
    
    if (![currentUserUniqueIdentifier length]) {
        return 0;
    }
    
    NSDictionary *openCountDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:Yo_OPEN_COUNT_DIC_KEY];
    if (!openCountDic) {
        openCountDic = [NSDictionary new];
    }
    
    // increment
    NSMutableDictionary *openCountMutableDic = [openCountDic mutableCopy];
    NSInteger openCountForUser = [openCountMutableDic[currentUserUniqueIdentifier] integerValue];
    openCountForUser++;
    
    // save
    [openCountMutableDic setObject:@(openCountForUser) forKey:currentUserUniqueIdentifier];
    [[NSUserDefaults standardUserDefaults] setObject:openCountMutableDic forKey:Yo_OPEN_COUNT_DIC_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return openCountForUser;
}

- (NSInteger)openCountForUser:(NSString *)username {
    if (![username length])
        return 0;
    
    NSString *currentUserUniqueIdentifier = username;
    
    NSDictionary *openCountDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:Yo_OPEN_COUNT_DIC_KEY];
    if (!openCountDic) {
        openCountDic = [NSDictionary new];
    }
    
    NSMutableDictionary *openCountMutableDic = [openCountDic mutableCopy];
    NSInteger openCountForUser = [openCountMutableDic[currentUserUniqueIdentifier] integerValue];
    
    return openCountForUser;
}

- (void)muteObject:(YoModelObject *)object completionHandler:(YoResponseBlock)block {
    NSTimeInterval secondsInEightHours = 8 * 60 * 60;
    NSDate *dateEightHoursAhead = [[NSDate date] dateByAddingTimeInterval:secondsInEightHours];
    NSString * timestamp = [NSString stringWithFormat:@"%f",[dateEightHoursAhead timeIntervalSince1970] * 1000000];
    [self.yoAPIClient POST:@"rpc/mute"
                parameters:@{@"username": object.username, @"expires": timestamp}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       if (block) {
                           block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"%@", error);
                       block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)unmuteObject:(YoModelObject *)object completionHandler:(YoResponseBlock)block {
    [self.yoAPIClient POST:@"rpc/unmute"
                parameters:@{@"username": object.username}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       if (block) {
                           block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"%@", error);
                       block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

#ifndef IS_APP_EXTENSION

#pragma mark - Phone Verification

- (void)getPhoneVerificationHashWithCompletionBlock:(void (^)(NSString *hash))block {
    void (^replyToBlock)(NSString *hash) = ^(NSString *hash){
        if (block) {
            block(hash);
        }
    };
    [self.yoAPIClient POST:@"rpc/gen_sms_hash"
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       NSString *hash = responseObject[@"hash"];
                       if (block) {
                           block(hash);
                       }
                       NS_HANDLER
                       replyToBlock(nil);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"%@", error);
                       replyToBlock(nil);
                   }];
}

- (void)verifyUserPhoneNumberWithHash:(NSString *)hash completionBlock:(void (^)(MessageComposeResult result))block {
    
    NSString *text = MakeString(NSLocalizedString(@"Tap Send \n or we can send you a text instead - tap Cancel :)\n\nCode: %@\n\n* Carrier charges may apply", nil), hash);
    NSString *number = @"+14156128793";
    [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:@[number]
                                                                   text:text
                                                            resultBlock:^(MessageComposeResult result) {
                                                                block(result);
                                                            }];
}

- (void)requestVerificationCodeForNumber:(NSString *)phoneNumber
                     withCompletionBlock:(void (^)(BOOL didSend))block
{
    void (^replyToBlock)(BOOL didSend) = ^(BOOL didSend){
        if (block) {
            block(didSend);
        }
    };
    NSMutableDictionary *parameters = [@{@"phone_number": phoneNumber} mutableCopy];
    if (self.possible_country_code.length) {
        parameters[@"country_code"] = self.possible_country_code;
    }
    [self.yoAPIClient POST:@"rpc/send_verification_code"
                parameters:parameters
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       replyToBlock(YES);
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       replyToBlock(NO);
                   }];
}

- (void)submitCode:(NSString *)code withCompletionBlock:(void (^)(BOOL didVerify))block {
    void (^replyToBlock)(BOOL didVerify) = ^(BOOL didVerify){
        if (block) {
            block(didVerify);
        }
    };
    [self.yoAPIClient POST:@"rpc/verify_code"
                parameters:@{@"code": code}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       [[YoUser me] setHasVerifiedPhoneNumber:YES];
                       replyToBlock(YES);
                       [YoAnalytics logEvent:YoEventVerifyingCodeSucceeded withParameters:nil];
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       replyToBlock(NO);
                       [YoAnalytics logEvent:YoEventVerifyingCodeFailed withParameters:nil];
                   }];
}

#endif

#pragma mark - User

- (void)clearUserPhoneNumberValidation{
    if (![self user]) {
        return;
    }
    
    self.user.hasVerifiedPhoneNumber = NO;
    [self.yoAPIClient POST:@"rpc/unset_my_phone_number"
                parameters:@{}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       DDLogWarn(@"Successfuly clear user phone validation");
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"Failed to update is verified %@", error);
                   }];
}

- (void)refreshUserProfileWithCompletionBlock:(void (^)(BOOL success))block{
    [self.yoAPIClient POST:@"rpc/get_me"
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                       NS_DURING
                       
                       if (responseObject) {
                           NSString *username = [responseObject objectForKey:Yo_USERNAME_KEY];
                           if (username) {
                               self.lastKnownValidUsername = username;
                           }
#ifndef IS_APP_EXTENSION
                           BOOL phoneNotVerified = [responseObject objectForKey:Yo_HAS_VERIFIED_PHONE_NUMBER_KEY] != nil && [[responseObject objectForKey:Yo_HAS_VERIFIED_PHONE_NUMBER_KEY] boolValue] == NO;
                           if (phoneNotVerified) {
                               [[APPDELEGATE mainController] presentPhoneVerificationFlowWithCloseButton:YES];
                               
                           }
#endif
                           
                           [self.user updateWithDictionary:responseObject];
                           
                           [[YoActivityManager sharedInstance] setUsername:[YoUser me].username];
                       }
                       
                       if (block) block(YES);
                       
                       NS_HANDLER
                       if (block) block(YES);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"%@", error);
                       if (block) block(NO);
                   }];
}

- (void)changeUserProperties:(NSDictionary *)properties completionHandler:(YoResponseBlock)block {
    if (![self user]) {
        if (block) block(YoResultFailed, 000, nil);
        return;
    }
    
    [self.yoAPIClient POST:@"rpc/set_me"
                parameters:properties
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       [self.user updateWithDictionary:responseObject]; // @or: TODO is responseObject the user or is it nested?
                       
                       if ([properties objectForKey:Yo_USERNAME_KEY]) {
                           self.lastKnownValidUsername = properties[Yo_USERNAME_KEY];
                       }
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)uploadUserProfilePicture:(UIImage *)profilePicture completionHandler:(YoResponseBlock)block {
    if (![self user]) {
        if (block) block(YoResultFailed, 000, nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *imageData = UIImageJPEGRepresentation(profilePicture, 1.0);
        
        NSString *encodedString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:1];
        if (encodedString) {
            parameters[@"image_body"] = encodedString;
        }
        __weak YoApp *weakSelf = self;
        [self.yoAPIClient POST:@"rpc/set_profile_picture"
                    parameters:parameters
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               NS_DURING
                               NSString *linkString = [operation.responseObject objectForKey:@"url"];
                               if ([linkString length]) {
                                   NSURL *photoURL = [NSURL URLWithString:linkString];
                                   if (photoURL) {
                                       weakSelf.user.photoURL = photoURL;
                                   }
                               }
                               else {
                                   weakSelf.user.photoURL = nil;
                               }
                               if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                               NS_HANDLER
                               if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                               NS_ENDHANDLER
                           });
                       }
                       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           DDLogWarn(@"Failed to upload user profile picture");
                           dispatch_async(dispatch_get_main_queue(), ^{
                               if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                           });
                       }];
    });
}

#pragma mark - Find Friends

- (void)findFriendsFromPhoneNumbers:(NSArray *)numbers completionBlock:(void (^)(NSArray *friendDictionaries))block {
    NSMutableDictionary *params = [@{@"phone_numbers": numbers} mutableCopy];
    
    NSString *default_country_code = [[YoApp currentSession] possible_country_code];
    if ([default_country_code length]) params[@"default_country_code"] = default_country_code;
    
    [self.yoAPIClient POST:@"rpc/find_friends"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       NS_DURING
                       
                       NSArray *friends = (NSArray *)responseObject[@"friends"];
                       
                       // sort
                       NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
                       friends = [[friends mutableCopy] sortedArrayUsingDescriptors:@[sortDescriptor]];
                       
                       if (block) block(friends);
                       
                       NS_HANDLER
                       if (block) block(nil);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) block(nil);
                   }];
}

- (void)findFriendsFromFacebook:(NSArray *)friendIds completionBlock:(void (^)(NSArray *friendDictionaries))block {
    [self.yoAPIClient POST:@"rpc/find_facebook_friends"
                parameters:@{@"facebook_ids": friendIds}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       NS_DURING
                       
                       NSArray *friends = (NSArray *)responseObject[@"friends"];
                       
                       // sort
                       NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
                       friends = [[friends mutableCopy] sortedArrayUsingDescriptors:@[sortDescriptor]];
                       
                       if (block) block(friends);
                       
                       NS_HANDLER
                       if (block) block(nil);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) block(nil);
                   }];
}

#pragma mark - Lazy Loading

- (YoAPIClient *)yoAPIClient {
    if (!_yoAPIClient) {
        _yoAPIClient = [[YoAPIClient alloc] initWithAccessToken:self.accessToken];
    }
    return _yoAPIClient;
}

- (void)portObjectFromDefaults:(NSUserDefaults *)fromDefaults toDefaults:(NSUserDefaults *)toDefaults withrKey:(NSString *)key {
    id obj = [fromDefaults objectForKey:key];
    if (obj) {
        [toDefaults setObject:obj forKey:key];
        [toDefaults synchronize];
    }
}

- (void)fetchEasterEggWithCompletionHandler:(YoResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        CLLocationCoordinate2D coordinate = [[YoLocationManager sharedInstance] cachedLocation].coordinate;
        params[@"location"] = MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude);
    }
    
    [self.yoAPIClient POST:@"rpc/get_easter_egg"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)fetchWebContextWithPath:(NSString *)path completionHandler:(YoResponseBlock)block {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        CLLocationCoordinate2D coordinate = [[YoLocationManager sharedInstance] cachedLocation].coordinate;
        params[@"location"] = MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude);
    }
    
    [self.yoAPIClient POST:MakeString(@"rpc/%@", path)
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

#pragma mark - Groups

- (void)createGroupWithName:(NSString *)groupName andMemberUsernames:(NSArray *)memberUsernames completionHandler:(YoResponseBlock)block {
    
    [self.yoAPIClient POST:@"rpc/add_group"
                parameters:@{@"name": groupName, @"members": memberUsernames}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)addMembersToGroup:(YoGroup *)group multipleUserObjects:(NSArray *)userObjects completionHandler:(YoResponseBlock)block {
    NSMutableArray *rawUsers = [NSMutableArray array];
    [userObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [rawUsers addObject:[obj toObject]];
    }];
    [self.yoAPIClient POST:@"rpc/add_group_members"
                parameters:@{@"username": group.username, @"members": rawUsers}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}



- (void)getGroupWithUsername:(NSString *)groupUserame completionHandler:(YoResponseBlock)block {
    
    [self.yoAPIClient POST:@"rpc/get_group"
                parameters:@{@"username": groupUserame}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)updateGroup:(YoGroup *)group updatedProperties:(NSDictionary *)updatedProperties completionHandler:(YoResponseBlock)block {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:group.username forKey:@"username"];
    [params addEntriesFromDictionary:updatedProperties];
    
    [self.yoAPIClient POST:@"rpc/update_group"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}


- (void)leaveGroupWithUsername:(NSString *)groupUserame completionHandler:(YoResponseBlock)block {
    
    [self.yoAPIClient POST:@"rpc/leave_group"
                parameters:@{@"username": groupUserame}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}

- (void)addToGroup:(YoGroup *)group userObject:(YoUser *)object completionHandler:(YoResponseBlock)block {
    NSMutableDictionary *params = [@{@"username": group.username } mutableCopy];
    
    if (object.phoneNumber) {
        params[@"member_phone_number"] = object.phoneNumber;
    }
    if (object.fullName) {
        params[@"member_name"] = object.fullName;
    }
    if (object.username) {
        params[@"member_username"] = object.username;
    }
    [self.yoAPIClient POST:@"rpc/add_group_member"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}


- (void)removeFromGroup:(YoGroup *)group memberWithUsername:(NSString *)userame completionHandler:(YoResponseBlock)block {
    
    [self.yoAPIClient POST:@"rpc/remove_group_member"
                parameters:@{@"username": group.username, @"member": userame}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       
                       // TODO
                       
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_HANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, operation.responseObject);
                       NS_ENDHANDLER
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to update ");
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
}


@end
