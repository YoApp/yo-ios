//
//  YoBannerView.h
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import <UIKit/UIKit.h>
#import "YoBanner.h"

typedef NS_ENUM(NSUInteger, YoBannerViewResult) {
    YoBannerViewResultExpired,
    YoBannerViewResultDismissed,
    YoBannerViewResultOpened,
};

@class YoBannerView;
@protocol YoBannerViewDelegate <NSObject>
@optional
- (void)bannerView:(YoBannerView *)bannerView didDismissWithResult:(YoBannerViewResult)result;
@end

@interface YoBannerView : UIView

- (void)configureForBanner:(YoBanner *)banner;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (readonly, nonatomic) YoBanner *banner;
@property (weak, nonatomic) id <YoBannerViewDelegate> delegate;

- (void)showInView:(UIView *)view;

@end
