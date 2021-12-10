//
//  YoLabel.h
//  Yo
//
//  Created by Peter Reveles on 12/17/14.
//
//

typedef enum {
    YoLabelVerticalAlignmentCenter,
    YoLabelVerticalAlignmentTop,
    YoLabelVerticalAlignmentBottom
} YoLabelVerticalAlignment;

@interface YoLabel : UILabel {
    CGColorSpaceRef colorSpaceRef;
}

@property (nonatomic, assign) YoLabelVerticalAlignment verticalAlignment;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, assign) BOOL makeYoOccurancesBold;

@property (nonatomic, assign) CGSize glowOffset;
@property (nonatomic, assign) CGFloat glowAmount;
@property (nonatomic, retain) UIColor *glowColor;

@end
