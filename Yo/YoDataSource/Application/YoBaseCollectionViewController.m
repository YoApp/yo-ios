//
//  YoBaseCollectionViewController.m
//  Yo
//
//  Created by Peter Reveles on 6/16/15.
//
//

#import "YoBaseCollectionViewController.h"
#import "YoDataSource.h"
#import "YoDataSourceDelegate.h"

@interface YoBaseCollectionViewController () <YoDataSourceDelegate>

@end

static void *YoContext = &YoContext;

@implementation YoBaseCollectionViewController

- (void)dealloc
{
    [self.collectionView removeObserver:self forKeyPath:@"dataSource" context:YoContext];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UICollectionView *collectionView = self.collectionView;
    
    YoDataSource *dataSource = (YoDataSource *)collectionView.dataSource;
    if ([dataSource isKindOfClass:YoDataSource.class]) {
        [dataSource registerReusableViewsWithCollectionView:collectionView];
        [dataSource setNeedsLoadContent];
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    UICollectionView *oldCollectionView = self.collectionView;
    
    _collectionView = collectionView;
    
    [oldCollectionView removeObserver:self forKeyPath:@"dataSource" context:YoContext];
    
    //  We need to know when the data source changes on the collection view so we can become the delegate for any APPLDataSource subclasses.
    [collectionView addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:YoContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //  For change contexts that aren't the data source, pass them to super.
    if (context == YoContext) {
        UICollectionView *collectionView = object;
        YoDataSource *dataSource = (YoDataSource *)collectionView.dataSource;
        if ([dataSource isKindOfClass:YoDataSource.class]) {
            if (dataSource.delegate == nil) {
                dataSource.delegate = self;
            }
        }
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - AAPLDataSourceDelegate methods

- (void)dataSource:(YoDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(YoDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(YoDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(YoDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction
{
    id <YoDataSourceDelegate> layout = (id <YoDataSourceDelegate>)self.collectionView.collectionViewLayout;
    if ([layout conformsToProtocol:@protocol(YoDataSourceDelegate)] && [layout respondsToSelector:@selector(dataSource:didInsertSections:direction:)]) {
        [layout dataSource:dataSource didInsertSections:sections direction:direction];
    }
    [self.collectionView insertSections:sections];
}

- (void)dataSource:(YoDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction
{
    id <YoDataSourceDelegate> layout = (id <YoDataSourceDelegate>)self.collectionView.collectionViewLayout;
    if ([layout conformsToProtocol:@protocol(YoDataSourceDelegate)] && [layout respondsToSelector:@selector(dataSource:didRemoveSections:direction:)]) {
        [layout dataSource:dataSource didRemoveSections:sections direction:direction];
    }
    [self.collectionView deleteSections:sections];
}

- (void)dataSource:(YoDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(YoDataSourceSectionOperationDirection)direction
{
    id <YoDataSourceDelegate> layout = (id <YoDataSourceDelegate>)self.collectionView.collectionViewLayout;
    if ([layout conformsToProtocol:@protocol(YoDataSourceDelegate)] && [layout respondsToSelector:@selector(dataSource:didMoveSection:toSection:direction:)]) {
        [layout dataSource:dataSource didMoveSection:section toSection:newSection direction:direction];
    }
    [self.collectionView moveSection:section toSection:newSection];
}

- (void)dataSource:(YoDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(YoDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections
{
    [self.collectionView reloadSections:sections];
}

- (void)dataSourceDidReloadData:(YoDataSource *)dataSource
{
    [self.collectionView reloadData];
}

- (void)dataSource:(YoDataSource *)dataSource performBatchUpdate:(void(^)(void))update completion:(void (^)(BOOL))completion
{
    [self.collectionView performBatchUpdates:update completion:completion];
}

@end
