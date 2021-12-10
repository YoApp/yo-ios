//
//  YoStoreButton.m
//  Yo
//
//  Created by Peter Reveles on 2/26/15.
//
//

#import "YoStoreButton.h"

@implementation YoStoreButton

- (void)setup {
    self.style = YoStoreButtonStyleBordered;
    self.tintColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont fontWithName:@"Montserrat-Regular" size:14];
    self.layer.cornerRadius = 4.0f;
    self.layer.masksToBounds = YES;
    self.contentEdgeInsets = UIEdgeInsetsMake(6.0f, 6.0f, 6.0f, 6.0f);
}

- (void)setStyle:(YoStoreButtonStyle)style {
    _style = style;
    
    switch (style) {
        case YoStoreButtonStyleWhite:
        case YoStoreButtonStylePlain:
            self.layer.borderWidth = 0.0f;
            break;
            
        default:
        case YoStoreButtonStyleBordered:
            self.layer.borderWidth = 1.5f;
            break;
    }
    
    [self tintColorDidChange];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    //self.layer.cornerRadius = 4.0f;
}

- (void)tintColorDidChange {
    switch (self.style) {
        case YoStoreButtonStylePlain:
            self.backgroundColor = self.tintColor;
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [self setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
            break;
            
        case YoStoreButtonStyleWhite:
            self.backgroundColor = [UIColor whiteColor];
            [self setTitleColor:self.tintColor forState:UIControlStateNormal];
            [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
            [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
            break;
            
            
        default:
        case YoStoreButtonStyleBordered:
            self.backgroundColor = [UIColor clearColor];
            self.layer.borderColor = self.tintColor.CGColor;
            [self setTitleColor:self.tintColor forState:UIControlStateNormal];
            [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
            [self setTitleColor:[self.tintColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
            break;
    }
    
    if (self.backgroundColor != [UIColor clearColor]) {
        self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:self.enabled?1.0f:0.3f];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    
    if (self.backgroundColor != [UIColor clearColor]) {
        self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:enabled?1.0f:0.3f];
    }
    //    [self setTitle:[self titleForState:UIControlStateNormal] forState:UIControlStateDisabled];
}


- (void)setHighlighted:(BOOL)highlighted {
    [self setTitle:self.titleLabel.text forState:UIControlStateHighlighted];
    [super setHighlighted:highlighted];
    
    [UIView animateWithDuration:(highlighted?0.0:0.15) animations:^{
        if (self.style == YoStoreButtonStylePlain) {
            self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:highlighted?0.7f:1.0f];
        } else {
            self.layer.borderColor = [self.tintColor colorWithAlphaComponent:highlighted?0.7f:1.0f].CGColor;
        }
    }];
}

@end
