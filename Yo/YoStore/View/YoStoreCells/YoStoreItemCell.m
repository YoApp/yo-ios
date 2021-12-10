//
//  YoStoreItemCell.m
//  Yo
//
//  Created by Or Arbel on 2/14/15.
//
//

#import "YoStoreItemCell.h"

@interface YoStoreItemCell ()
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *subscribeButtonConstraints;
@end

@implementation YoStoreItemCell

@synthesize nameLabel;

//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        // setup
//        [self performInitialConfiguration];
//    }
//    return self;
//}
//
//- (instancetype)initWithCoder:(NSCoder *)aDecoder {
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        // setup
//        [self performInitialConfiguration];
//    }
//    return self;
//}
//
//- (instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        // setup
//        [self performInitialConfiguration];
//    }
//    return self;
//}
//
//- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self) {
//        // setup
//        [self performInitialConfiguration];
//    }
//    return self;
//}

- (void)awakeFromNib {
    self.profileImageView.layer.cornerRadius = self.profileImageView.width/2.0;
    self.profileImageView.layer.masksToBounds = YES;
    
    self.subscribeButton.style = YoStoreButtonStyleBordered;
    [self.subscribeButton addTarget:self action:@selector(subscribeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.subscribeButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:12.0f];
    [self.subscribeButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
    
    [self.detailsButton addTarget:self action:@selector(detailsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.nameLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:16.0f];
    self.descriptionLabel.font = [UIFont fontWithName:@"Montserrat" size:13.0f];
    
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor = 0.1f;
    
    self.detailsButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:12.0f];
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    CGFloat takenSpace = self.profileImageView.width + self.subscribeButton.width + self.needsLocationImageView.width + (8.0f * 4.0f) + 20.0f;
    
    [self addConstraint:
     [NSLayoutConstraint
      constraintWithItem:self.nameLabel attribute:NSLayoutAttributeWidth
      relatedBy:NSLayoutRelationLessThanOrEqual
      toItem:self attribute:NSLayoutAttributeWidth
      multiplier:1.0 constant:-takenSpace]];
    
    YoABTestOption option = [[YoABTestingFrameWork sharedInstance] optionForTest:YoABTestShowDetailsButton];
    switch (option) {
        case YoABTestOptionA:
            self.detailsButton.hidden = NO;
            break;
            
        case YoABTestOptionB:
            self.detailsButton.hidden = YES;
            break;
            
        default:
            break;
    }
}

- (void)addSubscribeButton {
    YoStoreButton *subscribeButton = [YoStoreButton new];
    subscribeButton.translatesAutoresizingMaskIntoConstraints = NO;
    subscribeButton.style = YoStoreButtonStyleBordered;
    [subscribeButton addTarget:self action:@selector(subscribeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    subscribeButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:12.0f];
    [subscribeButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
    
    [self addSubview:subscribeButton];
    self.subscribeButton = subscribeButton;
    
    // constraints
    // right
    NSMutableArray *subscribeButtonConstraints = [NSMutableArray new];
    [subscribeButtonConstraints
     addObject:[NSLayoutConstraint
                constraintWithItem:subscribeButton attribute:NSLayoutAttributeRight
                relatedBy:NSLayoutRelationEqual
                toItem:self attribute:NSLayoutAttributeRight
                multiplier:1.0f constant:-8.0f]];
    
    // left
    [subscribeButtonConstraints
     addObject:[NSLayoutConstraint
                constraintWithItem:subscribeButton attribute:NSLayoutAttributeLeft
                relatedBy:NSLayoutRelationGreaterThanOrEqual
                toItem:self.needsLocationImageView attribute:NSLayoutAttributeRight
                multiplier:1.0f constant:-8.0f]];
    
    // Y position
    [subscribeButtonConstraints
     addObject:[NSLayoutConstraint
                constraintWithItem:subscribeButton attribute:NSLayoutAttributeTop
                relatedBy:NSLayoutRelationEqual
                toItem:self.profileImageView attribute:NSLayoutAttributeTop
                multiplier:1.0f constant:4.0f]];
    
    [subscribeButtonConstraints
     addObject:[NSLayoutConstraint
                constraintWithItem:self.nameLabel attribute:NSLayoutAttributeCenterY
                relatedBy:NSLayoutRelationEqual
                toItem:subscribeButton attribute:NSLayoutAttributeCenterY
                multiplier:1.0f constant:0.0f]];
    
    [subscribeButtonConstraints
     addObject:[NSLayoutConstraint
                constraintWithItem:self.descriptionLabel attribute:NSLayoutAttributeTop
                relatedBy:NSLayoutRelationEqual
                toItem:subscribeButton attribute:NSLayoutAttributeBottom
                multiplier:1.0f constant:2.0f]];
    
    [self addConstraints:subscribeButtonConstraints];
    //[subscribeButton sizeToFit];
    self.subscribeButtonConstraints = subscribeButtonConstraints;
}

- (void)prepareForReuse {
    self.needsLocationImageView.hidden = YES;
    self.isVerifiedImageView.hidden = YES;
    self.profileImageView.image = nil;
    
    [self removeConstraints:self.subscribeButtonConstraints];
    [self.subscribeButton removeFromSuperview];
    [self addSubscribeButton];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    //self.detailsButton.tintColor = backgroundColor;
}

- (void)subscribeButtonTapped:(UIButton *)subscribeButton {
    if (self.subscribeButtonTappedBlock) {
        self.subscribeButtonTappedBlock(self);
    }
}

- (void)detailsButtonTapped:(UIButton *)detailsButton {
    if (self.detailsButtonTappedBlock) {
        self.detailsButtonTappedBlock(self);
    }
}

@end
