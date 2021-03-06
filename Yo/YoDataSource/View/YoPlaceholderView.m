/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoPlaceholderView.h"
#import "FLAnimatedImage.h"

#define CORNER_RADIUS 3.0
#define CONTINUOUS_CURVES_SIZE_FACTOR (1.528665)
#define BUTTON_WIDTH 124
#define BUTTON_HEIGHT 29

@interface YoPlaceholderView ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong, readwrite) FLAnimatedImageView *imageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) NSArray *constraints;
@end

@implementation YoPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame
{
    NSAssert(NO, @"-[YoPlaceholderView initWithFrame:] will not return a usable view");
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message animatedImage:(FLAnimatedImage *)animatedImage buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction {
    self = [super initWithFrame:frame];
    if (!self)
        return self;
    
    [self commonInitWithTitle:title message:message image:nil animatedImage:animatedImage buttonTitle:buttonTitle buttonAction:buttonAction];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message image:(UIImage *)image buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction
{
    self = [super initWithFrame:frame];
    if (!self)
        return self;
    
    [self commonInitWithTitle:title message:message image:image animatedImage:nil buttonTitle:buttonTitle buttonAction:buttonAction];
    
    return self;
}

- (void)commonInitWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction {
    _title = [title copy];
    _message = [message copy];
    _image = image;
    _animatedImage = animatedImage;
    
    if (buttonTitle && buttonAction) {
        NSAssert(message != nil, @"a message must be provided when using a button");
        _buttonTitle = [buttonTitle copy];
        _buttonAction = [buttonAction copy];
    }
    
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _containerView = [[UIView alloc] initWithFrame:CGRectZero];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //UIColor *textColor = [UIColor colorWithWhite:172/255.0 alpha:1];
    UIColor *textColor = [UIColor whiteColor];
    
    if (animatedImage) {
        _imageView = [[FLAnimatedImageView alloc] init];
        _imageView.animatedImage = animatedImage;
    }
    else {
        _imageView = [[FLAnimatedImageView alloc] initWithImage:_image];
    }
    
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.backgroundColor = nil;
    _titleLabel.opaque = NO;
    //_titleLabel.font = [UIFont systemFontOfSize:22.0];
    _titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:22.0f];
    _titleLabel.numberOfLines = 0;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = textColor;
    [_containerView addSubview:_titleLabel];
    
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.opaque = NO;
    _messageLabel.backgroundColor = nil;
    //_messageLabel.font = [UIFont systemFontOfSize:14];
    _messageLabel.font = [UIFont fontWithName:@"Montserrat-Regular" size:14.0f];
    _messageLabel.numberOfLines = 0;
    _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _messageLabel.textColor = textColor;
    [_containerView addSubview:_messageLabel];
    
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_actionButton addTarget:self action:@selector(_actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_actionButton setFrame:CGRectMake(0, 0, 124, 29)];
    //_actionButton.titleLabel.font = [UIFont systemFontOfSize:14];
    _actionButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Regular" size:14.0f];
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    _actionButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    [_actionButton setBackgroundImage:[self _buttonBackgroundImageWithColor:textColor] forState:UIControlStateNormal];
    [_actionButton setTitleColor:textColor forState:UIControlStateNormal];
    [_containerView addSubview:_actionButton];
    
    [self addSubview:_containerView];
    
    [self _updateViewHierarchy];
    
    // Constrain the container to the host view. The height of the container will be determined by the contents.
    NSMutableArray *constraints = [NSMutableArray array];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        // _containerView should be no more than 418pt and the left and right padding should be no less than 30pt on both sides
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=30)-[_containerView(<=418)]-(>=30)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_containerView)]];
    else
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-30-[_containerView]-30-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_containerView)]];
    
    [self addConstraints:constraints];
}

- (UIImage *)_buttonBackgroundImageWithColor:(UIColor *)color
{
    static UIImage *backgroundImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        CGFloat cornerRadius = CORNER_RADIUS;

        CGFloat capSize = ceilf(cornerRadius * CONTINUOUS_CURVES_SIZE_FACTOR);
        CGFloat rectSize = 2.0 * capSize + 1.0;
        CGRect rect = CGRectMake(0.0, 0.0, rectSize, rectSize);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);

        // pull in the stroke a wee bit
        CGRect pathRect = CGRectInset(rect, 0.5, 0.5);
        cornerRadius -= 0.5;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathRect cornerRadius:cornerRadius];

        [color set];
        [path stroke];

        backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(capSize, capSize, capSize, capSize)];
    });

    return backgroundImage;
}

