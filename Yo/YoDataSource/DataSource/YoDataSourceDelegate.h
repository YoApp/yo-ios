//
//  AAPLDataSourceHeader.h
//  AdvancedCollectionView
//
//  Created by Zachary Waldowski on 7/12/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import "YoDataSource.h"

@class YoCollectionPlaceholderView;

@protocol YoDataSourceDelegate <NSObject>
@optional

- (void)dataSource:(YoDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(YoDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(YoDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(YoDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath;

- (void)dataSource:(YoDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction;
- (void)dataSource:(YoDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction;
- (void)dataSource:(YoDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(YoDataSourceSectionOperationDirection)direction;
- (void)dataSource:(YoDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections;

- (void)dataSourceDidReloadData:(YoDataSource *)dataSource;
- (void)dataSource:(YoDataSource *)dataSource performBatchUpdate:(void(^)(void))update completion:(void(^)(BOOL finished))completion;

/// If the content was loaded successfully, the error will be nil.
- (void)dataSource:(YoDataSource *)dataSource didLoadContentWithError:(NSError *)error;

/// Called just before a data source begins loading its content.
- (void)dataSourceWillLoadContent:(YoDataSource *)dataSource;
@end

@interface YoDataSource ()

/// A delegate object that will receive change notifications from this data source.
@property (nonatomic, weak) id<YoDataSourceDelegate> delegate;

@end