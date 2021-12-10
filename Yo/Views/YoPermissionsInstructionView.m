//
//  YoViewWithTitleAndAction.m
//  Yo
//
//  Created by Peter Reveles on 6/4/15.
//
//

#import "YoPermissionsInstructionView.h"

@implementation YoPermissionsInstructionView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.instructionImageView.layer.masksToBounds = NO;
    self.instructionImageView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.instructionImageView.layer.shadowRadius = 3.0f;
    self.instructionImageView.layer.shadowOpacity = 0.5f;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)updateHeightToFitSubviews {
    CGFloat height = [self getHeightRequiredToDisplayText:self.textLabel.text
                                           withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Regular" size:17.0f]}
                                                  inWidth:self.width - 32.0f];
    height += 17.0f; // for some reason getHeightRequired is off by 1 line height
    CGFloat padding = 24.0f + 10.0f + (14.0f * 2); // padding based on View layout
    CGFloat shouldBeHeight = height + self.settingsAppIconImageView.height + self.instructionImageView.height + padding;
    if (self.actionButton.superview) {
        shouldBeHeight += self.actionButton.height + 14.0f;
    }
    self.height = shouldBeHeight;
}

- (NSUInteger)getHeightRequiredToDisplayText:(NSString *)text
                              withAttributes:(NSDictionary *)attributes
                                     inWidth:(CGFloat)maxWidth
{
    if (!text.length || !maxWidth) {
        return 0.0;
    }
    
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size.height;
}

@end
