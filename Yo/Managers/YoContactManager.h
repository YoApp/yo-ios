//
//  YoContactManager.h
//  Yo
//
//  Created by Peter Reveles on 11/5/14.
//
//

@class YoModelObject;
@class YoContacts;
@class YoStoreItem;

#define kNotificationListChanged @"kNotificationListChanged"

@interface YoContactManager : NSObject

- (void)grantAPIAccressWithClient:(YoAPIClient *)yoAPIClient;

- (void)updateContactsWithCompletionBlock:(void (^)(bool success))block;

- (YoModelObject *)objectForUsername:(NSString *)username;
- (YoModelObject *)objectForDictionary:(NSDictionary *)dict;

#pragma mark - Contacts

- (NSArray *)allUsernames;

- (NSMutableArray *)list; // of class YoUser or YoGroup

- (NSArray *)services;

- (void)addObject:(YoUser *)object withCompletionBlock:(YoResponseBlock)block;

- (void)removeObject:(YoModelObject *)object withCompletionBlock:(YoResponseBlock)block;
- (void)removeObject:(YoModelObject *)object localObjectOnly:(BOOL)localObjectOnly withCompletionBlock:(YoResponseBlock)block;

- (void)promoteObjectToTop:(YoModelObject *)object;

- (void)promoteObjectToTopWithUsername:(NSString *)username;

- (void)fetchStatusesForObjects:(NSArray *)objects withCompletionHandler:(void (^)(NSArray *statuses))handler;

- (void)fetchProfileForUsername:(NSString *)username withCompletionBlock:(void (^)(NSDictionary *object))block;

#pragma mark Subscriptions

@property (nonatomic, readonly) NSArray *subscriptionsObjects;
@property (nonatomic, readonly) NSArray *subscriptionsUsernames;

@property (nonatomic, readonly) BOOL isUpdatingSubscriptionsUsernames;

- (void)updateSubscriptionsWithCompletionBlock:(void (^)())completionBlock;

#pragma mark Blocked Contacts

@property (nonatomic, readonly) NSArray *blockedContacts;

- (void)blockObject:(YoModelObject *)object withCompletionBlock:(void (^)(BOOL success))block;

- (void)unblockObject:(YoModelObject *)object withCompletionBlock:(void (^)(BOOL success))block;

#pragma mark - Services

- (void)unsubscribeFromServiceWithUsername:(NSString *)username withCompletionBlock:(void (^)(BOOL success))block;

- (void)subscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block;

#pragma mark - Management

- (void)clearStoredData;

@end
