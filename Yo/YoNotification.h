//
//  YoNotification.h
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import <Foundation/Foundation.h>
#import "YoNotificationObjectProtocol.h"

typedef NS_ENUM(NSUInteger, YoNotificationTrigger) {
    YoNotificationTriggerOpenCount,
    YoNotificationTriggerDate,
    YoNotificationTriggerNavigation
};

#define Yo_OPEN_COUNT_THRESHOLD_KEY @"open_count_threshold"

@interface YoNotification : NSObject <YoNotificationObjectProtocal>

- (instancetype)initWithMessage:(NSString *)message tapBlock:(void (^)())tapBlock;

@property (nonatomic, readonly) NSString *message;

@property (copy, nonatomic) void (^tapBlock)();

@end
