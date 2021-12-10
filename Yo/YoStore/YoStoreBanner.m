//
//  YoStoreBanner.m
//  Yo
//
//  Created by Peter Reveles on 4/29/15.
//
//

#import "YoStoreBanner.h"

@interface YoStoreBanner ()
@property (nonatomic, strong) NSString *imageFileName;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) YoStoreItem *associatedStoreItem;
@end

@implementation YoStoreBanner

#pragma mark Life

- (instancetype)initWithImageFileName:(NSString *)imageFileName
          andAssociatedStoreItem:(YoStoreItem *)item
{
    if (imageFileName.length == 0 || item == nil) {
        DDLogWarn(@"<Yo> Failed to load banner due to invalid initial parameters");
        return nil;
    }
    self = [super init];
    if (self) {
        // setup
        [self configureWithImageFileName:imageFileName andAssociatedStoreItem:item];
    }
    return self;
}

- (void)configureWithImageFileName:(NSString *)imageFileName
       andAssociatedStoreItem:(YoStoreItem *)item
{
    _imageFileName = imageFileName;
    _imageURL = [NSURL URLWithString:MakeString(@"https://yo-index-images.s3.amazonaws.com/carousel/%@", imageFileName)];
    _associatedStoreItem = item;
}

#pragma mark - Utility

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToBanner:object];
    }
    else {
        return NO;
    }
}

- (BOOL)isEqualToBanner:(YoStoreBanner *)otherBanner {
    return [self.imageFileName isEqualToString:otherBanner.imageFileName];
}

@end
