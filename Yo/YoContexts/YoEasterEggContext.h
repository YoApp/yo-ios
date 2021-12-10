//
//  YoEasterEggContext.h
//  Yo
//
//  Created by Or Arbel on 6/17/15.
//
//

#import "YoContextObject.h"

#define YoNotificationFetchedEasterEgg @"YoNotificationFetchedEasterEgg"
#define YoNotificationEasterEggFailed @"YoNotificationEasterEggFailed"

@interface YoEasterEggContext : YoContextObject

@property(nonatomic, assign) BOOL isLoaded;

- (void)fetchEasterEgg;

@end
