//
//  YoContactTableViewCell.m
//  Yo
//
//  Created by Peter Reveles on 7/14/15.
//
//

#import "YoUserTableViewCell.h"
#import "YoThemeManager.h"

@interface YoModelObject (YoUserTableViewCell)
- (NSString *)getLastYoStatusWithDate;
@end

@interface YoUserTableViewCell ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIView *userDataView;
@property (nonatomic, strong) YoLabel *nameLabel;
@property (nonatomic, strong) YoLabel *lastYoStatusLabel;

@property (nonatomic, strong) YoModelObject *user;
@property (nonatomic, strong) NSMutableArray *userDataViewConstraints;
@property (nonatomic, assign) UIEdgeInsets contentInsets;
@property (nonatomic, assign) BOOL isFlashingText;
@property (nonatomic, assign) BOOL isIndicatingProgress;
@end

@implementation YoUserTableViewCell

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)commonInIt {
    self.backgroundView = [[UIView alloc] init];
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14f];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        UIView *contentView = self.contentView;
        
        _activityIndicatorView = [[UIActivityIndicatorView alloc] init];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _activityIndicatorView.hidesWhenStopped = YES;
        _activityIndicatorView.hidden = YES;
        _activityIndicatorView.center = self.contentView.center;
        _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [contentView addSubview:_activityIndicatorView];
        
        _placeholderLabel = [[YoLabel alloc] initWithFrame:self.contentView.frame];
        _placeholderLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:36];
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderLabel.adjustsFontSizeToFitWidth = YES;
        _placeholderLabel.minimumScaleFactor = 0.5;
        _placeholderLabel.textColor = [[YoThemeManager sharedInstance] textColor];
        _placeholderLabel.hidden = YES;
        _placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [contentView addSubview:_placeholderLabel];
        
        _progressView = [[UIView alloc] initWithFrame:self.contentView.frame];
        _progressView.backgroundColor = [UIColor redColor];
        _progressView.hidden = YES;
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [contentView addSubview:_progressView];
        
        _userDataView = [[UIView alloc] initWithFrame:self.contentView.frame];
        _userDataView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [contentView addSubview:_userDataView];
        
        // Initialization code
        _nameLabel = [[YoLabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.numberOfLines = 1;
        _nameLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:36];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        _nameLabel.minimumScaleFactor = 0.5;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = [[YoThemeManager sharedInstance] textColor];
        [_userDataView addSubview:_nameLabel];
        
        _lastYoStatusLabel = [[YoLabel alloc] init];
        _lastYoStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _lastYoStatusLabel.numberOfLines = 1;
        _lastYoStatusLabel.textColor = [[YoThemeManager sharedInstance] textColor];
        _lastYoStatusLabel.textAlignment = NSTextAlignmentCenter;
        _lastYoStatusLabel.alpha = 0.0f;
        _lastYoStatusLabel.hidden = YES;
        _lastYoStatusLabel.font = [UIFont fontWithName:@"Montserrat-Regular" size:11];
        [_userDataView addSubview:_lastYoStatusLabel];
        
        [self commonInIt];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.user = nil;
    [self stopAnimatingActivityIndicator];
    [self stopIndicatingProgress];
    [self hidePlaceHolder];
}

- (void)congifureForUser:(YoModelObject *)user {
    _user = user;
    _nameLabel.text = user.displayName;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    // Configure the view for the highlighted state
    _nameLabel.highlighted = highlighted;
    _lastYoStatusLabel.highlighted = highlighted;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    if (UIEdgeInsetsEqualToEdgeInsets(contentInsets, _contentInsets))
        return;
    _contentInsets = contentInsets;
    [self invalidateConstraints];
}

