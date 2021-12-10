//
//  YoRecordingView.h
//  Yo
//
//  Created by Peter Reveles on 7/17/15.
//
//

#import <UIKit/UIKit.h>
@class YoButton;

typedef NS_ENUM(NSInteger, YoRecordingViewStyle) {
    YoRecordingViewSendAndCancelStyle,
    YoRecordingViewCancelStyle
};

@interface YoRecordingView : UIView

- (instancetype)initWithStyle:(YoRecordingViewStyle)style;

@property (nonatomic, assign) YoRecordingViewStyle style;

@property (nonatomic, weak) YoButton *sendButton;
@property (nonatomic, weak) YoButton *cancelButton;

@end
