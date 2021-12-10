//
//  YoActionButton.m
//  Yo
//
//  Created by Or Arbel on 6/3/15.
//
//

#import "YoActionButton.h"

@interface YoActionButton ()

@property(nonatomic, strong) UIActivityIndicatorView *aiView;

@end

@implementation YoActionButton

- (void)awakeFromNib {
    [super awakeFromNib];
    self.disableRoundedCorners = YES;
    
    
    self.aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.aiView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.aiView];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:[self aiView]
                                                      attribute:NSLayoutAttributeCenterX
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self
                                                      attribute:NSLayoutAttributeCenterX
                                                     multiplier:1
                                                       constant:0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:[self aiView]
                                                      attribute:NSLayoutAttributeCenterY
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self
                                                      attribute:NSLayoutAttributeCenterY
                                                     multiplier:1
                                                       constant:0]];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)startAnimating {
   [self.titleLabel removeFromSuperview];
    [self.aiView startAnimating];
}

- (void)stopAnimating {
    [self addSubview:self.titleLabel];
    [self.aiView stopAnimating];
}

@end
