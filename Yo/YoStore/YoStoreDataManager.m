//
//  YoStoreDataManager.m
//  Yo
//
//  Created by Peter Reveles on 3/26/15.
//
//

#import "YoStoreDataManager.h"
#import <CoreLocation/CLLocation.h>
#import "YOLocationManager.h"
#import "YoNetworkAssistant.h"
#import "YoStore.h"

@interface YoStoreDataManager ()
@property (nonatomic, strong) NSArray *featuredStoreItems;
@property (nonatomic, strong) NSArray *storeCategories;
@property (nonatomic, strong) NSArray *storeBanners;

@property (nonatomic, assign) YoLoadingStatus loadingStatus;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) NSMutableDictionary *itemIDToBannerImageDic; // <String, NSData>

@property (nonatomic, strong) AFHTTPRequestOperationManager *apiClient;
@property (nonatomic, strong) NSDictionary *usernameToItemDictionary;
@end

@implementation YoStoreDataManager

#pragma mark - Lazy Loading

- (NSMutableDictionary *)itemIDToBannerImageDic {
    if (!_itemIDToBannerImageDic) {
        _itemIDToBannerImageDic = [NSMutableDictionary new];
    }
    return _itemIDToBannerImageDic;
}

#pragma mark - Network

+ (instancetype)sharedInstance {
    static YoStoreDataManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //setup
        [self setupAPIClient];
        [self startListeners];
    }
    return self;
}

- (void)setupAPIClient {
    self.apiClient = [[YoApp currentSession] yoAPIClient];
}

