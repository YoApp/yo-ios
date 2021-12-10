
#import "YOAppDelegate.h"
#import "YoMainController.h"
#import "Flurry.h"
#import "Appirater.h"
#import "YoView.h"
#import "EDSemver.h"
#import <SSKeychain/SSKeychain.h>
#import "OAuthAuthorizeController.h"
//#import <FlashPolls/FlashPollsSDK.h>
#include <unistd.h>
#include <netdb.h>
#import "DDTTYLogger.h"
#import "MobliConfigManager.h"
#import "YoConfigManager.h"
#import "YoManager.h"
#import "YoUser.h"
#import "TSTapstream.h"
#import <CoreLocation/CoreLocation.h>

#import "YoNetworkAssistant.h"
#import "YoImgUploadClient.h"
#import "YoLoggedOutViewController.h"
#import "YoThemeManager.h"
#import "YoMainNavigationController.h"

#ifndef IS_APP_EXTENSION
@import Batch;
#import <Optimizely/Optimizely.h>
#import <CHCSVParser/CHCSVParser.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Smooch/Smooch.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#endif

#define kYoBackAction @"kYoBackAction"
#define kYoLocationAction @"kYoLocationAction"
#define kYoUnsubAction  @"kYoUnsubAction"

#import "Yo+Utility.h"
#import "YoInbox.h"

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "YoActionPerformer.h"
#import "YOFacebookManager.h"

@interface YOAppDelegate ()
@property(nonatomic, strong) NSMutableDictionary *tips;
@end


@implementation YOAppDelegate

- (void)testStuff {
    UIPasteboard *appPasteBoard = [UIPasteboard generalPasteboard];
    DDLogInfo(@"pasteBoard: %@",[appPasteBoard string]);
}

#pragma mark - DidFinishLaunchingWithOptions

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self handleShortCutItem:shortcutItem completionHandler:completionHandler];
}

- (void)handleShortCutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([shortcutItem.type isEqualToString:@"yo"]) {
        NSString *type = (NSString *)shortcutItem.userInfo[@"type"];
        NSString *username = (NSString *)shortcutItem.userInfo[@"username"];
        if ([type isEqualToString:@"just_yo"]) {
            [[YoManager sharedInstance] yo:username completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                if (completionHandler) {
                    completionHandler(YES);
                }
            }];
        }
        else if ([type isEqualToString:@"location"]) {
            [[YoManager sharedInstance] yo:username withCurrentLocation:YES completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                if (completionHandler) {
                    completionHandler(YES);
                }
            }];
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if (IS_OVER_IOS(9.0)) {
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (shortcutItem){
            [self handleShortCutItem:shortcutItem completionHandler:nil];
        }
    }
    
    //[FlashPollsSDK initWithAppToken:@"049eff5c-75b8-480b-9825-b682d082925b" launchOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    self.navigationController = [mainStoryboard instantiateInitialViewController];
    self.mainController = (YoMainController *)[self.navigationController topViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kYoUserLoginDidFailNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (![self.topVC isKindOfClass:[YoLoggedOutViewController class]]) {
                                                          if (self.navigationController.presentedViewController != nil) {
                                                              [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                                                  [self.navigationController presentLogin];
                                                              }];
                                                          }
                                                          else {
                                                              [self.navigationController presentLogin];
                                                          }
                                                      }
                                                  }];
    
    [[YoApp currentSession] load];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupThirdParties:launchOptions];
    });
    
    return YES;
}

