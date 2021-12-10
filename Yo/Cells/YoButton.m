//
//  YoButton.m
//  Yo
//
//  Created by Peter Reveles on 5/15/15.
//
//

#import "YoButton.h"

@implementation YoButton

- (instancetype)init {
    self = [super init];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self performInitialSetup];
}

- (void)performInitialSetup {
    self.layer.cornerRadius = 3.0f;
}

- (void)setDisableRoundedCorners:(BOOL)disableRoundedCorners {
    _disableRoundedCorners = disableRoundedCorners;
    if (disableRoundedCorners) {
        self.layer.cornerRadius = 0.0f;
    }
    else {
        self.layer.cornerRadius = 3.0f;
    }
}

- (void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    
    if (self.backgroundColor != [UIColor clearColor]) {
        self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:enabled?1.0f:0.7f];
    }
}

- (void)animateProgressWithDuration:(NSTimeInterval)durationInSeconds {
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.height)];
    progressView.backgroundColor = [UIColor redColor];
    progressView.tag = 543;
    [self insertSubview:progressView belowSubview:self.titleLabel];
    [UIView animateWithDuration:durationInSeconds delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        progressView.frame = CGRectMake(0, 0, self.width, self.height);
    } completion:^(BOOL finished) {
        [progressView removeFromSuperview];
    }];
}

- (void)removeProgressView {
    [self viewWithTag:543].backgroundColor = [UIColor clearColor];
    [[self viewWithTag:543] removeFromSuperview];
}

@end
