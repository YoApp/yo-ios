//
//  YoLocalPushNotificationManager.m
//  Yo
//
//  Created by Peter Reveles on 4/21/15.
//
//

#import "YoLocalPushNotificationAssistant.h"
#import "Yo.h"

@implementation YoLocalPushNotificationAssistant

#ifndef IS_APP_EXTENSION

+ (void)presentLocalNotificationWithText:(NSString *)text actionDic:(NSDictionary *)actionDic {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.fireDate = [NSDate date];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = text;
    NSMutableDictionary *userinfo = [@{@"aps" :     @{
                                               @"alert" : text
                                               },
                                       @"header" : text
                                       } mutableCopy];
    if (actionDic) {
        userinfo[@"action"] = actionDic;
    }
    
    // add date
    NSString *creationDate = MakeString(@"%f", [[NSDate date] timeIntervalSince1970]*pow(10, 6));
    userinfo[Yo_CREATION_DATE_KEY] = creationDate;
    
    localNotification.userInfo = userinfo;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

+ (void)presentLocalNotificationWithText:(NSString *)text url:(NSURL *)url {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.fireDate = [NSDate date];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = text;
    NSMutableDictionary *userinfo = [@{@"aps" :     @{
                                               @"alert" : text,
//                                               @"sound" : @"yo.mp3", @or: local notification should not play sound
                                               },
                                       @"header" : text
                                       } mutableCopy];
    if (url) {
        userinfo[Yo_LINK_KEY] = url.absoluteString;
        userinfo[@"delayUntilOpen"] = @(YES);
    }
    
    // add date
    NSString *creationDate = MakeString(@"%f", [[NSDate date] timeIntervalSince1970]*pow(10, 6));
    userinfo[Yo_CREATION_DATE_KEY] = creationDate;
    
    localNotification.userInfo = userinfo;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                                   url:(NSURL *)url
                              location:(NSString *)location photoURL:(NSURL *)photoURL {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.fireDate = [NSDate date];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = text;
    NSMutableDictionary *userinfo = [@{@"aps":@{@"alert" : text,
                                              //  @"sound" : @"yo.mp3"
                                                },
                                       @"header" : text
                                       } mutableCopy];
    
    NSString *categoryName = nil;
    
    if (url) {
        userinfo[Yo_LINK_KEY] = url.absoluteString;
        userinfo[@"delayUntilOpen"] = @(YES);
        categoryName = kYoCategoryLink;
    }
    else if ([location length]) {
        userinfo[Yo_LOCATION_KEY] = location;
        userinfo[@"delayUntilOpen"] = @(YES);
        categoryName = kYoCategoryLocation;
    }
    else if (photoURL) {
        userinfo[Yo_LINK_KEY] = photoURL.absoluteString;
        userinfo[@"delayUntilOpen"] = @(YES);
        categoryName = kYoCategoryPhoto;
    }
    else {
        categoryName = kYoCategoryJustYo;
    }
    
    // add date
    NSString *creationDate = MakeString(@"%f", [[NSDate date] timeIntervalSince1970]*pow(10, 6));
    userinfo[Yo_CREATION_DATE_KEY] = creationDate;
    
    NSString *localYoID = [self genUniqueYoID];
    userinfo[Yo_ID_KEY] = localYoID;
    
    if ([yoUsername length]) {
        userinfo[Yo_SENDER_KEY] = yoUsername;
    }
    
    localNotification.userInfo = userinfo;
    localNotification.soundName = @"yo.mp3";
    if (IS_OVER_IOS(8.0)) {
        localNotification.category = categoryName;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text {
    DDLogWarn(@"Dispatching local Yo Notification");
    [self presentLocalYoNotificationFrom:yoUsername
                             displayText:text
                                     url:nil
                                location:nil
                                photoURL:nil];
}

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                                   url:(NSURL *)url {
    DDLogWarn(@"Dispatching local Yo URL Notification");
    [self presentLocalYoNotificationFrom:yoUsername
                             displayText:text
                                     url:url
                                location:nil
                                photoURL:nil];
};

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                              location:(NSString *)location {
    DDLogWarn(@"Dispatching local Yo Location Notification");
    [self presentLocalYoNotificationFrom:yoUsername
                             displayText:text
                                     url:nil
                                location:location
                                photoURL:nil];
};

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                              photoURL:(NSURL *)photoURL {
    DDLogWarn(@"Dispatching local Yo Photo Notification");
    [self presentLocalYoNotificationFrom:yoUsername
                             displayText:text
                                     url:nil
                                location:nil
                                photoURL:photoURL];
}

#endif

+ (NSString *)genUniqueYoID {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uniqueYoID = (__bridge_transfer NSString *)uuidStringRef;
    uniqueYoID = MakeString(@"%@-%@", YoLocalYoIDPrefix, uniqueYoID);
    return uniqueYoID;
}

@end
