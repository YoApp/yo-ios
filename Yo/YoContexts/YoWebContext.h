//
//  YoWebContext.h
//  Yo
//
//  Created by Or Arbel on 7/6/15.
//
//

#define YoNotificationFetchedWebContext @"YoNotificationFetchedWebContext"
#define YoNotificationWebContextFailed @"YoNotificationWebContextFailed"

#import "YoContextObject.h"

@interface YoWebContext : YoContextObject

@property(nonatomic, assign) BOOL isLoaded;

- (void)fetch;

@end
