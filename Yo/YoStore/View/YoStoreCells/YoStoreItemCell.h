//
//  YoStoreItemCell.h
//  Yo
//
//  Created by Or Arbel on 2/14/15.
//
//

#import <UIKit/UIKit.h>
#import "YoStoreButton.h"
@class YoStoreItem;
@class YoStoreItemCell;

typedef void (^YoStoreItemCellSubscribeButtonTapped) (YoStoreItemCell *subscribeButton);
typedef void (^YoStoreItemCellDetailsButtonTapped) (YoStoreItemCell *detailsButton);

@interface YoStoreItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet YoStoreButton *subscribeButton;
@property (nonatomic, weak) IBOutlet UIButton *detailsButton;
@property (weak, nonatomic) IBOutlet UIImageView *needsLocationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isVerifiedImageView;

@property (nonatomic, strong) YoStoreItem *item;

@property (nonatomic, strong) YoStoreItemCellSubscribeButtonTapped subscribeButtonTappedBlock;
@property (nonatomic, strong) YoStoreItemCellDetailsButtonTapped detailsButtonTappedBlock;

@end
