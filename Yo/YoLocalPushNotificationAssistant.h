//
//  YoLocalPushNotificationManager.h
//  Yo
//
//  Created by Peter Reveles on 4/21/15.
//
//

#import <Foundation/Foundation.h>

@interface YoLocalPushNotificationAssistant : NSObject

+ (void)presentLocalNotificationWithText:(NSString *)text
                                     url:(NSURL *)url NS_EXTENSION_UNAVAILABLE("(void)presentLocal... cannot present notification in app extension");

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text NS_EXTENSION_UNAVAILABLE("(void)presentLocal... cannot present notification in app extension");

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                                   url:(NSURL *)url NS_EXTENSION_UNAVAILABLE("(void)presentLocal... cannot present notification in app extension");

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                              location:(NSString *)location NS_EXTENSION_UNAVAILABLE("(void)presentLocal... cannot present notification in app extension");

+ (void)presentLocalYoNotificationFrom:(NSString *)yoUsername
                           displayText:(NSString *)text
                              photoURL:(NSURL *)photoURL NS_EXTENSION_UNAVAILABLE("(void)presentLocal... cannot present notification in app extension");

/**
 Ex. {"type":"YoActionAddContact", "title": "Open", "dismiss_title": "Nah", "params": {"username": "PETERREVEL"}}
 **/
+ (void)presentLocalNotificationWithText:(NSString *)text
                               actionDic:(NSDictionary *)actionDic;

@end
