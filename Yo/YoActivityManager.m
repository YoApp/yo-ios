//
//  YoAnalytics.m
//  Yo
//
//  Created by Peter Reveles on 2/17/15.
//
//

#import "YoActivityManager.h"

#define YoActivityManagerAppID @"YoActivityManagerAppID"
#define YoActivityManagerSessionNumber @"YoActivityManagerSessionNumber"

@interface YoActivityManager ()
@property (nonatomic, strong) NSMutableArray *viewControllerActivityLog;
@property(nonatomic, strong) NSString *currentViewController;
@end

@implementation YoActivityManager

#pragma mark - Getter & Setters

- (void)incrementSessionNumber {
    NSInteger sessionNumber = [self getSessionNumber];
    sessionNumber++;
    NSString *sessionNumberString = MakeString(@"%li", (long)sessionNumber);
    NSUserDefaults *groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
    [groupUserDefaults setObject:sessionNumberString forKey:YoActivityManagerSessionNumber];
    [groupUserDefaults synchronize];
}

- (NSInteger)getSessionNumber {
    NSUserDefaults *groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
    NSString *sessionNumberString = [groupUserDefaults objectForKey:YoActivityManagerSessionNumber];
    NSInteger sessionNumber = 0;
#ifndef IS_APP_EXTENSION
    if (sessionNumberString == nil) {
       sessionNumberString = [[NSUserDefaults standardUserDefaults] objectForKey:YoActivityManagerSessionNumber];
    }
#endif
    if (sessionNumberString != nil) {
        sessionNumber = [sessionNumberString integerValue];
    }
    return sessionNumber;
}

- (NSString *)getAppID {
    NSUserDefaults *groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
    NSString *appID = [groupUserDefaults stringForKey:YoActivityManagerAppID];
    if (!appID.length) {
#ifndef IS_APP_EXTENSION
        NSString *appID = [[NSUserDefaults standardUserDefaults] stringForKey:YoActivityManagerAppID];
#endif
        if (!appID) {
            appID = [YoActivityManager genUniqueAppID];
            [groupUserDefaults setObject:appID forKey:YoActivityManagerAppID];
            [groupUserDefaults synchronize];
        }
    }
    return appID;
}

#pragma mark - Lazy Loading

- (NSMutableArray *)viewControllerActivityLog {
    if (!_viewControllerActivityLog) {
        _viewControllerActivityLog = [NSMutableArray new];
    }
    return _viewControllerActivityLog;
}

#pragma mark - Life

+ (instancetype)sharedInstance {
    static YoActivityManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)startListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForgroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)stopListeners {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self stopListeners];
}

#pragma mark - Listeners

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification {
    [self endSession];
}

- (void)appWillEnterForgroundNotification:(NSNotification *)notification {
    [self resumeLastKnownActivity];
}

- (void)resumeLastKnownActivity {
    YoActivity *lastKnownViewControllerActivity = [self.viewControllerActivityLog lastObject];
    if (lastKnownViewControllerActivity) {
        [lastKnownViewControllerActivity started];
    }
}

#pragma mark - External Utility

- (void)startSession {
    [self incrementSessionNumber];
    [self startListeners];
    
    if ([self.viewControllerActivityLog count]) {
        YoActivity *lastActivity = [self.viewControllerActivityLog lastObject];
        [lastActivity started];
    }
}

- (void)endSession {    
    YoActivity *lastViewControllerActivity = [self.viewControllerActivityLog lastObject];
    [lastViewControllerActivity ended];
    
    [YoAnalytics logEvent:YoEventSessionEnded withParameters:nil];
    
    self.viewControllerActivityLog = nil;
    if (lastViewControllerActivity) {
        [self.viewControllerActivityLog addObject:lastViewControllerActivity];
    }
    [self stopListeners];
}

- (NSArray *)getControllerHistoryWithMaxCount:(NSInteger)maxCount {
    NSMutableArray *viewControllerActivitiesPerformmedInSession = [NSMutableArray new];
    NSInteger index = 0;
    for (YoActivity *acitvity in self.viewControllerActivityLog) {
        if (index >= maxCount) {
            break;
        }
        else {
            [viewControllerActivitiesPerformmedInSession addObject:acitvity.info];
            index++;
        }
    }
    return viewControllerActivitiesPerformmedInSession;
}

#pragma mark - Controller Stack

- (void)controllerWillBePresented:(UIViewController <YoViewControllerProtocol> *)viewController {
  //  [self toogleNotificationsForCurrentViewController:viewController];
}

- (void)controllerPresented:(UIViewController <YoViewControllerProtocol> *)viewController {
    [self logControllerInUserActivityFeeed:viewController];
}

- (void)logControllerInUserActivityFeeed:(UIViewController <YoViewControllerProtocol> *)viewController {
    // end last activity if there is one
    YoActivity *lastActivity = [self.viewControllerActivityLog lastObject];
    [lastActivity ended];
    
    NSString *controllerIdentifier = [[viewController class] description];
    
    // set current view controller
    self.currentViewController = controllerIdentifier;
    
    // log activity
    NSString *activityName = MakeString(@"Viewed %@", controllerIdentifier);
    YoActivity *activity = [[YoActivity alloc] initWithName:activityName];
    [activity started];
    [self.viewControllerActivityLog addObject:activity];    
}

#ifndef IS_APP_EXTENSION
- (void)controllerDidDisAppear:(UIViewController <YoViewControllerProtocol> *)viewController {
    if (IS_OVER_IOS(8.0) && viewController.modalPresentationStyle == UIModalPresentationOverCurrentContext) {
        // this is a special case. This means the controller beneath will not
        // receive a call of didApear, becase of which, we will not receive a
        // controller presented call.
        UIViewController *topViewController = [APPDELEGATE topVC];
        if ([topViewController conformsToProtocol:@protocol(YoViewControllerProtocol)]) {
            [self logControllerInUserActivityFeeed:(UIViewController <YoViewControllerProtocol> *)topViewController];
            [self toogleNotificationsForCurrentViewController:(UIViewController <YoViewControllerProtocol> *)topViewController];
        }
    }
}
#endif

#pragma mark - Activity Maintainance

- (void)toogleNotificationsForCurrentViewController:(UIViewController <YoViewControllerProtocol> *)viewController {
    BOOL pauseNotification = ![viewController areNotificationAllowed];
    [[[YoApp currentSession] notificationManager] setPauseNotifications:pauseNotification];
}

#pragma mark - Internal Utility

+ (NSString *)genUniqueAppID {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uniqueAppId = (__bridge_transfer NSString *)uuidStringRef;
    uniqueAppId = MakeString(@"iOSClient-%@", uniqueAppId);
    return uniqueAppId;
}

@end