- (void)setupThirdParties:(NSDictionary *)launchOptions {
    [self startLogger];
    [self startAppirater];
    [self startStats];
    [self startConfig];
    
    [Optimizely startOptimizelyWithAPIToken:@"AAM7hIkBE4GRojjIvLkOLqDVK0CgRPgT~3599423305" launchOptions:launchOptions];
    
#ifdef DEBUG
    [self testStuff];
    [Batch startWithAPIKey:@"DEV54EF61519873E7D44375EEED8B1"];
#else
    [Batch startWithAPIKey:@"54EF61519779FA514CC8A8562A9EF0"];
#endif
    
    [BatchPush registerForRemoteNotifications];
    
    TSConfig *config = [TSConfig configWithDefaults];
    [TSTapstream createWithAccountName:@"justyo" developerSecret:@"KutzBStiTFuHaOMWsjIISw" config:config];
    
    if (IS_OVER_IOS(7.0)) {
        [Smooch initWithSettings:
         [SKTSettings settingsWithAppToken:@"5feop48lap3z1i42amkcbi3y7"]];
    }
    
    [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication]
                             didFinishLaunchingWithOptions:launchOptions];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [self performSelectorInBackground:@selector(checkInternet) withObject:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [Appirater appEnteredForeground:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    START_BACKGROUND_TASK
    
    [[YoConfigManager sharedInstance] updateWithCompletionHandler:^(BOOL success) {
        END_BACKGROUND_TASK
        if (success) {
            [[YoThemeManager sharedInstance] parseThemeString];
        }
    }];
    
    
    /* UILocalNotification *n = [[UILocalNotification alloc] init];
     n.fireDate = [NSDate date];
     n.category = @"inline-text";
     n.alertBody = @"💵 Western Union: New Offer! Redeem 75 My WU points – Get a $12 service fee¹ reduction!? Enter your email to redeem!";
     [[UIApplication sharedApplication] scheduleLocalNotification:n];*/
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //    [YoMagic handleApplicationDidEnterBackground];
}

- (void)presentAuthorizationController:(NSURL *)url {
    
    OAuthAuthorizeController *authVc = [[OAuthAuthorizeController alloc] initWithNibName:@"OAuthAuthorizeController" bundle:nil];
    authVc.clientId = [self paramForKey:@"clientId" inURLString:url.absoluteString];
    authVc.appId = [self paramForKey:@"appId" inURLString:url.absoluteString];
    
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:authVc];
    nc.modalPresentationStyle = UIModalPresentationCustom;
    [[self topVC] presentViewController:nc animated:YES completion:nil];
    
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    NS_DURING
    
    if ([Optimizely handleOpenURL:url]) {
        return YES;
    }
    
    // facebook
    if ([[url.scheme lowercaseString] hasPrefix:@"fb"]) {
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    }
#warning TODO Enhancement - Store username from attempted add and add them after user is logged in
    if ([[url.scheme lowercaseString] isEqualToString:@"yo"]/* && [[YoApp currentSession] isLoggedIn]*/) {
        
        if ([[url host] isEqualToString:@"fbinvite"]) {
            [[self topVC] dismissViewControllerAnimated:YES completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowInviteFacebook" object:nil];
            }];
            return YES;
        }
        
        if ([[url host] isEqualToString:@"login"]) {
            
            if ([[YoApp currentSession] isLoggedIn]) {
                [self presentAuthorizationController:url];
            }
            else {
                self.oauthURL = url;
            }
            
            return YES;
        }
        
        
        NSString *arg = [[[url absoluteString] stringByReplacingOccurrencesOfString:MakeString(@"%@://", url.scheme) withString:@""] uppercaseString];
        
        if (arg.length == 0) {
            return YES;
        }
        
        if ([arg rangeOfString:@"+"].location == NSNotFound) {
            NSString *username = arg;
            [[YoManager sharedInstance] yo:username completionHandler:nil];
        }
        else {
            NSArray *usernames = [[url host] componentsSeparatedByString:@"+"];
            
            NSTimeInterval throttle = 0.0;
            
            NSMutableArray *upper = [NSMutableArray array];
            for (NSString *username in usernames) {
                [upper addObject:[username uppercaseString]];
                NSString *usernameUPPR = [username uppercaseString];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(throttle * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YoManager sharedInstance] yo:usernameUPPR completionHandler:nil];
                });
                throttle += 0.5;
            }
        }
        
        NSString *usernameStringToDisplay = [arg stringByReplacingOccurrencesOfString:@"+" withString:@", "];
        
        YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Subscribed!"
                                             desciption:MakeString(@"You are now subscribed to %@", usernameStringToDisplay)];
        [alert addAction:[[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:alert animated:NO completionBlock:nil];
        
        return YES;
    }
    else {
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    }
    NS_HANDLER
    DDLogError(@"%@", localException);
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
    NS_ENDHANDLER
}