- (void)_updateViewHierarchy
{
    if (_image || _animatedImage) {
        [_containerView addSubview:_imageView];
        if (_image) {
            _imageView.image = _image;
        }
        else {
            _imageView.animatedImage = _animatedImage;
        }
    }
    else
        [_imageView removeFromSuperview];

    if (_title) {
        [_containerView addSubview:_titleLabel];
        _titleLabel.text = _title;
    }
    else
        [_titleLabel removeFromSuperview];

    if (_message) {
        [_containerView addSubview:_messageLabel];
        _messageLabel.text = _message;
    }
    else
        [_messageLabel removeFromSuperview];

    if (_buttonTitle) {
        [_containerView addSubview:_actionButton];
        [_actionButton setTitle:_buttonTitle forState:UIControlStateNormal];
    }
    else {
        [_actionButton removeFromSuperview];
    }

    if (_constraints)
        [_containerView removeConstraints:_constraints];
    _constraints = nil;
    [self setNeedsUpdateConstraints];
}

- (void)setImage:(UIImage *)image
{
    if ([image isEqual:_image])
        return;

    _image = image;
    [self _updateViewHierarchy];
}

- (void)setAnimatedImage:(FLAnimatedImage *)animatedImage
{
    if ([animatedImage isEqual:_animatedImage])
        return;
    
    _animatedImage = animatedImage;
    [self _updateViewHierarchy];
}

- (void)setTitle:(NSString *)title
{
    NSAssert(title && [title length], @"Title cannot be nil or empty");

    if ([title isEqualToString:_title])
        return;

    _title = [title copy];

    [self _updateViewHierarchy];
}

- (void)setMessage:(NSString *)message
{
    if ([message isEqualToString:_message])
        return;

    _message = [message copy];

    [self _updateViewHierarchy];
}

- (void)setButtonTitle:(NSString *)buttonTitle
{
    if ([buttonTitle isEqualToString:_buttonTitle])
        return;

    _buttonTitle = [buttonTitle copy];

    [self _updateViewHierarchy];
}

- (void)_actionButtonPressed:(id)sender
{
    if (self.buttonAction)
        self.buttonAction();
}

- (void)updateConstraints
{
    if (_constraints) {
        [super updateConstraints];
        return;
    }

    NSMutableArray *constraints = [NSMutableArray array];

    NSDictionary *views = NSDictionaryOfVariableBindings(_imageView, _titleLabel, _messageLabel, _actionButton);
    UIView *last = _containerView;
    NSLayoutAttribute lastAttr = NSLayoutAttributeTop;
    CGFloat constant = 0;

    if (_imageView.superview) {
        // Force the container to be at least as wide as the image
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_imageView]-(>=0)-|" options:0 metrics:nil views:views]];
        // horizontally center the image
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        // aligned with the top of the container
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];

        last = _imageView;
        lastAttr = NSLayoutAttributeBottom;
        constant = 15; // spec calls for 20pt space, but when set to 20pt, there's 25pts of space between the bottom of the image and the top of the text.
    }

    if (_titleLabel.superview) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|" options:0 metrics:nil views:views]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:last attribute:lastAttr multiplier:1.0 constant:constant]];

        last = _titleLabel;
        lastAttr = NSLayoutAttributeBaseline;
        constant = 15; // spec calls for 20pt space, but when set to 20pt, there's 25pts of space between the baseline of the title and the message.
    }

    if (_messageLabel.superview) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_messageLabel]|" options:0 metrics:nil views:views]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_messageLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:last attribute:lastAttr multiplier:1.0 constant:constant]];

        last = _messageLabel;
        lastAttr = NSLayoutAttributeBaseline;
        constant = 20;
    }

    if (_actionButton.superview) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:last attribute:lastAttr multiplier:1.0 constant:constant]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:BUTTON_WIDTH]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:BUTTON_HEIGHT]];

        last = _actionButton;
    }

    // link the bottom of the last view with the bottom of the container to provide the size of the container
    [constraints addObject:[NSLayoutConstraint constraintWithItem:last attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

    [_containerView addConstraints:constraints];
    _constraints = constraints;

    [super updateConstraints];
}

@end


@interface YoCollectionPlaceholderView ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) YoPlaceholderView *placeholderView;
@end

