//
//  YoContactManager.m
//  Yo
//
//  Created by Peter Reveles on 11/5/14.
//
//

#import "YoContactManager.h"
#import "YoManager.h"
#import "YoMainController.h"
#import "YoStoreItem.h"
#import "YoModelObject.h"

#define Yo_CONTACTS_KEY @"contacts"

#define Yo_BLOCKED_CONTACTS_KEY @"yo_blocked_contacts"

typedef NS_ENUM(NSUInteger, YoUserDeletionReason) {
    YoUserDeletionReason_NoSuchUser,
    YoUserDeletionReason_Blocked,
};

@interface YoContactManager ()
@property (nonatomic, strong) NSMutableArray *list; // @or: an array of YoModelObjects
@property (nonatomic, strong) NSMutableArray *usernames; // @or: an array of NSStrings of the usernames from the list
@property (nonatomic, strong) NSMutableArray *services;
@property (nonatomic, strong) YoAPIClient *yoAPIClient;
@property (nonatomic, strong) NSMutableDictionary *usernameToObjectDic;
@property (nonatomic, strong) NSArray *subscriptionsUsernames;
@property (nonatomic, strong) NSArray *subscriptionsObjects;
@property (nonatomic, assign) BOOL isUpdatingSubscriptionsUsernames;
@end

@implementation YoContactManager

- (id)init {
    if (self = [super init]) {
        [self performSelectorInBackground:@selector(loadStoredList) withObject:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)applicationDidEnterBackgroundNotification {
    [self storeContacts];
}

#pragma mark - Lazy Loading

- (YoModelObject *)objectForUsername:(NSString *)username {
    return [self.usernameToObjectDic objectForKey:username];
}

- (YoModelObject *)objectForDictionary:(NSDictionary *)dict {
    if (dict[@"username"] == nil) {
        return nil;
    }
    YoModelObject *object = [self.usernameToObjectDic objectForKey:dict[@"username"]];
    if ( ! object) {
        object = [YoModelObject objectFromDictionary:dict];
        self.usernameToObjectDic[dict[@"username"]] = object;
    }
    return object;
}

- (NSMutableDictionary *)usernameToObjectDic {
    if (!_usernameToObjectDic) {
        _usernameToObjectDic = [[NSMutableDictionary alloc] init];
    }
    return _usernameToObjectDic;
}

- (NSArray *)loadStoredList {
    return [self getStoredObjectForKey:@"list"];
}

- (id)getStoredObjectForKey:(NSString *)key {
#ifdef IS_APP_EXTENSION
    // grab contacts from shared resource with containing app
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#endif
    NSData *data = [defaults objectForKey:@"list"];
    self.list = [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    if ( ! self.list) {
        self.list = [NSMutableArray new];
    }
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    for (YoModelObject *object in self.list) {
        if ([object isKindOfClass:[YoModelObject class]] && object.username) {
            self.usernameToObjectDic[object.username] = object;
        }
        else {
            [objectsToRemove addObject:object];
        }
    }
    [self.list removeObjectsInArray:objectsToRemove];
    
    self.usernames = [[self.list valueForKey:@"username"] mutableCopy];
    [defaults setObject:self.usernames forKey:Yo_CONTACTS_KEY];
    [defaults synchronize];
    
    NSArray *object = [defaults arrayForKey:key];
    return object;
}

- (void)storeContacts {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NSMutableArray *listCopy = [self.list copy]; // @or: prevent crash of mutating while updating
        
        // @or: store list (YoModelObjects)
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:listCopy];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.usernames forKey:Yo_CONTACTS_KEY];
        [defaults setObject:encodedObject forKey:@"list"];
        [defaults synchronize];
        
        NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
        [groupDefaults setObject:self.usernames forKey:Yo_CONTACTS_KEY];
        [groupDefaults setObject:encodedObject forKey:@"list"];
        [groupDefaults synchronize];
    });
    
}

- (NSMutableArray *)services{
    if (!_services) {
        _services = [NSMutableArray new];
    }
    return _services;
}

#pragma mark - Life Cycle

- (void)grantAPIAccressWithClient:(YoAPIClient *)yoAPIClient{
    _yoAPIClient = yoAPIClient;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (NSArray *)allUsernames{
    return self.usernames;
}

- (NSArray *)justServices{
    return [self.services copy];
}

- (void)clearStoredData{
    self.list = [NSMutableArray new];
    self.usernames = [NSMutableArray new];
    self.services = [NSMutableArray new];
    self.usernameToObjectDic = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"list"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:Yo_CONTACTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (IS_OVER_IOS(7.0)) {
        NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:Yo_GROUP_KEY];
        [groupDefaults removeObjectForKey:Yo_CONTACTS_KEY];
        [groupDefaults synchronize];
    }
}