- (NSString *)paramForKey:(NSString *)key inURLString:(NSString *)urlString{
    NSString *delimeter = @"&";
    //   key = key.lowercaseString;
    //    urlString = urlString.lowercaseString;
    NSRange rangeOfKeyInURLString = [urlString rangeOfString:key];
    if (rangeOfKeyInURLString.location == NSNotFound) return nil;
    NSString *param = [urlString substringFromIndex:rangeOfKeyInURLString.location];
    NSRange rangeOfDelimeterInParam = [param rangeOfString:delimeter];
    if (rangeOfDelimeterInParam.location != NSNotFound)
    param = [param substringToIndex:rangeOfDelimeterInParam.location];
    if ([param rangeOfString:@"="].location == NSNotFound) return nil;
    param = [param substringFromIndex:[param rangeOfString:@"="].location + 1];
    return param;
}

#pragma mark - Push

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    //register to receive notifications
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"User_Did_Register_For_Push_Notification" object:nil]];
    
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"User_Did_Register_For_Push_Notification" object:nil]];
    
    NSString *deviceToken = [[[[newDeviceToken description]
                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    
    
    if ([[YoApp currentSession] isLoggedIn] && (! self.pushToken || ! [self.pushToken isEqualToString:deviceToken])) {
        [[YoApp currentSession] grantAbilityToReceivePushNotificationsWithPushToken:deviceToken];
    }
    
    self.pushToken = deviceToken;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"User_Did_Fail_To_Register_For_Push_Notification" object:nil]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self handleIncomingPush:userInfo fetchCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self handleIncomingPush:userInfo fetchCompletionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self handleIncomingPush:notification.userInfo fetchCompletionHandler:nil];
}

- (void)handleIncomingPush:(id)payload fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
#ifdef IS_BETA
    NSLog(@"1 %@", payload);
#endif
    if ([payload objectForKey:@"yo_id"]) {
        [self handleIncomingYoPayload:payload fetchCompletionHandler:completionHandler];
    }
    else {
        [self handleIncomingRegularPushPayload:payload fetchCompletionHandler:completionHandler];
    }
}

#ifndef IS_APP_EXTENSION

