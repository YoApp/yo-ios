//
//  YOHeaderFooterCell.m
//  Yo
//
//  Created by Peter Reveles on 10/13/14.
//
//

#import "YOHeaderFooterCell.h"

#define SIDE_MARGINS 15.0f
@implementation YOHeaderFooterCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self createAndLayoutCells];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self createAndLayoutCells];
    }
    return self;
}

- (void)createAndLayoutCells{
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [UIFont fontWithName:@"Montserrat-Bold" size:38];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.backgroundColor = [UIColor clearColor];
    title.numberOfLines = 0;
    [self.contentView addSubview:title];
    self.title = title;
    
    UILabel *titleDescription = [UILabel new];
    titleDescription.translatesAutoresizingMaskIntoConstraints = NO;
    titleDescription.font = [UIFont fontWithName:@"Montserrat-Bold" size:30];
    titleDescription.textColor = [UIColor whiteColor];
    titleDescription.textAlignment = NSTextAlignmentCenter;
    titleDescription.backgroundColor = [UIColor clearColor];
    title.numberOfLines = 0;
    [self.contentView addSubview:titleDescription];
    self.titleDescription = titleDescription;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(title, titleDescription);
    
    NSDictionary *metrics = @{@"SIDE_MARGINS" : @(SIDE_MARGINS)};
    
    [self.contentView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[title]|"
      options:0
      metrics:metrics views:views]];
    [self.contentView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[title][titleDescription]|"
      options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
      metrics:metrics views:views]];
    [self.contentView addConstraint:
     [NSLayoutConstraint
      constraintWithItem:title attribute:NSLayoutAttributeHeight
      relatedBy:NSLayoutRelationEqual
      toItem:self.contentView attribute:NSLayoutAttributeHeight
      multiplier:0.573f constant:0.0f]];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.title.text = nil;
    self.titleDescription.text = nil;
}

@end
