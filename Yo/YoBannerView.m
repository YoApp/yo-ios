//
//  YoBannerView.m
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import "YoBannerView.h"

@implementation YoBannerView

- (instancetype)init
{
    return [[[NSBundle mainBundle] loadNibNamed:@"YoBannerView" owner:self options:nil] objectAtIndex:0];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self init];
    self.frame = frame;
    return self;
}

- (void)configureForBanner:(YoBanner *)banner
{
    _banner = banner;
    self.messageLabel.text = banner.message;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithHexString:PETER];
    self.messageLabel.text = nil;
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapBannerWithTapGR:)];
    [self addGestureRecognizer:tapGR];
    
    self.layer.shadowRadius = 5.0f;
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowColor = [[UIColor colorWithHexString:ASPHALT] CGColor];
}

- (void)userDidTapBannerWithTapGR:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state == UIGestureRecognizerStateEnded) {
        [self dismissFromParentViewWithCompletionBlock:^{
            if ([self.delegate respondsToSelector:@selector(bannerView:didDismissWithResult:)]) {
                [self.delegate bannerView:self didDismissWithResult:YoBannerViewResultOpened];
            }
        }];
    }
}

- (IBAction)dismissButtonTapped:(UIButton *)sender {
    [self dismissFromParentViewWithCompletionBlock:^{
        if ([self.delegate respondsToSelector:@selector(bannerView:didDismissWithResult:)]) {
            [self.delegate bannerView:self didDismissWithResult:YoBannerViewResultDismissed];
        }
    }];
}

- (void)showInView:(UIView *)view
{
    self.frame = CGRectMake(0.0f,
                            CGRectGetMaxY(view.frame),
                            view.width,
                            90.0f);
    [view addSubview:self];
    
    void (^animationBlock)() = ^(){
        self.bottom = CGRectGetMaxY(view.frame);
    };
    
    if (IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.2 animations:^{
            animationBlock();
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2 delay:0.0
             usingSpringWithDamping:0.8 initialSpringVelocity:0.2
                            options:UIViewAnimationOptionCurveEaseInOut animations:^{
                                animationBlock();
                            } completion:nil];
    }
}

- (void)dismissFromParentViewWithCompletionBlock:(void (^)())block
{
    if (self.superview == nil) {
        if (block) {
            block();
        }
        return;
    }
    
    void (^animationBlock)() = ^(){
        self.top = CGRectGetMaxY(self.superview.frame);
    };
    
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        [self removeFromSuperview];
        if (block) {
            block();
        }
    };
    
    if (IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.2
                         animations:animationBlock
                         completion:completionBlock];
    }
    else {
        [UIView animateWithDuration:0.2 delay:0.1
             usingSpringWithDamping:0.7 initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animationBlock
                         completion:completionBlock];
    }
}

@end