- (void)handleIncomingRegularPushPayload:(id)payload fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NS_DURING
    
    if ([payload[@"command"] isEqualToString:@"add_response"]) {
        
        NSDictionary *rawCategory = payload[@"args"][0];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *filePath = [NSString stringWithFormat:@"%@/categories.json", documentsDirectory];
        
        NSData *localData = [NSData dataWithContentsOfFile:filePath];
        
        NSMutableArray *rawLocalCategories = [[[NSJSONSerialization JSONObjectWithData:localData
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:nil] valueForKey:@"categories"] mutableCopy];
        
        
        [rawLocalCategories addObject:rawCategory];
        
        NSSet *categoriesWithNewOne = [[self parseCategories:[NSSet setWithArray:rawLocalCategories]] mutableCopy];
        
        [self registerCategories:categoriesWithNewOne];
        
        NSData *mergedData = [NSJSONSerialization dataWithJSONObject:@{@"categories": rawLocalCategories } options:NSJSONWritingPrettyPrinted error:nil];
        
        [mergedData writeToFile:filePath atomically:YES];
        
        [[[YoApp currentSession] yoAPIClient] POST:@"rpc/command_ack"
                                        parameters:@{@"id": payload[@"id"],
                                                     @"command": payload[@"command"],
                                                     @"status_code": @"200"}
                                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                               DDLogDebug(@"Sent ack");
                                               
                                               if (completionHandler) {
                                                   completionHandler(UIBackgroundFetchResultNewData);
                                               }
                                               
                                           }
                                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                               DDLogError(@"%@", error);
                                               
                                               if (completionHandler) {
                                                   completionHandler(UIBackgroundFetchResultNewData);
                                               }
                                           }];
        return;
    }
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        if (payload[@"msg"]) {
            YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Yo" desciption:payload[@"aps"][@"alert"]];
            
            NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:2];
            
            if (payload[@"action"] != nil) {
                NSString *action = payload[@"action_dic"][@"type"];
                NSString *actionTitle = payload[@"action_dic"][@"title"];
                if (action && actionTitle) {
                    NSString *dismissActionTitle = payload[@"action_dic"][@"dismiss_title"];
                    if (dismissActionTitle) {
                        [actions addObject:
                         [[YoAlertAction alloc] initWithTitle:dismissActionTitle tapBlock:nil]];
                    }
                    
                    NSDictionary *params = payload[@"action_dic"][@"params"];
                    [actions addObject:
                     [[YoAlertAction alloc] initWithTitle:actionTitle tapBlock:^{
                        [YoActionPerformer performAction:action withParameters:params];
                    }]];
                }
            }
            
            if (actions.count == 0) {
                [actions addObject:
                 [[YoAlertAction alloc] initWithTitle:@"OK" tapBlock:nil]];
            }
            
            for (YoAlertAction *action in actions) {
                [alert addAction:action];
            }
            
            [[YoAlertManager sharedInstance] showAlert:alert];
        }
    }
    
    if (payload[@"sender"]) {
        [[[YoUser me] contactsManager] promoteObjectToTopWithUsername:payload[@"sender"]];
    }
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
    
    NS_HANDLER
    DDLogError(@"%@", localException);
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
    NS_ENDHANDLER
}

- (void)handleIncomingYoPayload:(id)yoPayload fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (!yoPayload) {
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultNoData);
        }
        return;
    }
    
    NS_DURING
    
    if ([yoPayload[@"action"] isEqualToString:@"update_yo_status"]) {
        YoModelObject *object = [[[YoUser me] contactsManager] objectForUsername:yoPayload[@"username"]];
        if (object) {
            NSLog(@"Updating object: %@", object);
            object.lastYoStatus = yoPayload[@"status"];
            object.lastYoDate = [NSDate dateWithTimeIntervalSince1970:[[yoPayload objectForKey:@"time"] doubleValue] / pow(10, 6)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ObjectChanged" object:object];
        }
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    Yo *yo  = [[Yo alloc] initWithPushPayload:yoPayload];
    [yo refresh];
    
    if ([yo isFromService] == NO) {
#warning Todo: at this point has the contactsManager loaded its contacts from disc?
        [[[YoUser me] contactsManager] promoteObjectToTopWithUsername:yo.senderUsername];
    }
    
    if (yo) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
            dispatch_async(dispatch_get_main_queue(), ^{ // @or if not delayed animation gets stuck
                [yo open];
                
                if (completionHandler) {
                    completionHandler(UIBackgroundFetchResultNewData);
                }
            });
        }
        else {
            [self playSound:@"yo"];
            [[[YoUser me] yoInbox] updateOrAddYo:yo withStatus:YoStatusReceived];
            if (completionHandler) {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }
    }
    NS_HANDLER
    DDLogError(@"%@", localException);
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
    NS_ENDHANDLER
}
#endif

#pragma mark - Push Notifications with Actions

- (BOOL)isRegisteredForPushNotifications{
    BOOL isRegisteredForNotifications = YES;
    if (IS_OVER_IOS(8.0)) {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (settings.types == UIUserNotificationTypeNone || ![settings.categories count]) {
            isRegisteredForNotifications = NO;
        }
    } else {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (types == UIRemoteNotificationTypeNone) {
            isRegisteredForNotifications = NO;
        }
    }
    return isRegisteredForNotifications;
}

