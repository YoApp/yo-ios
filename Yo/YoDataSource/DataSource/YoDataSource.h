//
//  YoDataSource.h
//  Yo
//
//  Created by Peter Reveles on 6/15/15.
//
//

#import <UIKit/UIKit.h>
#import "YoContentLoading.h"

@class YoLayoutSectionMetrics;
@class YoLayoutSupplementaryMetrics;

typedef NS_ENUM(NSUInteger, YoDataSourceSectionOperationDirection) {
    YoDataSourceSectionOperationDirectionNone,
    YoDataSourceSectionOperationDirectionRight,
    YoDataSourceSectionOperationDirectionLeft
};

@interface YoDataSource : NSObject <UICollectionViewDataSource, YoContentLoading>

/// The title of this data source. This value is used to populate section headers.
@property (nonatomic, copy) NSString *title;

/// The number of sections in this data source.
@property (nonatomic, readonly) NSUInteger numberOfSections;

/// Find the item at the specified index path.
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

/// Remove an item from the data source. This method should only be called as the result of a user action. Automatic removal of items due to outside changes should instead be handled by the data source itself — not the controller.
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Metrics

@property (nonatomic, strong) YoLayoutSectionMetrics *defaultMetrics;

- (YoLayoutSectionMetrics *)metricsForSectionAtIndex:(NSInteger)sectionIndex;
- (void)setMetrics:(YoLayoutSectionMetrics *)metrics forSectionAtIndex:(NSInteger)sectionIndex __unused;

/// Look up a header by its key
- (YoLayoutSupplementaryMetrics *)headerForKey:(NSString *)key;
/// Create a new header and append it to the collection of headers
- (YoLayoutSupplementaryMetrics *)newHeaderForKey:(NSString *)key;
/// Remove a header specified by its key
- (void)removeHeaderForKey:(NSString *)key __unused;
/// Replace a header specified by its key with a new header with the same key.
- (void)replaceHeaderForKey:(NSString *)key withHeader:(YoLayoutSupplementaryMetrics *)header __unused;

/// Compute a flattened snapshot of the layout metrics associated with this and any child data sources.
- (NSDictionary *)snapshotMetrics;

#pragma mark - Placeholders

@property (nonatomic, copy) NSString *noContentTitle;
@property (nonatomic, copy) NSString *noContentMessage;
@property (nonatomic, strong) UIImage *noContentImage;

@property (nonatomic, copy) NSString *errorMessage;
@property (nonatomic, copy) NSString *errorTitle;

/// Is this data source "hidden" by a placeholder either of its own or from an enclosing data source. Use this to determine whether to report that there are no items in your data source while loading.
@property (nonatomic, readonly) BOOL obscuredByPlaceholder;

#pragma mark -

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPathIsHidden:(NSIndexPath *)indexPath;

/// Measure variable height cells. The goal here is to do the minimal necessary configuration to get the correct size information.
- (CGSize)collectionView:(UICollectionView *)collectionView sizeFittingSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath;

/// Register reusable views needed by this data source
- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView NS_REQUIRES_SUPER;

/// Signal that the data source SHOULD reload its content
- (void)setNeedsLoadContent;

@end