- (void)updateContactsWithCompletionBlock:(void (^)(bool success))block{
    [self.yoAPIClient POST:@"rpc/list_contacts"
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                           
                           NS_DURING
                           
                           NSArray *list = responseObject[Yo_CONTACTS_KEY];
                           
                           self.list = [NSMutableArray array];
                           for (NSDictionary *rawObject in list) {
                               YoModelObject *yoObject = self.usernameToObjectDic[rawObject[@"username"]];
                               if (yoObject) {
                                   [yoObject updateWithDictionary:rawObject];
                               }
                               else {
                                   yoObject = [YoModelObject objectFromDictionary:rawObject];
                               }
                               [self.list addObject:yoObject];
                               self.usernames = [[self.list valueForKey:@"username"] mutableCopy];
                               self.usernameToObjectDic[yoObject.username] = yoObject;
                               [self storeContacts];
                           }
                           
                           if (block) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   block(YES);
                               });
                           }
                           
                           NS_HANDLER
                           if (block) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   block(NO);
                               });
                           }
                           NS_ENDHANDLER
                       });
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogError(@"get_contacts failed with %@", error);
                       if (block) block(NO);
                   }];
}

- (void)fetchProfileForUsername:(NSString *)username withCompletionBlock:(void (^)(NSDictionary *object))block{
    [self.yoAPIClient POST:@"rpc/get_profile"
                parameters:@{Yo_USERNAME_KEY: username}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       self.usernames = [[self.list valueForKey:@"username"] mutableCopy];
                       self.usernameToObjectDic[username] = [YoModelObject objectFromDictionary:responseObject];
                       if (block) {
                           block(responseObject);
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) {
                           block(nil);
                       }
                   }];
}

#pragma mark - Private Methods

- (void)filterContacts:(NSMutableArray *)contacts{
    NS_DURING
    [contacts filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* evaluatedObject, NSDictionary *bindings) {
        if (evaluatedObject.length > 0) {
            return YES;
        }
        return NO;
    }]];
    NS_HANDLER
    NS_ENDHANDLER
}

#pragma mark - Utility Methods

- (void)addContactWithUsername:(NSString *)username {
    if (![username length]) return;
    YoUser *contactForUsername = [YoUser new];
    contactForUsername.username = username;
    self.usernameToObjectDic[username] = contactForUsername;
}

- (void)addObject:(YoUser *)object withCompletionBlock:(YoResponseBlock)block {
    NS_DURING
    
    if ([self.list containsObject:object]) {
        [self.list removeObject:object];
    }
    [self.list insertObject:object atIndex:0];
    self.usernames = [[self.list valueForKey:@"username"] mutableCopy];
    
    self.usernameToObjectDic[object.username] = object;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (object.username.length > 0) {
        params[@"username"] = object.username;
    }
    if (object.phoneNumber) {
        params[@"phone_number"] = object.phoneNumber;
    }
    if (object.fullName) {
        params[@"name"] = object.fullName;
    }
    
    [self.yoAPIClient POST:@"rpc/add_contact"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       [object updateWithDictionary:responseObject[@"added"]];
                       [[NSNotificationCenter defaultCenter] postNotificationName:@"ObjectChanged" object:object];
                       NS_HANDLER
                       
                       NS_ENDHANDLER
                       if (block) block(YoResultSuccess, operation.response.statusCode, responseObject);
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                   }];
    NS_HANDLER
    DDLogError(@"%@", localException);
    NS_ENDHANDLER
}

- (void)removeObject:(YoModelObject *)object withCompletionBlock:(YoResponseBlock)block {
    [self removeObject:object localObjectOnly:NO withCompletionBlock:block];
}

- (void)removeObject:(YoModelObject *)object localObjectOnly:(BOOL)localObjectOnly withCompletionBlock:(YoResponseBlock)block {
    
    [self.list removeObject:object];
    [self.usernames removeObject:object.username];
    [self.usernameToObjectDic removeObjectForKey:object.username];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationListChanged object:nil];
    
    if (!localObjectOnly) {
        [self.yoAPIClient POST:@"/rpc/remove_contact"
                    parameters:@{Yo_USERNAME_KEY: object.username}
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           if (block) {
                               block(YoResultSuccess, operation.response.statusCode, responseObject);
                           }
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           if (block) {
                               block(YoResultFailed, operation.response.statusCode, operation.responseObject);
                           }
                       }];
    }
    else {
        if (block) {
            block(YoResultFailed, 000, nil);
        }
    }
}

- (void)promoteObjectToTopWithUsername:(NSString *)username {
    
    NSInteger index = [self.usernames indexOfObject:username];
    if (index == NSNotFound) {
        [self fetchProfileForUsername:username withCompletionBlock:^(NSDictionary *rawObject) {
            if (rawObject) {
                YoModelObject *object = [YoModelObject objectFromDictionary:rawObject];
                [self promoteObjectToTop:object];
            }
            else {
                DDLogError(@"Failed to fetch user with username: %@", username);
            }
        }];
    }
    else {
        [self promoteObjectToTop:self.list[index]];
    }
}

- (void)promoteObjectToTop:(YoModelObject *)object {
    
    if ( ! object) {
        DDLogError(@"object is nil");
    }
    
    NSInteger index = [self.list indexOfObject:object];
    if (index != NSNotFound) {
        
        NSString *username = object.username;
        
        [self.usernames removeObject:username];
        [self.usernames insertObject:username atIndex:0];
        
        [self.list removeObjectAtIndex:index];
        [self.list insertObject:object atIndex:0];
        
    }
    else {
        [self.list insertObject:object atIndex:0];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationListChanged object:nil];
}