- (NSMutableSet *)parseCategories:(NSSet *)rawCategories {
    if ( ! rawCategories) {
        return nil;
    }
    NSMutableSet *categories = [NSMutableSet set];
    
    for (NSDictionary *rawCategory in rawCategories) {
        if ([rawCategory isKindOfClass:[NSDictionary class]]) {
            UIMutableUserNotificationCategory *category = [self createCategoryWithRawCategory:rawCategory];
            if (category) {
                [categories addObject:category];
            }
        }
        else {
            DDLogError(@"%@", rawCategory);
        }
    }
    return categories;
}

- (void)registerCategories:(NSSet *)categories {
    
    UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
    category.identifier = @"inline-text";
    [category setActions:@[[self createTextAction]]
              forContext:UIUserNotificationActionContextDefault];
    
    categories = [categories setByAddingObject:category];
    UIUserNotificationType types = UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (NSURL *)localURLforCategoriesJson {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/categories.json", documentsDirectory];
    
    NSURL *localURL = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        localURL = [NSURL fileURLWithPath:filePath];
    }
    else {
        localURL = [[NSBundle mainBundle] URLForResource:@"categories" withExtension:@"json"];
    }
    return localURL;
}

- (void)registerForPushNotifications {
    if (IS_OVER_IOS(8.0)) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSURL *localURL = [self localURLforCategoriesJson];
            
            NSData *localData = [NSData dataWithContentsOfURL:localURL];
            NSArray *rawLocalCategories = [[NSJSONSerialization JSONObjectWithData:localData
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:nil] valueForKey:@"categories"];
            NSSet *localCategories = [self parseCategories:[NSSet setWithArray:rawLocalCategories]];
            [self registerCategories:localCategories];
            
            NSURL *remoteURL = [NSURL URLWithString:@"https://yoapp.s3.amazonaws.com/yo/categories.json"];
            NSData *remoteData = [NSData dataWithContentsOfURL:remoteURL];
            if (remoteData) {
                NSArray *rawRemoteCategories = [[NSJSONSerialization JSONObjectWithData:remoteData
                                                                                options:NSJSONReadingAllowFragments
                                                                                  error:nil] valueForKey:@"categories"];
                
                NSSet *rawMerged = [[NSSet setWithArray:rawLocalCategories] setByAddingObjectsFromArray:rawRemoteCategories];
                
                NSSet *merged = [self parseCategories:rawMerged];
                
                if ( ! [merged isEqualToSet:localCategories]) {
                    
                    [self registerCategories:merged];
                    
                    NSData *mergedData = [NSJSONSerialization dataWithJSONObject:@{@"categories": [rawMerged allObjects]} options:NSJSONWritingPrettyPrinted error:nil];
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSString *filePath = [NSString stringWithFormat:@"%@/categories.json", documentsDirectory];
                    [mergedData writeToFile:filePath atomically:YES];
                }
            }
        });
    }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
         UIRemoteNotificationTypeAlert|
         UIRemoteNotificationTypeSound];
    }
}

- (UIMutableUserNotificationCategory *)createCategoryWithRawCategory:(NSDictionary *)rawCategory {
    if ( ! rawCategory[@"identifier"]) {
        return nil;
    }
    UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
    category.identifier = rawCategory[@"identifier"];
    
    NSArray *rawActions = [rawCategory valueForKey:@"actions"];
    if (rawActions.count > 0) {
        NSMutableArray *actions = [NSMutableArray array];
        for (NSDictionary *rawAction in rawActions) {
            [actions addObject:[self createActionWithRawAction:rawAction]];
        }
        
        [category setActions:actions
                  forContext:UIUserNotificationActionContextDefault];
    }
    return category;
}

