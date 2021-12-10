//
//  YONotificationView.m
//  Yo
//
//  Created by Or Arbel on 5/24/14.
//
//

#import "YoView.h"

#define StandardPadding 8.0f
#define StandardLineHeight 18.0f

@interface YoView ()
@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIButton *openButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *notificationContainerView;
@property (weak, nonatomic) IBOutlet UIView *actionsContainerView;
@property (weak, nonatomic) IBOutlet UIView *seperator;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *openButtonLeftConstraint;
@property (nonatomic, strong) NSDate *dateReceived;
@end

@implementation YoView

- (void)awakeFromNib {
    [super awakeFromNib];
    if (!IS_OVER_IOS(8.0)) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    }
    // set fonts
    UIFont *font = [UIFont systemFontOfSize:15.0];
    [self.textLabel setFont:font];
    [self.appNameLabel setFont:font];
    [self.dateLabel setFont:font];
    UIFont *buttonLabelFont = [UIFont fontWithName:@"Montserrat-Regular" size:14];
    [self.closeButton.titleLabel setFont:buttonLabelFont];
    [self.openButton.titleLabel setFont:buttonLabelFont];
    // set titles
    [self.closeButton setTitle:NSLocalizedString(@"dismiss", nil).capitalizedString forState:UIControlStateNormal];
    [self.openButton setTitle:NSLocalizedString(@"open", nil).capitalizedString forState:UIControlStateNormal];
    [self.appNameLabel setText:NSLocalizedString(@"yo", nil).capitalizedString];
    [self.dateLabel setText:nil]; // should only display intended text
}

- (NSDictionary *)getAttributesForTextLabel {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = 6.0f;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:15.0],
                                 NSParagraphStyleAttributeName:paragraphStyle};
    return attributes;
}

#pragma mark Actions

- (IBAction)closeButtonTouchedUpInside:(UIButton *)sender {
    if (self.actionDelegate) {
        [self.actionDelegate closeButtonTouchedUpInsideInYoView:self];
    }
}

- (IBAction)openButtonTouchedUpInside:(UIButton *)sender {
    if (self.actionDelegate) {
        [self.actionDelegate openButtonTouchedUpInsideInYoView:self];
    }
}

#pragma mark Setters 

- (void)setDisplayText:(NSString *)displayText {
    _displayText = displayText;
    [self updateDisplayLabelWithText:displayText];
}

- (void)setRequiresOpen:(BOOL)requiresOpen {
    if (_requiresOpen != requiresOpen) {
        _requiresOpen = requiresOpen;
        if (requiresOpen) {
            [self.closeButton removeFromSuperview];
            [self removeConstraint:self.openButtonLeftConstraint];
            self.openButtonLeftConstraint = [NSLayoutConstraint
                                             constraintWithItem:self attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.openButton attribute:NSLayoutAttributeLeft
                                             multiplier:1.0f constant:-StandardPadding];
            [self addConstraint:self.openButtonLeftConstraint];
        }
        else {
            [self.actionsContainerView addSubview:self.closeButton];
            [self removeConstraint:self.openButtonLeftConstraint];
            self.openButtonLeftConstraint = [NSLayoutConstraint
                                             constraintWithItem:self.closeButton attribute:NSLayoutAttributeRight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self.openButton attribute:NSLayoutAttributeLeft
                                             multiplier:1.0f constant:-StandardPadding];
            [self addConstraint:self.openButtonLeftConstraint];
        }
    }
}

#pragma mark Overrides

- (void)updateFrameToFitContent {
    // get height for label
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat ratio = width/320.0;
    CGFloat availableWidthForText = self.textLabel.width * ratio;
    CGFloat heightThatFitsText = [self getHeightToLabel:self.textLabel inWidth:availableWidthForText];
    heightThatFitsText = MAX(self.textLabel.height, heightThatFitsText);
    CGFloat defaultHeight = self.actionsContainerView.height + self.seperator.height  + self.notificationContainerView.height;
    CGFloat heightMinusLabel = defaultHeight - self.textLabel.height;
    CGFloat height = heightMinusLabel + heightThatFitsText;
    CGRect frameThatFits = CGRectMake(self.frame.origin.x,
                                      self.frame.origin.y,
                                      width,
                                      height);
    self.frame = frameThatFits;
}

#pragma Internal

- (void)updateDisplayLabelWithText:(NSString *)text {
    // Style
    NSDictionary *attributes = [self getAttributesForTextLabel];
    NSAttributedString *attributedDisplayText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    // Set
    self.textLabel.attributedText = attributedDisplayText;
}

- (NSUInteger)numberOfLinesRequiredToDisplayText:(NSString *)text withFont:(UIFont *)font inWidth:(CGFloat)maxWidth{
    CGSize textDisplaySize = CGSizeZero;
    
    if (![text length] || !font || !maxWidth) return 0.0;
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:[self getAttributesForTextLabel]
                                     context:nil];
    textDisplaySize = rect.size;
    
    NSUInteger linesRequiredBasedOfTextSize = ceil(textDisplaySize.height/23.895);
    
    NSUInteger linesRequired = linesRequiredBasedOfTextSize;
    
    return linesRequired;
}

- (CGFloat)getHeightToLabel:(UILabel *)label inWidth:(CGFloat)width {
    NSInteger numberOfLines = [self numberOfLinesRequiredToDisplayText:label.text withFont:label.font inWidth:width];
    CGFloat heightThatFits = numberOfLines * self.textLabel.height;
    return heightThatFits;
}

@end
