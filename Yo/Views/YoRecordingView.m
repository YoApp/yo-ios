//
//  YoRecordingView.m
//  Yo
//
//  Created by Peter Reveles on 7/17/15.
//
//

#import "YoRecordingView.h"

@interface YoRecordingView ()
@property (nonatomic, strong) NSMutableArray *constraints;
@end

@implementation YoRecordingView

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (instancetype)init {
    return [self initWithStyle:YoRecordingViewSendAndCancelStyle];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitWithStyle:YoRecordingViewSendAndCancelStyle];
    }
    return self;
}

- (instancetype)initWithStyle:(YoRecordingViewStyle)style {
    self = [super init];
    if (self) {
        [self commonInitWithStyle:style];
    }
    return self;
}

- (void)commonInitWithStyle:(YoRecordingViewStyle)style {
    _style = style;
    
    UIFont *standardButtonFont = [UIFont fontWithName:@"Montserrat-Bold" size:24];
    
    YoButton *sendButton = [[YoButton alloc] init];
    sendButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
    sendButton.layer.cornerRadius = 0.0f;
    sendButton.titleLabel.font = standardButtonFont;
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [self addSubview:sendButton];
    _sendButton = sendButton;
    
    YoButton *cancelButton = [[YoButton alloc] init];
    cancelButton.layer.cornerRadius = 0.0f;
    cancelButton.titleLabel.font = standardButtonFont;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    [self addSubview:cancelButton];
    _cancelButton = cancelButton;
}

- (void)setStyle:(YoRecordingViewStyle)style {
    if (_style != style) {
        _style = style;
        [self invalidateConstraints];
    }
}

- (void)updateConstraints {
    if (_constraints) {
        [super updateConstraints];
        return;
    }
    
    _constraints = [[NSMutableArray alloc] init];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_sendButton, _cancelButton);
    
    [_constraints addObjectsFromArray:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[_sendButton]|"
      options:0 metrics:nil views:views]];
    
    if (_style == YoRecordingViewSendAndCancelStyle) {
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[_cancelButton][_sendButton(_cancelButton)]|"
          options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom
          metrics:nil views:views]];
    }
    else {
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[_cancelButton][_sendButton(0)]|"
          options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom
          metrics:nil views:views]];
    }
    
    [self addConstraints:_constraints];
    [super updateConstraints];
}

- (void)invalidateConstraints {
    if (_constraints) {
        [self removeConstraints:_constraints];
    }
    _constraints = nil;
    [self setNeedsUpdateConstraints];
}


@end
