//
//  YoAnalytics.m
//  Yo
//
//  Created by Peter Reveles on 2/18/15.
//
//

#import "YoAnalytics.h"
#import "YoConfigManager.h"

#define YoParam_APP_ID @"app_id"
#define YoParam_SESSION_NUMBER @"app_session_number"
#define YoParam_USER_ID @"user_id"

#define YoParam_EVENT @"event"
#define YoParam_CURRENT_CONTROLLER @"current_controller"
#define YoParam_CONTROLLER_HISTORY_LOG @"controller_history_log"

#define YoParam_EVENT_PARAMS @"parameters"

#define Yo_EVENT_LOG_URL_PATH @"callback/gen_204"
#define Yo_EXEPTION_LOG _URL_PATH @"callback/log_exception"

@interface YoAnalytics ()
@property (nonatomic, strong) YoAPIClient *APIClient;
@end

@implementation YoAnalytics

#pragma mark - Lazy Loading

- (YoAPIClient *)APIClient {
    if (!_APIClient) {
        _APIClient = [[YoAPIClient alloc] initWithBaseURL:YoAnalyticsURL];
    }
    return _APIClient;
}

#pragma mark - Life

+ (instancetype)sharedInstance {
    static YoAnalytics *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - Event Loggging

+ (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters {
    NSDictionary *params = [YoAnalytics completeParametersForEvent:event withEventParameters:parameters];
    NS_DURING
    [[[YoAnalytics sharedInstance] APIClient] POST:Yo_EVENT_LOG_URL_PATH parameters:params success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogWarn(@"Failed to log event with error %@", error);
    }];
    NS_HANDLER
    NS_ENDHANDLER
}

+ (NSDictionary *)completeParametersForEvent:(NSString *)event withEventParameters:(NSDictionary *)eventParameters {
    NS_DURING
    NSMutableDictionary *resultDic = nil;
    
    resultDic = [NSMutableDictionary new];
    resultDic[YoParam_APP_ID] = [[YoActivityManager sharedInstance] getAppID]?:@"no_app_id";
    resultDic[YoParam_SESSION_NUMBER] = @([[YoActivityManager sharedInstance] getSessionNumber]);
    resultDic[@"username"] = [[YoActivityManager sharedInstance] username]?:@"username_unavailable";
#ifndef IS_APP_EXTENSION
    //resultDic[YoParam_CURRENT_CONTROLLER] = [[YoActivityManager sharedInstance] currentViewController]?:@"no_controller";
    NSInteger controllerHistoryCount = [[YoConfigManager sharedInstance] getYoAnalayticsDesiredControllerHistoryCount];
    resultDic[YoParam_CONTROLLER_HISTORY_LOG] = [[YoActivityManager sharedInstance] getControllerHistoryWithMaxCount:controllerHistoryCount]?:[NSArray new];
#endif
#ifdef IS_WATCH_EXTENSION
    resultDic[@"is_apple_watch"] = @(YES);
#endif
    resultDic[YoParam_EVENT] = event?:@"no_event";
    
    resultDic[YoParam_EVENT_PARAMS] = eventParameters?:[NSDictionary new];
    
    return resultDic;
    
    NS_HANDLER
    return nil;
    NS_ENDHANDLER
}

@end