- (UIMutableUserNotificationAction *)createActionWithRawAction:(NSDictionary *)rawAction {
    UIMutableUserNotificationAction *action = [UIMutableUserNotificationAction new];
    action.identifier = rawAction[@"identifier"];
    action.title = rawAction[@"title"];
    action.activationMode = [rawAction[@"is_background"] boolValue] ? UIUserNotificationActivationModeBackground : UIUserNotificationActivationModeForeground;
    action.destructive = [rawAction[@"is_destructive"] boolValue];
    action.authenticationRequired = [rawAction[@"is_authentication_required"] boolValue];
    return action;
}

- (UIMutableUserNotificationAction *)createTextAction {
    UIMutableUserNotificationAction *action = [UIMutableUserNotificationAction new];
    action.identifier = @"inline.text";
    action.title = @"Reply";
    action.activationMode = UIUserNotificationActivationModeBackground;
    action.authenticationRequired = NO;
    if (IS_OVER_IOS(9.0)) {
        action.behavior = UIUserNotificationActionBehaviorTextInput;
    }
    return action;
}


- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {
    
    /*NSString *deepLink = @"sms:+14156576882";
     if (deepLink) {
     dispatch_async(dispatch_get_main_queue(), ^{
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:deepLink]];
     completionHandler();
     });
     return;
     }
     
     
     [[YoManager sharedInstance] yo:@"OR" contextParameters:@{@"context": identifier, @"reply_to": @"32452", @"from_push": @(YES)}
     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
     completionHandler();
     }];*/
    
    
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    
    Yo *yo = [[Yo alloc] initWithPushPayload:userInfo];
    yo.openedFromPush = YES;
    
    NSRange range = [yo.category rangeOfString:@"."];
    BOOL categoryTextContainsPeriod = (range.location != NSNotFound);
    if (categoryTextContainsPeriod) {
        NS_DURING
        
        NSString *deepLink = nil;
        
        NSArray *components = [yo.category componentsSeparatedByString:@"."];
        if ([identifier isEqualToString:components[0]]) {
            deepLink = userInfo[@"left_deep_link"];
        }
        else if ([identifier isEqualToString:components[1]]) {
            deepLink = userInfo[@"right_deep_link"];
        }
        
        if (deepLink) {
            NSURL *url = [NSURL URLWithString:deepLink];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:url];
                    completionHandler();
                });
                return;
            }
        }
        
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    
    if ([yo.senderUsername length]) {
        if ([identifier isEqualToString:kYoBackAction] || [identifier isEqualToString:@"yo"]) {
            START_BACKGROUND_TASK
            [[[YoUser me] yoInbox] updateOrAddYo:yo
                                      withStatus:YoStatusRead];
            
            [[YoManager sharedInstance] yo:yo.senderUsername completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                completionHandler();
                END_BACKGROUND_TASK
            }];
        }
        else if ([identifier isEqualToString:kYoLocationAction] || [identifier isEqualToString:@"send.location"]) {
            START_BACKGROUND_TASK
            [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardStarted object:self userInfo:@{Yo_USERNAME_KEY:yo.senderUsername, @"type": @"location"}];
            [[YoManager sharedInstance] yo:yo.senderUsername withCurrentLocation:YES completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished
                                                                    object:self
                                                                  userInfo:@{
                                                                             Yo_USERNAME_KEY:yo.senderUsername,
                                                                             @"success": @(result == YoResultSuccess)                                                    }];
                END_BACKGROUND_TASK
            }];
            completionHandler();
        }
        else if ([identifier isEqualToString:kYoUnsubAction]) {
            START_BACKGROUND_TASK
            [[[YoUser me] yoInbox] updateOrAddYo:yo
                                      withStatus:YoStatusRead];
            
            YoUser *user = [YoUser new];
            user.username = yo.senderUsername;
            [[[YoUser me] contactsManager] blockObject:user withCompletionBlock:^(BOOL success) {
                completionHandler();
                END_BACKGROUND_TASK
            }];
        }
        else {
            START_BACKGROUND_TASK
            [[YoManager sharedInstance] yo:yo.senderUsername contextParameters:@{@"context": identifier, @"reply_to": yo.yoID, @"from_push": @(YES)}
                         completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                             completionHandler();
                             END_BACKGROUND_TASK
                         }];
        }
    }
}

