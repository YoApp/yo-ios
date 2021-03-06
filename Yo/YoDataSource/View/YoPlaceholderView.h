/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import <UIKit/UIKit.h>
@class FLAnimatedImageView;
@class FLAnimatedImage;

/// A placeholder view that approximates the standard iOS no content view.
@interface YoPlaceholderView : UIView

@property (nonatomic, strong, readonly) FLAnimatedImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *messageLabel;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) FLAnimatedImage *animatedImage;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, copy) NSString *buttonTitle;
@property (nonatomic, copy) void (^buttonAction)(void);

/// Initialize a placeholder view. A message is required in order to display a button.
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message image:(UIImage *)image buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction;

/// Initialize a placeholder view. A message is required in order to display a button.
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message animatedImage:(FLAnimatedImage *)animatedImage buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction;

@end

/// A placeholder view for use in the collection view. This placeholder includes the loading indicator.
@interface YoCollectionPlaceholderView : UICollectionReusableView

@property (nonatomic, strong, readonly) YoPlaceholderView *placeholderView;

- (void)showActivityIndicator:(BOOL)show;
- (void)showPlaceholderWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animated:(BOOL)animated;
- (void)hidePlaceholderAnimated:(BOOL)animated;

@end


/// A placeholder cell. Used when it's not appropriate to display the full size placeholder view in the collection view, but a smaller placeholder is desired.
@interface YoPlaceholderCell : UICollectionViewCell

@property (nonatomic, strong, readonly) YoPlaceholderView *placeholderView;

- (void)showPlaceholderWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animated:(BOOL)animated;
- (void)hidePlaceholderAnimated:(BOOL)animated;

@end
