//
//  YoInboxYoTableViewCell.h
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "SWTableViewCell.h"

@class Yo;

typedef NS_ENUM(NSUInteger, YoTVCSizeType) {
    YoTVCSizeTypeNone,
    YoTVCSizeTypeSquare,
    YoTVCSizeTypeLandscape,
    YoTVCSizeTypePortrait
};

extern NSString *const YoExceptionInValidCellTypeForYo;

@interface YoInboxTableViewCell : SWTableViewCell

@property (nonatomic, strong, readonly) UILabel *senderLabel;
@property (nonatomic, strong, readonly) UILabel *sentDateLabel;
@property (nonatomic, strong, readonly) UILabel *bottomRightLabel;
@property (nonatomic, strong) UIView *yoPreview;

/**
 Animatable. Defaults to YoTVCImageSizeTypeNone.
 */
@property (nonatomic, assign) YoTVCSizeType yoSizeType;

@property (nonatomic, assign) UIEdgeInsets contentInsets;

/// a convinience method
- (void)configureForYo:(Yo *)yo;

- (CGSize)yo_systemLayoutSizeFittingSize:(CGSize)targetSize;

@end
