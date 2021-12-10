//
//  YOProfileView.m
//  Yo
//
//  Created by Tomer on 7/23/14.
//
//

#import "YOProfileView.h"
#import <QuartzCore/QuartzCore.h>

@interface YOProfileView ()
@property (nonatomic) YOProfileViewMode currentMode;
@end

@implementation YOProfileView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.fullNameLabel.text = NSLocalizedString(@"FULL NAME", nil).lowercaseString.capitalizedString;
    self.fullNameLabel.adjustsFontSizeToFitWidth = YES;
    self.fullNameLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:34];
    self.fullNameLabel.minimumScaleFactor = 4./34;
    self.fullNameLabel.numberOfLines = 0;
    
    self.cellImageView.layer.cornerRadius = self.cellImageView.width/2;
    self.cellImageView.layer.masksToBounds = YES;
    
    self.currentMode = YOProfileViewMode_Default;
}

- (void)updateCellForMode:(YOProfileViewMode)mode{
    if (self.currentMode == mode) return;
    switch (mode) {
        case YOProfileViewMode_NoImage:
            self.cellImageView.hidden = YES;
            for (NSLayoutConstraint *constraint in self.constraints) {
                if ([constraint.description rangeOfString:@"]-(11)-[UILabel:"].location != NSNotFound) {
                    [self removeConstraint:constraint];
                    [self addConstraint:
                     [NSLayoutConstraint
                      constraintWithItem:self.fullNameLabel attribute:NSLayoutAttributeLeft
                      relatedBy:NSLayoutRelationEqual
                      toItem:self attribute:NSLayoutAttributeLeft
                      multiplier:1.0f constant:5.0f]];
                }
            }
            break;
            
        case YOProfileViewMode_Default:
            self.cellImageView.hidden = NO;
            for (NSLayoutConstraint *constraint in self.constraints) {
                if ([constraint.description rangeOfString:@"|-(5)-[UILabel:"].location != NSNotFound) {
                    [self removeConstraint:constraint];
                    [self addConstraint:
                     [NSLayoutConstraint
                      constraintWithItem:self.fullNameLabel attribute:NSLayoutAttributeLeft
                      relatedBy:NSLayoutRelationEqual
                      toItem:self.cellImageView attribute:NSLayoutAttributeRight
                      multiplier:1.0f constant:11.0f]];
                }
            }
            break;
    }
    self.currentMode = mode;
    [self layoutIfNeeded];
}

@end
