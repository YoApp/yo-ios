//
//  YoCollectionViewCell.m
//  Yo
//
//  Created by Peter Reveles on 6/16/15.
//
//

#import "YoCollectionViewCell.h"
#import "YoCollectionViewGridLayoutAttributes.h"

@implementation YoCollectionViewCell

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)commonInit
{
    // We don't get background or selectedBackground views unless we create them!
    self.backgroundView = [[UIView alloc] init];
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14f];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    
    if ([layoutAttributes isKindOfClass:YoCollectionViewGridLayoutAttributes.class]) {
        YoCollectionViewGridLayoutAttributes *attributes = (YoCollectionViewGridLayoutAttributes *)layoutAttributes;
        self.backgroundView.backgroundColor = attributes.backgroundColor;
        self.selectedBackgroundView.backgroundColor = attributes.selectedBackgroundColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [self insertSubview:self.selectedBackgroundView aboveSubview:self.backgroundView];
        self.selectedBackgroundView.alpha = 1;
        self.selectedBackgroundView.hidden = NO;
    }
    else {
        self.selectedBackgroundView.hidden = YES;
    }
}

@end
