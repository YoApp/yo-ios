//
//  YoStoreItemScreenShotsCollectionViewCell.m
//  Yo
//
//  Created by Peter Reveles on 2/25/15.
//
//

#import "YoStoreItemScreenShotsCollectionViewCell.h"
#import <SwipeView/SwipeView.h>

@implementation YoStoreItemScreenShotsCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    self.backgroundColor = [UIColor clearColor];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //setup
        self.swipeView.truncateFinalPage = YES;
    }
    return self;
}

@end
