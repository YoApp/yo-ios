//
//  YoDataAccessManager.h
//  Yo
//
//  Created by Peter Reveles on 6/15/15.
//
//

#import <Foundation/Foundation.h>

@interface YoDataAccessManager : NSObject

+ (YoDataAccessManager *)sharedDataManager;

@property (nonatomic, strong) NSString *accessToken;

- (void)fetchContactsListWithCompletionHandler:(void(^)(NSArray *list, NSError *error))handler;

- (void)fetchBlockedListWithCompletionHandler:(void(^)(NSArray *blockedList, NSError *error))handler;

- (void)fetchBannerWithUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(NSDictionary *bannerDictionary, NSError *error))handler;

- (void)fetchContextConfigurationWithCompletionHandler:(void (^)(NSDictionary *configuration, NSError *error))handler;

- (void)acknowledgeBannerWithID:(NSString *)bannerID result:(NSString *)result;

- (void)fetchMagicWithCompletionHandler:(void (^)(id responseObject, NSError *error))handler;

- (void)setMagic:(id)payload completionBlock:(void (^)(id reponseObject, NSError *error))block;

@end
