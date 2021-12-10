//
//  YoStoreItemHeaderCollectionViewCell.h
//  Yo
//
//  Created by Peter Reveles on 2/25/15.
//
//

#import <UIKit/UIKit.h>
#import "YoStoreButton.h"

typedef void (^YOStoreSubscribeButtonTapBlock)();

@interface YoStoreItemHeaderCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet YoStoreButton *itemSubscriptionButton;
@property (weak, nonatomic) IBOutlet UIImageView *isOfficialImageView;

@property (nonatomic, copy) YOStoreSubscribeButtonTapBlock subcribeButtonTapBlock;

@end