- (void)updateConstraints
{
    if (_userDataViewConstraints) {
        [super updateConstraints];
        return;
    }
    
    CGFloat height = CGRectGetHeight(self.userDataView.frame);
    
    CGFloat nameLabelVerticalPadding = (height - _nameLabel.font.lineHeight)/2.0f;
    CGFloat topPaddingLastYoStatusLabel = (height - _lastYoStatusLabel.font.lineHeight) - 8;
    
    _userDataViewConstraints = [NSMutableArray array];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_nameLabel, _lastYoStatusLabel);
    NSDictionary *metrics = @{
                              @"Left" : @(15),
                              @"Right" : @(15),
                              @"Bottom" : @(8),
                              @"vertical_padding_namelabel" : @(nameLabelVerticalPadding),
                              @"topPaddingLastYoStatusLabel" : @(topPaddingLastYoStatusLabel)
                              };
    
    [_userDataViewConstraints addObjectsFromArray:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|-Left-[_nameLabel]-Right-|"
      options:0 metrics:metrics views:views]];
    [_userDataViewConstraints addObjectsFromArray:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|-Left-[_lastYoStatusLabel]-Right-|"
      options:(NSLayoutFormatOptions) 0 metrics:metrics views:views]];
    [_userDataViewConstraints addObjectsFromArray:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|-vertical_padding_namelabel-[_nameLabel]-vertical_padding_namelabel-|"
      options:(NSLayoutFormatOptions) 0 metrics:metrics views:views]];
    
    [_userDataViewConstraints addObjectsFromArray:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:[_lastYoStatusLabel]-Bottom-|"
      options:(NSLayoutFormatOptions) 0 metrics:metrics views:views]];
    
    [_userDataView addConstraints:_userDataViewConstraints];
    [super updateConstraints];
}

- (void)invalidateConstraints
{
    if (_userDataViewConstraints) {
        [self.userDataView removeConstraints:_userDataViewConstraints];
    }
    _userDataViewConstraints = nil;
    [self setNeedsUpdateConstraints];
}

// last yo status

- (void)showLastYoStatus {
    self.lastYoStatusLabel.text = [self.user getLastYoStatusWithDate];
    
    if (self.lastYoStatusLabel.alpha != 1.0f) {
        self.lastYoStatusLabel.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.lastYoStatusLabel.alpha = 1.0f;
        }];
    }
}

- (void)hideLastYoStatus {
    if ([self isShowingLastYoStatus]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.lastYoStatusLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.lastYoStatusLabel.hidden = YES;
        }];
    }
}

- (BOOL)isShowingLastYoStatus {
    return self.lastYoStatusLabel.hidden == NO;
}

#pragma mark - Base

// Activity Indicating

- (void)startAnimatingActivityIndicator {
    [self.contentView bringSubviewToFront:_activityIndicatorView];
    _userDataView.hidden = YES;
    _activityIndicatorView.hidden = NO;
    [_activityIndicatorView startAnimating];
}

- (void)stopAnimatingActivityIndicator {
    _activityIndicatorView.hidden = YES;
    _userDataView.hidden = NO;
}

- (BOOL)isAnimatingActivityIndicator {
    return _activityIndicatorView.hidden == NO;
}

// Message Flashing (1.5)

- (void)flashText:(NSString *)text forDuration:(NSTimeInterval)duration completionHandler:(void (^)())handler {
    if (duration <= 0) {
        return;
    }
    
    _isFlashingText = YES;
    
    [self showPlaceHolderWithText:text];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        [self hidePlaceHolder];
        _isFlashingText = NO;
        if (handler) {
            handler();
        }
    });
}

- (void)showPlaceHolderWithText:(NSString *)text {
    _placeholderLabel.text = text;
    if ([self isShowingPlaceholder] == NO) {
        [self.contentView bringSubviewToFront:_placeholderLabel];
        _userDataView.hidden = YES;
        _placeholderLabel.hidden = NO;
    }
}

- (void)hidePlaceHolder {
    if ([self isShowingPlaceholder]) {
        _placeholderLabel.text = nil;
        _userDataView.hidden = NO;
        _placeholderLabel.hidden = YES;
    }
}

- (BOOL)isShowingPlaceholder {
    return _placeholderLabel.hidden == NO;
}

// Progress Indicating (4.0)

- (void)indicateProgressWithDuration:(NSTimeInterval)duration {
    
    [self stopIndicatingProgress];
    
    self.isIndicatingProgress = YES;
    
    _progressView.width = 0.0f;
    
    _progressView.hidden = NO;
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         _progressView.width = self.width;
                     } completion:^(BOOL finished) {
                         _progressView.hidden = YES;
                     }];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    _progressView.width = self.width;
    _progressView.hidden = YES;
    self.isIndicatingProgress = NO;
}

- (void)stopIndicatingProgress {
    _progressView.width = self.width;
    _progressView.hidden = YES;
    self.isIndicatingProgress = NO;
}

@end

@implementation YoModelObject (YoUserTableViewCell)

- (NSString *)getLastYoStatusWithDate {
    if (self.lastYoStatus != nil &&
        self.lastYoDate != nil &&
        [self.lastYoStatus isEqualToString:@"Received"] == NO) {
        return MakeString(@"%@ - %@", [self getStatusStringForStatus:self.lastYoStatus], [self.lastYoDate agoString]);
    }
    return nil;
}

@end