#pragma mark - Handoff

#define YoActivityIdentifierViewingYo @"com.yo.yo.user-activity.viewing-yo"

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    if ([userActivity.activityType isEqualToString:YoActivityIdentifierViewingYo]) {
        id yoPayload = [userActivity.userInfo valueForKey:@"yo"];
        if (yoPayload) {
            Yo *yo = [[Yo alloc] initWithPushPayload:yoPayload];
            if (yo) {
                [yo open];
                [YoAnalytics logEvent:YoEventOpenedYoFromHandoff withParameters:@{YoParam_Yo_PAYLOAD:yo.payload?:@{}}];
            }
        }
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - WatchKit

#define AppleWatchScrenWidth 312.0f

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    void (^cleanUp)(NSDictionary * response, UIBackgroundTaskIdentifier bgTask) = ^(NSDictionary * response , UIBackgroundTaskIdentifier bgTask) {
        if (reply) {
            reply(response);
        }
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    };
    
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithName:@"YoBackgroundTask" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        cleanUp(@{@"error":@"timed out while performing background task"}, bgTask);
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Do the work associated with the task, preferably in chunks.
        NSString *request = [userInfo valueForKey:YoAssistantRequestKey];
        if ([request isEqualToString:YoAssistantSendYo]) {
            [[YoApp currentSession] load];
            [self sendYoWithUserInfo:userInfo completionBlock:^(BOOL success, NSString *error) {
                if (success) {
                    cleanUp(@{@"successBool":@(true)}, bgTask);
                }
                else {
                    cleanUp(@{@"error":error}, bgTask);
                }
            }];
        }
        else if ([request isEqualToString:YoAssistantLoadParentApp]) {
            // load contacts is the only thing currently that needs loading
            [[YoApp currentSession] load];
            [[[YoUser me] contactsManager] updateContactsWithCompletionBlock:^(bool success) {
                cleanUp(@{@"successBool":@(success)}, bgTask);
            }];
        }
        else {
            cleanUp(@{@"error":@"request made for unsupported type"}, bgTask);
        }
    });
}

- (void)sendYoWithUserInfo:(NSDictionary *)userInfo completionBlock:(void (^)(BOOL success, NSString *error))completionBlock {
    NSString *username = [userInfo valueForKey:YoAssistantYoUsernameKey];
    NSNumber *latNumb = [userInfo valueForKey:YoAssistantLatKey];
    NSNumber *longNumb = [userInfo valueForKey:YoAssistantLongKey];
    if (username.length) {
        if (latNumb != nil && longNumb != nil) {
            // Yo With Location
            CLLocation *location = [[CLLocation alloc] initWithLatitude:latNumb.doubleValue
                                                              longitude:longNumb.doubleValue];
            if (location != nil) {
                [[YoManager sharedInstance] yo:username
                                  withLocation:location
                             completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                 if (completionBlock) {
                                     completionBlock(YES, nil);
                                 }
                             }];
            }
            else {
                if (completionBlock) {
                    completionBlock(NO, @"unable to parse location");
                }
            }
            
        }
        else {
            BOOL withLocation = [[userInfo valueForKey:YoAssistantWithLocationBoolKey] boolValue];
            // just Yo
            [[YoManager sharedInstance] yo:username
                       withCurrentLocation:withLocation
                         completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
             {
                 if (completionBlock) {
                     completionBlock(YES, nil);
                 }
             }];
        }
    }
    else {
        if (completionBlock) {
            completionBlock(NO, @"no username");
        }
    }
}

#pragma mark - Tips

