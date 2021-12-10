//
//  YoStoreItem.m
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoStoreItem.h"

#define YoStoreItemIdKey @"_id"
#define YoStoreItemCarouselPictureKey @"carousel_picture"
#define YoStoreItemCategoryKey @"category"
#define YoStoreItemCreationDateKey @"created"
#define YoStoreItemDescriptionKey @"description"
#define YoStoreItemScreenShotsKey @"featured_screenshots"
#define YoStoreItemIsInCarouselKey @"in_carousel"
#define YoStoreItemIsOfficialKey @"is_official"
#define YoStoreItemNameKey @"name"
#define YoStoreItemNeedsLocationKey @"needs_location"
#define YoStoreItemProfilePictureKey @"profile_picture"
#define YoStoreItemRankKey @"rank"
#define YoStoreItemRegionKey @"region"
#define YoStoreItemLastUpdateKey @"updated"
#define YoStoreItemURLKey @"url"
#define YoStoreItemUsernameKey @"username"

@implementation YoStoreItem

- (instancetype)initWithItemData:(id)itemData {
    self = [super init];
    if (self) {
        //setup
        [self parseItemData:itemData];
        _itemData = itemData;
    }
    return self;
}

- (void)parseItemData:(id)itemData {
    NS_DURING
    if (itemData && [itemData respondsToSelector:@selector(valueForKey:)]) {
        _itemID = [itemData valueForKey:YoStoreItemIdKey];
        _carouselPistureFileName = [itemData valueForKey:YoStoreItemCarouselPictureKey];
        _categories = [itemData valueForKey:YoStoreItemCategoryKey];
        _itemDescription = [itemData valueForKey:YoStoreItemDescriptionKey];
        
        NSString *urlString = [itemData valueForKey:YoStoreItemURLKey];
        if ([urlString length]) {
            _url = [NSURL URLWithString:urlString];
        }
        
        _username = [itemData valueForKey:YoStoreItemUsernameKey];
        _name = [itemData valueForKey:YoStoreItemNameKey];
        
        _profilePictureFileName = [itemData valueForKey:YoStoreItemProfilePictureKey];
        _rank = [[itemData valueForKey:YoStoreItemRankKey] integerValue];
        _screenShotFileNames = [itemData valueForKey:YoStoreItemScreenShotsKey];
        _needsLocation = [[itemData valueForKey:YoStoreItemNeedsLocationKey] boolValue];
        _isInCarousel = [[itemData valueForKey:YoStoreItemIsInCarouselKey] boolValue];
        _isOfficial = [[itemData valueForKey:YoStoreItemIsOfficialKey] boolValue];
    }
    NS_HANDLER
    NS_ENDHANDLER
}

#pragma mark - Utility

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToItem:object];
    }
    else {
        return NO;
    }
}

- (BOOL)isEqualToItem:(YoStoreItem *)item {
    if (self.itemID == item.itemID) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
