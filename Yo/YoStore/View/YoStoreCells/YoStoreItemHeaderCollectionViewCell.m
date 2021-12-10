//
//  YoStoreItemHeaderCollectionViewCell.m
//  Yo
//
//  Created by Peter Reveles on 2/25/15.
//
//

#import "YoStoreItemHeaderCollectionViewCell.h"

@implementation YoStoreItemHeaderCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    self.itemImageView.layer.cornerRadius = self.itemImageView.width/2.0f;
    self.itemImageView.layer.masksToBounds = YES;
    
//    self.itemSubscriptionButton.layer.cornerRadius = 4.0f;
//    self.itemSubscriptionButton.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.itemSubscriptionButton.layer.borderWidth = 1.0f;
    self.itemSubscriptionButton.style = YoStoreButtonStyleBordered;
    [self.itemSubscriptionButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
    [self.itemSubscriptionButton setTitle:NSLocalizedString(@"subscribed", nil).capitalizedString forState:UIControlStateSelected];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isOfficialImageView.hidden = YES;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // setup if neeeded
        
    }
    return self;
}

- (IBAction)userDidTapSubscribeButton:(YoStoreButton *)sender {
    if (self.subcribeButtonTapBlock) {
        self.subcribeButtonTapBlock();
    }
}

@end
