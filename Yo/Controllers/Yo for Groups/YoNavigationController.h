//
//  YoNavigationController.h
//  Yo
//
//  Created by Peter Reveles on 5/18/15.
//
//

@interface YoNavigationController : UINavigationController <YoBlurredBackgroundPresentable>

@property(nonatomic, assign) BOOL allowCustomBarColor;

@property(nonatomic, strong) UIImageView *blurredBackgrounImageView;

@end