- (void)buttonTapped:(NSNotification *)notification {
    NSString *key = notification.userInfo[@"key"];
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:key] && [self.tips[key] length] > 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:self.tips[key]
                                               desciption:nil];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Got it!", nil) tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}

#pragma mark - Sounds

- (void)playSound:(NSString *)filenameWithOutMp3Ext {
    if (!filenameWithOutMp3Ext) {
        return;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:filenameWithOutMp3Ext ofType:@"mp3"];
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    if (url) {
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        [self.player play];
    }
}

#pragma mark - Config

- (void)startConfig {
    dispatch_async(dispatch_get_main_queue(), ^{
        // [MobliConfigManager sharedInstance];
    });
}

#pragma mark - Logger

- (void)startLogger{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
#ifdef DEBUG
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    UIColor *pink = [UIColor colorWithRed:239/255.0f green:156/255.0f blue:189/255.0f alpha:1];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    
    UIColor *green = [UIColor colorWithRed:65/255.0f green:174/255.0f blue:34/255.0f alpha:1];
    [[DDTTYLogger sharedInstance] setForegroundColor:green backgroundColor:nil forFlag:LOG_FLAG_INFO];
#endif
}

#pragma mark - Appirator

- (void)startAppirater {
    [Appirater setAppId:@"834335592"];
    [Appirater setDaysUntilPrompt:6];
    [Appirater setUsesUntilPrompt:7];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
}

#pragma mark - Stats

- (void)startStats {
    [Flurry startSession:@"HRYV2J2PNZ7FNC3MJWTQ"];
    [Flurry setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    [Fabric with:@[CrashlyticsKit]];
}

#pragma mark - Avilability

- (BOOL)hasInternet{
    @autoreleasepool {
        
        if ([NSThread isMainThread]) {
            DDLogError(@"DO NOT RUN THIS ON MAIN THREAD OR IT WILL FREEZE THE APP!");
            return YES; // @or: fake yes
        }
        
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [reachability currentReachabilityStatus];
        return networkStatus != NotReachable;
    }
}

-(void)checkInternet {
    if (![self hasInternet]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"No Internet!", nil)
                                                   desciption:NSLocalizedString(@"Yo needs internet!", nil)];
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
        });
    }
}


#pragma mark - Update

- (void)checkUpdate {
    @autoreleasepool {
        
        NS_DURING
        
        NSString *serverVersion = [[YoConfigManager sharedInstance] serverVersionNumber];
        
        NSString *myVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        BOOL isUpdateMandatory = [[YoConfigManager sharedInstance] isUpdateMandatory];
        NSString *releaseNotes = [[YoConfigManager sharedInstance] releaseNotes];
        
        EDSemver *serverSemVersion  = [[EDSemver alloc] initWithString:serverVersion];
        EDSemver *mySemVersion = [[EDSemver alloc] initWithString:myVersion];
        
        if ([serverSemVersion isGreaterThan:mySemVersion]) {
            if (isUpdateMandatory) {
                YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Update", nil)
                                                       desciption:MakeString(NSLocalizedString(@"There is a newer version of Yo.\n%@", nil), releaseNotes)];
                [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Update", nil) tapBlock:^{
                    NSString *iTunesLink = @"https://itunes.apple.com/us/app/apple-store/id834335592?mt=8";
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                }]];
                [[YoAlertManager sharedInstance] showAlert:yoAlert];
            }
            else {
                YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Update", nil)
                                                       desciption:MakeString(@"There is a newer version. Do you want to update?\n%@", releaseNotes)];
                [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Not now", nil) tapBlock:nil]];
                [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Update", nil) tapBlock:^{
                    NSString *iTunesLink = @"https://itunes.apple.com/us/app/apple-store/id834335592?mt=8";
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                }]];
                [[YoAlertManager sharedInstance] showAlert:yoAlert];
            }
        }
        NS_HANDLER
        NS_ENDHANDLER
    }
}

#pragma mark - Modal Controllers

- (UIViewController *)topVC {
    UIViewController *topVC = self.window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
