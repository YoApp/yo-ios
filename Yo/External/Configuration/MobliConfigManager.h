//
//  MobliConfigManager.h
//  Mobli
//
//  Created by Or Arbel on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define kKeyCachedCopyLifetime          @"CachedCopyLifetime"
#define kNotificationConfigDidUpdate    @"kNotificationConfigDidUpdate"
@class SMXMLElement;

@interface MobliConfigManager : NSObject

+ (MobliConfigManager *)sharedInstance;
+ (void)cleanupOnVersionUpdate;

- (id)keyValue:(NSString *)key forNode:(NSString *)aNode;
- (id)keySection:(NSString *)key forNode:(NSString *)aNode;

- (id)miscValueOfKey:(NSString *)key;

- (NSTimeInterval)yoLinkLongTapDuration;
- (NSTimeInterval)yoLinkInAppPushViewDuration;

@end
