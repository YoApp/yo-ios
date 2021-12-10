//
//  YoContactsListDataSource.m
//  Yo
//
//  Created by Peter Reveles on 6/15/15.
//
//

#import "YoBlockedListDataSource.h"
#import "YoBlockedUserCell.h"
#import "YoDataAccessManager.h"

@implementation YoBlockedListDataSource

+ (instancetype)sharedInstance {
    static YoBlockedListDataSource *_sharedInstance = nil;
    static dispatch_once_t once_predicate;
    dispatch_once(&once_predicate, ^{
        YoBlockedListDataSource *blockedListDatasource = [[YoBlockedListDataSource alloc] init];
        blockedListDatasource.title = @"Blocked List";
        blockedListDatasource.noContentTitle = NSLocalizedString(@"No Blocked Contacts", nil);
        blockedListDatasource.noContentMessage = NSLocalizedString(@"To block a user tap and hold a contact to view their profile.", nil);
        blockedListDatasource.errorTitle = NSLocalizedString(@"Yo", nil);
        blockedListDatasource.errorMessage = NSLocalizedString(@"I couldn't find your blocked contacts. I'm sorry.", nil);
        
        _sharedInstance = blockedListDatasource;
    });
    return _sharedInstance;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];
    [collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([YoBlockedUserCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([YoBlockedUserCell class])];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoModelObject *blockedObject = [self itemAtIndexPath:indexPath];
    YoBlockedUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([YoBlockedUserCell class]) forIndexPath:indexPath];
    cell.object = blockedObject;
    
    return cell;
}

- (void)loadContent
{
    [super loadContentWithBlock:^(YoLoading *loading) {
        void (^handler)(NSArray *blockedList, NSError *error) = ^(NSArray *blockedList, NSError *error){
            // Check to make certain a more recent call to load content hasn't superceded this one…
            if (!loading.current) {
                [loading ignore];
                return;
            }
            
            if (error) {
                [loading done:NO error:error];
                return;
            }
            
            if (blockedList.count)
                [loading updateWithContent:^(YoBlockedListDataSource *me) {
                    me.items = blockedList;
                }];
            else
                [loading updateWithNoContent:^(YoBlockedListDataSource *me) {
                    me.items = @[];
                }];
        };
        
        [[YoDataAccessManager sharedDataManager] fetchBlockedListWithCompletionHandler:handler];
    }];
}

@end
