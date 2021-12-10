//
//  YoBannerStore.m
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import "YoBannerStore.h"
#import "CLLocation+LocationString.h"
#import "YoDataAccessManager.h"

@interface YoBannerStore ()
@property (strong, nonatomic) NSMutableDictionary *bannerCache;
@end

@implementation YoBannerStore

- (NSMutableDictionary *)bannerCache
{
    if (_bannerCache == nil) {
        _bannerCache = [[NSMutableDictionary alloc] init];
    }
    return _bannerCache;
}

- (void)getBannerDictionaryForOpenCount:(NSNumber *)openCount
                        currentContexts:(NSArray *)contexts
                               location:(NSString *)location
                  withCompletionHandler:(void (^)(NSDictionary *bannerDictionary, NSError *error))handler
{
    NSDictionary *userInfo = @{@"location":location,
                               @"open_count":openCount,
                               @"contexts":contexts};
    
    [[YoDataAccessManager sharedDataManager] fetchBannerWithUserInfo:userInfo
                                                   completionHandler:^(NSDictionary *bannerDictionary, NSError *error)
    {
        if (handler) {
            handler(bannerDictionary, error);
        }
    }];
}

- (void)getContextBannerForOpenCount:(NSInteger)openCount
                     currentContexts:(NSArray *)contexts
                            location:(CLLocation *)location
               withCompletionHandler:(void (^)(YoContextBanner *banner, NSError *error))handler
{
    NSString *locationString = [location getStringReresentation];
    locationString=locationString?:@"NULL";
    
    NSArray *contextIDs = [self getContextsIDsArrayFromContextObjects:contexts];
    
    NSString *bannerKey = [self getBannerCacheKeyFromOpenCount:@(openCount)
                                                      contexts:contextIDs
                                                      location:locationString];
    
    YoContextBanner *cachedBanner = self.bannerCache[bannerKey];
    if (cachedBanner != nil) {
        if (handler) {
            handler(cachedBanner, nil);
        }
        return;
    }
    
    [self getBannerDictionaryForOpenCount:@(openCount)
                          currentContexts:contextIDs
                                 location:locationString
                    withCompletionHandler:^(NSDictionary *bannerDictionary, NSError *error)
    {
        YoContextBanner * contextBanner = nil;
        if (bannerDictionary.count != 0) {
            contextBanner = [[YoContextBanner alloc] initWithDictionary:bannerDictionary];
            if (contextBanner != nil) {
                self.bannerCache[bannerKey] = contextBanner;
            }
        }
        
        if (handler) {
            handler(contextBanner, error);
        }
    }];
}

- (NSString *)getBannerCacheKeyFromOpenCount:(NSNumber *)openCount
                                    contexts:(NSArray *)contextIDs
                                    location:(NSString *)location
{
    return [NSString stringWithFormat:@"%@_%@_%@", openCount, contextIDs, location];
}

- (NSArray *)getContextsIDsArrayFromContextObjects:(NSArray *)contexts
{
    NSMutableArray *contextIDsArray = [[NSMutableArray alloc] initWithCapacity:contexts.count];
    for (YoContextObject *context in contexts) {
        [contextIDsArray addObject:[[context class] contextID]];
    }
    return contextIDsArray;
}

@end
