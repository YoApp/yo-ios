//
//  YoStoreBanner.h
//  Yo
//
//  Created by Peter Reveles on 4/29/15.
//
//

#import <Foundation/Foundation.h>

@interface YoStoreBanner : NSObject

- (instancetype)initWithImageFileName:(NSString *)imageFileName andAssociatedStoreItem:(YoStoreItem *)item;

@property (nonatomic, readonly) NSString *imageFileName;

@property (nonatomic, readonly) NSURL *imageURL;

@property (nonatomic, readonly) YoStoreItem *associatedStoreItem;

@property (nonatomic, assign) BOOL isFeatured;

#pragma mark - Utility

- (BOOL)isEqualToBanner:(YoStoreBanner *)otherBanner;

@end