@implementation YoCollectionPlaceholderView

- (void)showActivityIndicator:(BOOL)show
{
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _activityIndicatorView.color = [UIColor whiteColor];

        [self addSubview:_activityIndicatorView];
        NSMutableArray *constraints = [NSMutableArray array];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [self addConstraints:constraints];
    }

    _activityIndicatorView.hidden = !show;

    if (show)
        [_activityIndicatorView startAnimating];
    else
        [_activityIndicatorView stopAnimating];
}

- (void)hidePlaceholderAnimated:(BOOL)animated
{
    YoPlaceholderView *placeholderView = _placeholderView;

    if (!placeholderView)
        return;

    if (animated) {

        [UIView animateWithDuration:0.25 animations:^{
            placeholderView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [placeholderView removeFromSuperview];
            // If it's still the current placeholder, get rid of it
            if (placeholderView == _placeholderView)
                self.placeholderView = nil;
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            [placeholderView removeFromSuperview];
            if (_placeholderView == placeholderView)
                self.placeholderView = nil;
        }];
    }
}

- (void)showPlaceholderWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animated:(BOOL)animated
{
    YoPlaceholderView *oldPlaceHolder = self.placeholderView;

    if (oldPlaceHolder && [oldPlaceHolder.title isEqualToString:title] && [oldPlaceHolder.message isEqualToString:message])
        return;

    [self showActivityIndicator:NO];

    self.placeholderView = [[YoPlaceholderView alloc] initWithFrame:CGRectZero title:title message:message image:image buttonTitle:nil buttonAction:nil];
    _placeholderView.alpha = 0.0;
    _placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_placeholderView];

    NSMutableArray *constraints = [NSMutableArray array];
    NSDictionary *views = NSDictionaryOfVariableBindings(_placeholderView);

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_placeholderView]|" options:0 metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_placeholderView]|" options:0 metrics:nil views:views]];

    [self addConstraints:constraints];
    [self sendSubviewToBack:_placeholderView];

    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            _placeholderView.alpha = 1.0;
            oldPlaceHolder.alpha = 0.0;
        } completion:^(BOOL finished) {
            [oldPlaceHolder removeFromSuperview];
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            _placeholderView.alpha = 1.0;
            oldPlaceHolder.alpha = 0.0;
            [oldPlaceHolder removeFromSuperview];
        }];
    }
}

@end


@interface YoPlaceholderCell ()
@property (nonatomic, strong, readwrite) YoPlaceholderView *placeholderView;
@end

@implementation YoPlaceholderCell

- (void)hidePlaceholderAnimated:(BOOL)animated
{
    YoPlaceholderView *placeholderView = _placeholderView;

    if (!placeholderView)
        return;

    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            placeholderView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [placeholderView removeFromSuperview];
            // If it's still the current placeholder, get rid of it
            if (placeholderView == _placeholderView)
                self.placeholderView = nil;
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            [placeholderView removeFromSuperview];
            if (_placeholderView == placeholderView)
                self.placeholderView = nil;
        }];
    }
}

- (void)showPlaceholderWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animated:(BOOL)animated
{
    UIView *contentView = self.contentView;

    YoPlaceholderView *oldPlaceHolder = self.placeholderView;

    if (oldPlaceHolder && [oldPlaceHolder.title isEqualToString:title] && [oldPlaceHolder.message isEqualToString:message])
        return;

    self.placeholderView = [[YoPlaceholderView alloc] initWithFrame:CGRectZero title:title message:message image:image buttonTitle:nil buttonAction:nil];
    _placeholderView.alpha = 0.0;
    _placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:_placeholderView];

    NSMutableArray *constraints = [NSMutableArray array];
    NSDictionary *views = NSDictionaryOfVariableBindings(_placeholderView);

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_placeholderView]|" options:0 metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_placeholderView]|" options:0 metrics:nil views:views]];

    [contentView addConstraints:constraints];
    [contentView sendSubviewToBack:_placeholderView];

    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            _placeholderView.alpha = 1.0;
            oldPlaceHolder.alpha = 0.0;
        } completion:^(BOOL finished) {
            [oldPlaceHolder removeFromSuperview];
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            _placeholderView.alpha = 1.0;
            oldPlaceHolder.alpha = 0.0;
            [oldPlaceHolder removeFromSuperview];
        }];
    }
}

@end
