//
//  YoStoreCategory.m
//  Yo
//
//  Created by Peter Reveles on 4/28/15.
//
//

#import "YoStoreCategory.h"

#define YoStoreCategoryKeyID @"_id"
#define YoStoreCategoryKeyName @"category"
#define YoStoreCategoryKeyCreationTime @"created"
#define YoStoreCategoryKeyRank @"rank"
#define YoStoreCategoryKeyRegion @"region"
#define YoStoreCategoryKeyTimeSinceLastUpdate @"updated"
#define YoStoreCategoryKeyIsFeatured @"is_featured"

@interface YoStoreCategory ()
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *itemID;
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, assign) NSTimeInterval creationTime;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) BOOL isFeatured;
@end

@implementation YoStoreCategory

- (instancetype)initWithCategoryData:(id)categoryData {
    self = [super init];
    if (self) {
        //setup
        [self parseCategoryData:categoryData];
    }
    return self;
}

- (void)parseCategoryData:(id)categoryData {
    NS_DURING
    if ([categoryData respondsToSelector:@selector(valueForKey:)]) {
        _itemID = [categoryData valueForKey:YoStoreCategoryKeyID];
        _name = [categoryData valueForKey:YoStoreCategoryKeyName];
        _rank = [[categoryData valueForKey:YoStoreCategoryKeyRank] integerValue];
        
        id creationTime = [categoryData valueForKey:YoStoreCategoryKeyCreationTime];
        if ([creationTime respondsToSelector:@selector(doubleValue)]) {
            _creationTime = [creationTime doubleValue];
        }
        
        id lastUpdateTime = [categoryData valueForKey:YoStoreCategoryKeyTimeSinceLastUpdate];
        if ([lastUpdateTime respondsToSelector:@selector(doubleValue)]) {
            _lastUpdateTime = [lastUpdateTime doubleValue];
        }
        
        id isFeatured = [categoryData valueForKey:YoStoreCategoryKeyIsFeatured];
        if ([isFeatured respondsToSelector:@selector(boolValue)]) {
            _isFeatured = [isFeatured boolValue];
        }
        else {
            _isFeatured = YES;
        }
    }
    NS_HANDLER
    DDLogWarn(@"%@ | failed to create category from data", NSStringFromClass([self class]));
    NS_ENDHANDLER
}

#pragma mark - Utility

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToCategory:object];
    }
    else {
        return NO;
    }
}

- (BOOL)isEqualToCategory:(YoStoreCategory *)otherCategory {
    if (self.itemID == otherCategory.itemID) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
