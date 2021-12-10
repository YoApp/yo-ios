//
//  YoStoreItemController.h
//  Yo
//
//  Created by Or Arbel on 2/15/15.
//
//

#import <SwipeView/SwipeView.h>
#import "YoStoreBaseViewController.h"

@class YoStoreItemController;

@interface YoStoreItemController : YoStoreBaseViewController

- (instancetype)initForItem:(YoStoreItem *)item;

- (void)configureWithItem:(YoStoreItem *)item;

@property (nonatomic, readonly) YoStoreItem *item;

@end
