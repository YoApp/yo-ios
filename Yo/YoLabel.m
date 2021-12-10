//
//  YoLabel.m
//  Yo
//
//  Created by Peter Reveles on 12/17/14.
//
//

#import "YoLabel.h"

@implementation YoLabel

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
}

- (void)dealloc {
    CGColorSpaceRelease(colorSpaceRef);
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    size.width  += self.edgeInsets.left + self.edgeInsets.right;
    size.height += self.edgeInsets.top + self.edgeInsets.bottom;
    return size;
}

- (void)setText:(NSString *)text {
    if (text == nil) {
        self.attributedText = nil;
    }
    else {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(-0.6)
                                 range:NSMakeRange(0, [text length])];
        
        if (self.makeYoOccurancesBold) {
            NSArray *ranges = [self rangesOfString:@"Yo" inString:text];
            for (NSValue *range in ranges) {
                NSRange r = [range rangeValue];
                [attributedString addAttribute:NSFontAttributeName
                                         value:MonsterratBlack(self.font.pointSize)
                                         range:r];
            }
        }
        
        self.attributedText = attributedString;
    }
}

- (NSArray *)rangesOfString:(NSString *)searchString inString:(NSString *)str {
    NSMutableArray *results = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;
    while ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {
        [results addObject:[NSValue valueWithRange:range]];
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
    }
    return results;
}

- (void)drawTextInRect:(CGRect)rect {
    if (self.verticalAlignment == YoLabelVerticalAlignmentTop) {
        
        rect.size.height = [self sizeThatFits:rect.size].height;
    }
    else if (self.verticalAlignment == YoLabelVerticalAlignmentBottom) {
        
        CGFloat height = [self sizeThatFits:rect.size].height;
        
        rect.origin.y += rect.size.height - height;
        rect.size.height = height;
    }
    
    if ( ! CGSizeEqualToSize(self.glowOffset, CGSizeZero)) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        
        CGContextSetShadow(context, self.glowOffset, self.glowAmount);
        CGContextSetShadowWithColor(context, self.glowOffset, self.glowAmount, self.glowColor.CGColor);
    }
    
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

@end
