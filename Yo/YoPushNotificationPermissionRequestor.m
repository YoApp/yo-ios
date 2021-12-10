//
//  YoPushNotificationRequestor.m
//  Yo
//
//  Created by Peter Reveles on 2/12/15.
//
//

#import "YoPushNotificationPermissionRequestor.h"

@interface YoPushNotificationPermissionRequestor ()
@property (nonatomic, copy) PushNotificationRequestResultBlock resultBlock;
@property (nonatomic, assign) BOOL requestAlertIsOnScreen;
@end

@implementation YoPushNotificationPermissionRequestor

+ (instancetype)sharedInstance {
    
    static YoPushNotificationPermissionRequestor *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - Listeners

- (void)appDidBecomeActive {
    self.requestAlertIsOnScreen = NO;
    if (![APPDELEGATE isRegisteredForPushNotifications]) {
        [self respondToRequesterWithResult:NO];
    }
}

- (void)appDidResignActive {
    self.requestAlertIsOnScreen = YES;
}

- (void)userDidRegisterForPushNotifications:(NSNotification *)note{
    [self respondToRequesterWithResult:YES];
}

- (void)userDidFailToRegisterForPushNotifications:(NSNotification *)note {
    [self respondToRequesterWithResult:NO];
}

- (void)respondToRequesterWithResult:(BOOL)permissionGranted {
    if (self.resultBlock) {
        self.resultBlock(permissionGranted);
        self.resultBlock = nil;
    }
    [self stopListening];
}

#pragma mark - Internal Utitlty Methods

- (void)startListeing {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidRegisterForPushNotifications:) name:@"User_Did_Register_For_Push_Notification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidFailToRegisterForPushNotifications:) name:@"User_Did_Fail_To_Register_For_Push_Notification" object:nil];
}

- (void)stopListening {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self stopListening];
}

#pragma mark - External Utility

- (void)makeRequestWithCompletionBlock:(PushNotificationRequestResultBlock)resultBlock {
    if (APPDELEGATE.isRegisteredForPushNotifications) {
        if (resultBlock) {
            resultBlock(YES);
        }
        return;
    }
    
    [self startListeing];
    if (resultBlock) {
        self.resultBlock = resultBlock;
    }
    [APPDELEGATE registerForPushNotifications];
}

@end
