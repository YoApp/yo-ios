//
//  YoManager.m
//  Yo
//
//  Created by Peter Reveles on 1/5/15.
//
//

#import "YoManager.h"
#import <CoreLocation/CoreLocation.h>
#import "YoLocationManager.h"
#import "YoImgUploadClient.h"
#import "YoApp.h"
#import "YoPushNotificationPermissionRequestor.h"
#import "YoMapContext.h"
#import "YoCameraContext.h"
#import "YoLocalPushNotificationAssistant.h"

#define YO_SOUND_FILE @"yo.mp3"
#define YO_YO_SOUND_FILE @"yoyo.mp3"

@interface YoManager ()
@property (weak, nonatomic) YoAPIClient *yoAPIClient;
@end

@implementation YoManager

#pragma mark - Life Cycle

- (instancetype)initWithYoAPIClient:(YoAPIClient *)yoAPIClient{
    self = [super init];
    if (self) {
        _yoAPIClient = yoAPIClient;
        
    }
    return self;
}

+ (instancetype)sharedInstance {
    static YoManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] initWithYoAPIClient:[[YoApp currentSession] yoAPIClient]];
    });
    
    return _sharedInstance;
}


#pragma mark Network

- (void)grantNetworkAccessWithAPIClient:(YoAPIClient *)apiClient {
    _yoAPIClient = apiClient;
}

#pragma mark - Properties

- (void)setUserHasSentAnInAppYo:(BOOL)userHasSentAnInAppYo {
    NSString *unqueUserKeyForProperty = [self getUniqueUserKeyForStoredProperty:NSStringFromSelector(@selector(userHasSentAnInAppYo))];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
    [defaults setObject:@(userHasSentAnInAppYo) forKey:unqueUserKeyForProperty];
    [defaults synchronize];
}

- (BOOL)userHasSentAnInAppYo {
    NSString *unqueUserKeyForProperty = [self getUniqueUserKeyForStoredProperty:NSStringFromSelector(@selector(userHasSentAnInAppYo))];
    return [[[[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY] objectForKey:unqueUserKeyForProperty] boolValue];
}

- (NSString *)getUniqueUserKeyForStoredProperty:(NSString *)property {
    return MakeString(@"YoManagerKey%@For%@", property.capitalizedString, @"NoUserAvailable");
}

#pragma mark - Yo

- (void)yo:(NSString *)username completionHandler:(YoResponseBlock)block {
    [self yo:username contextParameters:@{} completionHandler:block];
}

- (void)yo:(NSString *)username withCurrentLocation:(BOOL)withCurrentLocation completionHandler:(YoResponseBlock)block {
    if ( ! withCurrentLocation) {
        [self yo:username completionHandler:block];
    }
    else if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        [[YoApp currentSession] updateCurrentLocationWithCompletionBlock:^(BOOL success) {
            [self yo:username withLocation:[[YoLocationManager sharedInstance] cachedLocation] completionHandler:block];
        }];
    }
    else {
#ifndef IS_APP_EXTENSION
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            [[YoAlertManager sharedInstance] showAlertWithTitle:@"Couldn't fetch location 😔 Please enable location"];
        }
        else {
            [YoLocalPushNotificationAssistant presentLocalNotificationWithText:@"Couldn't fetch location 😔 Please enable location" actionDic:nil];
        }
        if (block) {
            block(YoResultFailed, 000, nil);
        }
#endif
    }
}

- (void)yo:(NSString *)username withLocation:(CLLocation *)location completionHandler:(YoResponseBlock)block {
    CLLocationCoordinate2D coordinate = location.coordinate;
    if (location.coordinate.latitude == 0.0 && location.coordinate.longitude == 0.0) {
#ifndef IS_APP_EXTENSION
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            [[YoAlertManager sharedInstance] showAlertWithTitle:@"Couldn't fetch location 😔"];
        }
        else {
            [YoLocalPushNotificationAssistant presentLocalNotificationWithText:@"Couldn't fetch location 😔" actionDic:nil];
        }
        return;
#endif
    }
    NSDictionary *extraParameters = @{@"location": MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude)};
    [self yo:username contextParameters:extraParameters completionHandler:block];
}

- (void)yo:(NSString *)username contextParameters:(NSDictionary *)contextParameters completionHandler:(YoResponseBlock)block {
    NSMutableDictionary *params = [@{@"to": username,
                                     @"username": username,
                                     @"sound": YO_SOUND_FILE,
                                     @"udid": [YOUDID value] } mutableCopy];
    
    [params addEntriesFromDictionary:contextParameters];
    
    [self sendYoWithParams:params completionHandler:block];
}

- (void)yo:(YoModelObject *)object withContextParameters:(NSDictionary *)parameters completionHandler:(YoResponseBlock)block
{
    NSMutableDictionary *params = [@{
                                     @"sound": YO_SOUND_FILE,
                                     @"udid": [YOUDID value] } mutableCopy];
    
    if (object.username) {
        params[@"username"] = object.username;
    }
    if (object.phoneNumber) {
        params[@"phone_number"] = object.phoneNumber;
    }
    if (object.fullName && ! [object.fullName isEqualToString:object.username]) {
        params[@"name"] = object.fullName;
    }
    
    [params addEntriesFromDictionary:parameters];
    
    [self sendYoWithParams:params completionHandler:block];
}

#pragma mark - Final Yo Call

- (void)sendYoWithParams:(NSDictionary *)params completionHandler:(YoResponseBlock)block {
    NSString *username = params[@"username"];
    [[YoApp currentSession].yoAPIClient POST:@"rpc/yo"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       // succeess
                       DDLogWarn(@"Yo sent to %@", username);
                       dispatch_async(dispatch_get_main_queue(), ^{
                           if (block) {
                               block(YES, operation.response.statusCode, operation.responseObject);
                           }
                       });
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           DDLogError(@"Failed Yo: %@", [error localizedDescription]);
                           if (operation.response.statusCode == 404) { // no such user
                               [[NSNotificationCenter defaultCenter] postNotificationName:YoNote_UsernameDoesNotExist object:nil userInfo:params];
                           }
                           else if (operation.response.statusCode == 403) {
                               [[NSNotificationCenter defaultCenter] postNotificationName:YoNote_UsernameHasCurrentUserBlocked object:nil userInfo:params];
                           }
                           
                           NS_DURING
                           NSString *errorText = nil;
                           
                           if ([operation.responseObject[@"error"][@"message"] length])
                               errorText = [[operation.responseObject objectForKey:@"error"] objectForKey:@"message"];
                           
                           if (operation.response.statusCode == 404) {
                               errorText = NSLocalizedString(@"No Such User", nil);
                           }
#ifndef IS_APP_EXTENSION
                           NSString *failedDescription = MakeString(@"%@%@",errorText?@": ":@"", errorText?:@"");
                           NSString *failedUsernameText = MakeString(@" (%@)", username);
                           
                           [YoLocalPushNotificationAssistant presentLocalNotificationWithText:MakeString(NSLocalizedString(@"Failed Yo%@", nil), [failedDescription length]?failedDescription:failedUsernameText) url:nil];
#endif
                           NS_HANDLER
#ifndef IS_APP_EXTENSION
                           [YoLocalPushNotificationAssistant presentLocalNotificationWithText:MakeString(@"%@ (%@)", NSLocalizedString(@"Failed Yo", nil), username) url:nil];
#endif
                           NS_ENDHANDLER
                           
                           if (block) {
                               block(NO, operation.response.statusCode, operation.responseObject);
                           }
                       });
                   }];
}

@end

