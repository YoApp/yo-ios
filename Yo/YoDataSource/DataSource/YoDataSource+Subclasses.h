/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoDataSourceDelegate.h"
#import "YoLayoutMetrics.h"

@class YoCollectionPlaceholderView;

@interface YoDataSource (ForSubclassEyesOnly)

/// Find the data source for the given section. Default implementation returns self.
- (YoDataSource *)dataSourceForSectionAtIndex:(NSInteger)sectionIndex;

// Use these methods to notify the collection view of changes to the dataSource.
- (void)notifyItemsInsertedAtIndexPaths:(NSArray *)insertedIndexPaths;
- (void)notifyItemsRemovedAtIndexPaths:(NSArray *)removedIndexPaths;
- (void)notifyItemsRefreshedAtIndexPaths:(NSArray *)refreshedIndexPaths;
- (void)notifyItemMovedFromIndexPath:(NSIndexPath *)indexPath toIndexPaths:(NSIndexPath *)newIndexPath;

- (void)notifySectionsInserted:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction;
- (void)notifySectionsRemoved:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction;
- (void)notifySectionMovedFrom:(NSInteger)section to:(NSInteger)newSection direction:(YoDataSourceSectionOperationDirection)direction;
- (void)notifySectionsRefreshed:(NSIndexSet *)sections;

- (void)notifyDidReloadData;

- (void)notifyBatchUpdate:(void(^)(void))update completion:(void(^)(BOOL finished))completion;

- (void)notifyWillLoadContent;
- (void)notifyContentLoadedWithError:(NSError *)error;

- (void)updatePlaceholder:(YoCollectionPlaceholderView *)placeholderView notifyVisibility:(BOOL)notify;

#pragma mark -

- (YoLayoutSectionMetrics *)snapshotMetricsForSectionAtIndex:(NSInteger)sectionIndex;

- (void)executePendingUpdates;

- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath;

/// Whether this data source should display the placeholder.
@property (nonatomic, readonly) BOOL shouldDisplayPlaceholder;

#pragma mark - Subclass hooks

/// Load the content of this data source.
- (void)loadContent;

/// Reset the content and loading state.
- (void)resetContent NS_REQUIRES_SUPER;

/// Use this method to wait for content to load. The block will be called once the loadingState has transitioned to the ContentLoaded, NoContent, or Error states. If the data source is already in that state, the block will be called immediately.
- (void)whenLoaded:(dispatch_block_t)block __unused;

#pragma mark -

- (void)stateWillChangeFrom:(NSString *)oldState to:(NSString *)newState NS_REQUIRES_SUPER;
- (void)stateDidChangeFrom:(NSString *)oldState to:(NSString *)newState NS_REQUIRES_SUPER;

@end