- (void)fetchStatusesForObjects:(NSArray *)objects withCompletionHandler:(void (^)(NSArray *statuses))handler {
    [self.yoAPIClient POST:@"rpc/get_contacts_status"
                parameters:@{@"usernames": [objects valueForKey:@"username"]}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NS_DURING
                       NSArray *statuses = [operation.responseObject objectForKey:@"contacts"];
                       
                       for (NSDictionary *status in statuses) {
                           YoUser *user = [self.usernameToObjectDic objectForKey:status[@"username"]];
                           if (user) {
                               user.lastYoStatus = status[@"status"];
                               user.lastYoDate = [NSDate dateWithTimeIntervalSince1970:
                                                  [[status objectForKey:@"time"] doubleValue] / pow(10, 6)];
                           }
                       }
                       
                       if (handler) handler(statuses);
                       NS_HANDLER
                       DDLogError(@"%@", localException);
                       if (handler) handler(nil);
                       NS_ENDHANDLER
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       DDLogWarn(@"Failed to pull statuses: %@", error);
                       if (handler) handler(nil);
                   }];
}

#pragma mark - Blocked Contacts

- (void)blockObject:(YoModelObject *)object withCompletionBlock:(void (^)(BOOL success))block{
    [self.yoAPIClient POST:@"rpc/block"
                parameters:@{@"username": object.username}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       [self deleteSubscriptionUsername:object.username];
                       [self removeObject:object localObjectOnly:YES withCompletionBlock:^(YoResult result, NSInteger statusCode, id responseObject) {
                           [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationListChanged object:nil];
                           if (block) {
                               block(YES);
                           }
                       }];
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) {
                           block(NO);
                       }
                   }];
}

- (void)unblockObject:(YoModelObject *)object withCompletionBlock:(void (^)(BOOL success))block
{
    [self.yoAPIClient POST:@"rpc/unblock"
                parameters:@{@"username": object.username}
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       if (block) block(YES);
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if (block) block(NO);
                   }];
}

#pragma mark - Services

- (void)unsubscribeFromServiceWithUsername:(NSString *)username withCompletionBlock:(void (^)(BOOL success))block {
    void (^relayResult)(BOOL success) = ^(BOOL success) {
        if (block) {
            block(success);
        }
    };
    if (![username length]) {
        relayResult(NO);
    }
    
    YoUser *user = [YoUser new];
    user.username = username;
    [[[YoUser me] contactsManager] blockObject:user
                           withCompletionBlock:^(BOOL result) {
                               if (result == YoResultSuccess) {
                                   [self deleteSubscriptionUsername:username];
                               }
                               if (block) {
                                   block(result == YoResultSuccess);
                               }
                           }];
}

- (void)addSubscriptionUsername:(NSString *)username {
    if (self.subscriptionsUsernames == nil) {
        self.subscriptionsUsernames = [[NSArray alloc] initWithObjects:username, nil];
    }
    
    NSMutableArray *mutableSubscriptionUsernames = [self.subscriptionsUsernames mutableCopy];
    [mutableSubscriptionUsernames addObject:username];
    self.subscriptionsUsernames = mutableSubscriptionUsernames;
}

- (void)deleteSubscriptionUsername:(NSString *)username {
    NSInteger indexOfUsername = [self.subscriptionsUsernames indexOfObject:username];
    if (indexOfUsername != NSNotFound) {
        NSMutableArray *mutableSubscriptionUsernames = [self.subscriptionsUsernames mutableCopy];
        [mutableSubscriptionUsernames removeObjectAtIndex:indexOfUsername];
        self.subscriptionsUsernames = mutableSubscriptionUsernames;
    }
}

- (void)updateSubscriptionsWithCompletionBlock:(void (^)())completionBlock {
    void (^reply)() = ^() {
        if (completionBlock) {
            completionBlock();
        }
    };
    
    [self.yoAPIClient POST:@"rpc/get_subscriptions_objects"
                parameters:nil
                   success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         id subscriptionData = [responseObject valueForKey:@"subscriptions"];
         if ([subscriptionData isKindOfClass:[NSArray class]]) {
             self.subscriptionsObjects = subscriptionData;
             NSMutableArray *subscriptionsUsernames = [NSMutableArray array];
             for (NSDictionary *subscription in subscriptionData) {
                 if (subscription[@"username"]) {
                     [subscriptionsUsernames addObject:subscription[@"username"]];
                 }
             }
             self.subscriptionsUsernames = subscriptionsUsernames;
         }
         else {
             DDLogWarn(@"<Yo> %@ - WANRING failed to update subcriptinos due to bad response",
                       NSStringFromClass([self class]));
         }
         reply();
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         reply();
     }];
}

- (void)subscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block {
    [[YoManager sharedInstance] yo:service.username
                 completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                     if (result == YoResultSuccess) {
                         [self addSubscriptionUsername:service.username];
                     }
                     if (block) {
                         block(result == YoResultSuccess);
                     }
                 }];
}

@end
