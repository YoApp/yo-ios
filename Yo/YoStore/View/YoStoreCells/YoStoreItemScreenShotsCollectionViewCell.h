//
//  YoStoreItemScreenShotsCollectionViewCell.h
//  Yo
//
//  Created by Peter Reveles on 2/25/15.
//
//

#import <UIKit/UIKit.h>
@class SwipeView;

@interface YoStoreItemScreenShotsCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