- (void)startListeners {
    __weak YoStoreDataManager *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:YoAppDidUpdateUsersLocation
                                                      object:[YoApp currentSession]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
    {
        [weakSelf update];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data
#pragma mark Processing

- (void)processStoreItemsData:(NSArray *)itemsData {
    NSMutableArray *storeItems = [[NSMutableArray alloc] initWithCapacity:itemsData.count];
    NSMutableDictionary *usernameToItemDictionary = [[NSMutableDictionary alloc] initWithCapacity:itemsData.count];
    NSMutableArray *mutableStoreBanners = [NSMutableArray new];
    for (id itemData in itemsData) {
        YoStoreItem *item = [[YoStoreItem alloc] initWithItemData:itemData];
        [storeItems addObject:item];
        if (item.username.length) {
            usernameToItemDictionary[item.username] = item;
        }
        if (item.carouselPistureFileName.length) {
            YoStoreBanner *yoStoreBanner = [[YoStoreBanner alloc] initWithImageFileName:item.carouselPistureFileName
                                                                 andAssociatedStoreItem:item];
            yoStoreBanner.isFeatured = item.isInCarousel;
            [mutableStoreBanners addObject:yoStoreBanner];
        }
        [self updateAssetsForItem:item];
    }
    self.usernameToItemDictionary = [usernameToItemDictionary copy];
    self.storeBanners = [mutableStoreBanners copy];
    // sort all store items
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES];
    storeItems = [[storeItems sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    self.featuredStoreItems = [storeItems copy];
}

- (void)processStoreCategoriesData:(NSArray *)categoriesData {
    NSMutableArray *storeCategories = [[NSMutableArray alloc] initWithCapacity:categoriesData.count];
    for (id categoryData in categoriesData) {
        YoStoreCategory *category = [[YoStoreCategory alloc] initWithCategoryData:categoryData];
        [storeCategories addObject:category];
    }
    
    // sort all store items
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES];
    storeCategories = [[storeCategories sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    
    self.storeCategories = storeCategories;
}

- (void)updateAssetsForItem:(YoStoreItem *)item {
    // pull banner
    [self updateBannerImageForItem:item withCompletionBlock:nil];
}

- (void)updateBannerImageForItem:(YoStoreItem *)item withCompletionBlock:(void (^)(BOOL success))block {
    void (^relayResult)(BOOL success) = ^(BOOL success) {
        if (block) {
            block(success);
        }
    };
    if ([item.carouselPistureFileName length]) {
        NSURL *bannerURL = [YoStoreDataManager bannerURLForFileName:item.carouselPistureFileName];
        if (bannerURL) {
            __weak YoStoreDataManager *weakSelf = self;
            [YoNetworkAssistant pullImageFromURL:bannerURL withCompletionBlock:^(UIImage *image) {
                if (image) {
                    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                    weakSelf.itemIDToBannerImageDic[item.itemID] = imageData;
                    relayResult(YES);
                }
                else {
                    relayResult(NO);
                }
            }];
        }
        else {
            relayResult(NO);
        }
    }
    else {
        relayResult(NO);
    }
}

#pragma mark Access

- (NSUInteger)itemCount {
    return [self.featuredStoreItems count];
}

- (YoStoreItem *)itemAtIndex:(NSInteger)index {
    return [self.featuredStoreItems objectAtIndex:index];
}

- (YoStoreItem *)itemWithUsername:(NSString *)username {
    return self.usernameToItemDictionary[username];
}

- (NSArray *)fetchItemsMathcingPredicate:(NSPredicate *)predicate {
    return [self.featuredStoreItems filteredArrayUsingPredicate:predicate];
}

- (void)getBannerImageForStoreItem:(YoStoreItem *)item withCompletionBlock:(void (^)(UIImage *bannerImage))block {
    void (^relayResult)(NSData *bannerImageData) = ^(NSData *bannerImageData) {
        UIImage *storeItemBannerImage = [UIImage imageWithData:bannerImageData];
        if (block) {
            block(storeItemBannerImage);
        }
    };
    
    if ([item.itemID length]) {
        NSData *imageData = self.itemIDToBannerImageDic[item.itemID];
        if (imageData) {
            relayResult(imageData);
        }
        else {
            [self updateBannerImageForItem:item withCompletionBlock:^(BOOL success) {
                NSData *imageData = self.itemIDToBannerImageDic[item.itemID];
                relayResult(imageData);
            }];
        }
    }
    else {
        relayResult(nil);
    }
}

- (NSArray *)getFeauturedStoreBanners {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ = TRUE", NSStringFromSelector(@selector(isFeatured))];
    NSArray *featuredBanners = [self.storeBanners filteredArrayUsingPredicate:predicate];
    return featuredBanners;
}

#pragma mark - Internal Utility

+ (NSURL *)photoURLForForFileName:(NSString *)fileName {
    return [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/profile/%@", fileName)];
}

+ (NSURL *)bannerURLForFileName:(NSString *)fileName {
    return [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/carousel/%@", fileName)];
}

+ (NSURL *)screenshotURLForFilename:(NSString *)filename {
    return [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/screenshots/%@", filename)];
}

#pragma mark - Life

- (void)update {
    if (self.loadingStatus != YoLoadingStatusInProgress) {
        self.loadingStatus = YoLoadingStatusInProgress;
        if ([[YoApp currentSession] lastKnownLocation] != nil) {
            self.location = [[YoApp currentSession] lastKnownLocation];
        }
        NSString *endPoint = @"store/";
        if (self.location) {
            NSString *parameters = MakeString(@"lat=%f&lon=%f",
                                              self.location.coordinate.latitude,
                                              self.location.coordinate.longitude);
            endPoint = MakeString(@"%@?%@", endPoint, parameters);
        }
        if (self.apiClient == nil) {
            self.loadingStatus = YoLoadingStatusFailed;
            DDLogWarn(@"%@ | Failed to load store items due to missing API client",
                      NSStringFromClass([self class]));
        }
        else {
            [self.apiClient GET:endPoint
                         parameters:nil
                            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                NS_DURING
                                id storeItemsData = [responseObject valueForKey:YoStoreItemsKey];
                                if ([storeItemsData isKindOfClass:[NSArray class]]) {
                                    [self processStoreItemsData:storeItemsData];
                                }
                                
                                id categoriesData = [responseObject valueForKey:YoSoreCategoriesKey];
                                if ([categoriesData isKindOfClass:[NSArray class]]) {
                                    [self processStoreCategoriesData:categoriesData];
                                }
                                
                                if (storeItemsData == nil ||
                                    categoriesData == nil) {
                                    DDLogWarn(@"<Yo> %@ - WARNING Failed to update data for Yo store",
                                              [self class]);
                                }
                                self.loadingStatus = YoLoadingStatusComplete;
                                NS_HANDLER
                                // when in doubt get out
                                self.loadingStatus = YoLoadingStatusFailed;
                                NS_ENDHANDLER
                            }
                            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                self.loadingStatus = YoLoadingStatusFailed;
                                DDLogError(@"%@", error);
                            }];
        }
    }
}

- (void)clearData {
    self.featuredStoreItems = nil;
    self.storeCategories = nil;
    self.location = nil;
    self.loadingStatus = YoLoadingStatusUnstarted;
}

@end
