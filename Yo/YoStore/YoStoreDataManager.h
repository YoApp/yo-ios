//
//  YoStoreDataManager.h
//  Yo
//
//  Created by Peter Reveles on 3/26/15.
//
//

#import <Foundation/Foundation.h>

@class YoStoreDataManager;
@class YoStoreCategory;

/**
 Responsible for loading Yo Store data. The provides the ability to load store
 data idepently from store UI.
 */
@interface YoStoreDataManager : NSObject

+ (instancetype)sharedInstance;

#pragma mark - Management

- (void)update;

- (void)clearData;

#pragma mark - Data Access

- (NSUInteger)itemCount;

- (YoStoreItem *)itemAtIndex:(NSInteger)index;

- (YoStoreItem *)itemWithUsername:(NSString *)username;

- (NSArray *)fetchItemsMathcingPredicate:(NSPredicate *)predicate;

- (void)getBannerImageForStoreItem:(YoStoreItem *)item withCompletionBlock:(void (^)(UIImage *bannerImage))block;

- (NSArray *)getFeauturedStoreBanners;

@property (nonatomic, readonly) NSArray *storeBanners;

@property (nonatomic, readonly) NSArray *storeCategories;

@property (nonatomic, readonly) NSArray *featuredStoreItems;

#pragma mark - Settings

@property (nonatomic, readonly) YoLoadingStatus loadingStatus;

@property (nonatomic, readonly) CLLocation *location;

@end
