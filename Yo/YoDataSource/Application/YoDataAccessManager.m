//
//  YoDataAccessManager.m
//  Yo
//
//  Created by Peter Reveles on 6/15/15.
//
//

#import "YoDataAccessManager.h"
#import "YoConfigManager.h"

@interface YoDataAccessManager ()
@property (nonatomic, strong) YoAPIClient *APIClient;
@end

@implementation YoDataAccessManager

+ (YoDataAccessManager *)sharedDataManager {
    static YoDataAccessManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        // setup
        _APIClient = [[YoAPIClient alloc] init];
    }
    return self;
}

- (void)setAccessToken:(NSString *)accessToken {
    _accessToken = accessToken;
    self.APIClient.accessToken = accessToken;
}

#pragma mark - Fetch Requests

- (void)fetchContactsListWithCompletionHandler:(void(^)(NSArray *list, NSError *error))handler
{
    [self.APIClient POST:@"rpc/list_contacts"
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     @try {
                         NSArray *rawList = responseObject[@"contacts"];
                         NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:rawList.count];
                         for (NSDictionary *rawObject in rawList) {
                             YoModelObject *yoObject = [YoModelObject objectFromDictionary:rawObject];
                             [list addObject:yoObject];
                         }
                         
                         if (handler) {
                             handler(list, nil);
                         }
                     }
                     @catch (NSException *exception) {
                         if (handler) {
                             handler(nil, nil);
                         }
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     DDLogError(@"get_contacts failed with %@", error);
                     if (handler != nil) {
                         handler(nil, error);
                     }
                 }];
}

- (void)fetchBlockedListWithCompletionHandler:(void(^)(NSArray *blockedList, NSError *error))handler
{
    [self.APIClient POST:@"rpc/get_blocked_objects"
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     @try {
                         NSArray *rawList = responseObject[@"contacts"];
                         NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:rawList.count];
                         for (NSDictionary *rawObject in rawList) {
                             YoModelObject *yoObject = [YoModelObject objectFromDictionary:rawObject];
                             [list addObject:yoObject];
                         }
                         
                         if (handler) {
                             handler(list, nil);
                         }
                     }
                     @catch (NSException *exception) {
                         if (handler) {
                             handler(nil, nil);
                         }
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     DDLogError(@"get_contacts failed with %@", error);
                     if (handler != nil) {
                         handler(nil, error);
                     }
                 }];
}

- (void)fetchBannerWithUserInfo:(NSDictionary *)userInfo
              completionHandler:(void (^)(NSDictionary *bannerDictionary, NSError *error))handler
{
    [self.APIClient POST:@"rpc/get_banner"
              parameters:userInfo
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     @try {
                         NSDictionary *bannerDictionary = responseObject;
                         
                         if (handler) {
                             handler(bannerDictionary, nil);
                         }
                     }
                     @catch (NSException *exception) {
                         if (handler) {
                             handler(nil, nil);
                         }
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     //DDLogError(@"get_banners failed with %@", error);
                     if (handler != nil) {
                         handler(nil, error);
                     }
                 }];
}

- (void)fetchContextConfigurationWithCompletionHandler:(void (^)(NSDictionary *configuration, NSError *error))handler
{
    [self.APIClient POST:@"rpc/get_context_configuration"
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     @try {
                         NSDictionary *configuration = responseObject;
                         
                         if (handler) {
                             handler(configuration, nil);
                         }
                         
                     }
                     @catch (NSException *exception) {
                         [[YoConfigManager sharedInstance] updateWithCompletionHandler:^(BOOL sucess) {
                             handler([[YoConfigManager sharedInstance] sampleContextConfiguration], nil);
                         }];
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     DDLogError(@"get_contexts failed with %@", error);
                    [[YoConfigManager sharedInstance] updateWithCompletionHandler:^(BOOL sucess) {
                         handler([[YoConfigManager sharedInstance] sampleContextConfiguration], nil);
                     }];
                 }];
}

- (void)acknowledgeBannerWithID:(NSString *)bannerID result:(NSString *)result
{
    [self.APIClient POST:@"rpc/banner_ack"
              parameters:@{@"banner_id":bannerID,
                           @"result":result}
                 success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     DDLogError(@"banner_ack failed with %@", error);
                 }];
}

- (void)fetchMagicWithCompletionHandler:(void (^)(id responseObject, NSError *error))handler {
    if (handler == nil) {
        return;
    }
    
    [self.APIClient POST:@"rpc/get_magic"
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         DDLogDebug(@"Successfully got magic.");
         handler(responseObject, nil);
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         DDLogDebug(@"Failed to get magic.");
         handler(nil, error);
     }];
}

- (void)setMagic:(id)payload completionBlock:(void (^)(id reponseObject, NSError *error))block {
    [self.APIClient POST:@"rpc/set_magic"
              parameters:payload
                 success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         DDLogDebug(@"Successfully set magic.");
         if (block) {
             block(responseObject, nil);
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         DDLogDebug(@"Failed to set magic.");
         if (block) {
             block(operation.responseObject, error);
         }
     }];
}

@end
