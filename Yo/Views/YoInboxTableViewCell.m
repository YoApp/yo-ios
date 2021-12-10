//
//  YoInboxYoTableViewCell.m
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "YoInboxTableViewCell.h"
#import "Yo.h"

NSString *const YoExceptionInValidCellTypeForYo = @"YoExceptionInValidCellTypeForYo";

@interface YoInboxTableViewCell ()
@property (nonatomic, strong, readwrite) UILabel *senderLabel;
@property (nonatomic, strong, readwrite) UILabel *sentDateLabel;
@property (nonatomic, strong, readwrite) UILabel *bottomRightLabel;
@property (nonatomic, strong) NSMutableArray *constraints;
@property (nonatomic, strong) NSLayoutConstraint *yoPreviewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yoPreviewHeightConstraint;
@end

@implementation YoInboxTableViewCell

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.senderLabel = [[UILabel alloc] init];
        self.senderLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.senderLabel.numberOfLines = 0;
        self.senderLabel.font = [UIFont fontWithName:MontserratBold size:17.0f];
        self.senderLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.senderLabel];
        
        self.sentDateLabel = [[UILabel alloc] init];
        self.sentDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.sentDateLabel.numberOfLines = 1;
        self.sentDateLabel.font = [UIFont fontWithName:MontserratRegular size:14.0f];
        self.sentDateLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.sentDateLabel];
        
        self.bottomRightLabel = [[UILabel alloc] init];
        self.bottomRightLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.bottomRightLabel.numberOfLines = 1;
        self.bottomRightLabel.font = [UIFont fontWithName:MontserratRegular size:7.0f];
        self.bottomRightLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.bottomRightLabel];
        
        self.contentInsets = UIEdgeInsetsMake(10.0f, 17.0f, 10.0f, 17.0f);
    }
    return self;
}

//- (void)updatePreviewConstraints {
//    CGSize size = [self sizeForImageType:self.yoImageSizeType];
//    self.yoPreviewWidthConstraint.constant = size.width;
//    self.yoPreviewHeightConstraint.constant = size.height;
//}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.senderLabel.text = nil;
    self.sentDateLabel.text = nil;
    self.bottomRightLabel.text = nil;
    
    //// The ordering of the following instructions matters
    self.rightUtilityButtons = nil;
    self.leftUtilityButtons = nil;
//    //// This next line needs to be called last.
//    [self invalidateConstraints];
}

- (void)configureForYo:(Yo *)yo {
    self.senderLabel.text = yo.body;
    self.sentDateLabel.text = [yo.creationDate agoString];
}

- (CGSize)sizeForImageType:(YoTVCSizeType)type {
    switch (type) {
        case YoTVCSizeTypeLandscape:
            return CGSizeMake(120.0f, 80.0f);
            break;
            
        case YoTVCSizeTypeNone:
            return CGSizeZero;
            break;
            
        case YoTVCSizeTypePortrait:
            return CGSizeMake(80.0f, 120.0f);
            break;
            
        case YoTVCSizeTypeSquare:
            return CGSizeMake(80.0f, 80.0f);
            break;
            
        default:
            return CGSizeZero;
            break;
    }
}

//- (YoTVCImageSizeType)sizeTypeForImage:(UIImage *)image {
//    
//    if (image == nil) {
//        return YoTVCImageSizeTypeNone;
//    }
//    
//    BOOL isSquare = image.size.width == image.size.height;
//    if (isSquare) {
//        return YoTVCImageSizeTypeSquare;
//    }
//
//    BOOL isPortait = image.size.width < image.size.height;
//    if (isPortait) {
//        return YoTVCImageSizeTypePortrait;
//    }
//
//    BOOL isLandscape = image.size.width > image.size.height;
//    if (isLandscape) {
//        return YoTVCImageSizeTypeLandscape;
//    }
//    
//    return YoTVCImageSizeTypeSquare; // default
//}

- (void)setYoPreview:(UIView *)yoPreview {
    yoPreview.translatesAutoresizingMaskIntoConstraints = NO;
    [yoPreview removeFromSuperview];
    
    _yoPreview = yoPreview;
    if (_yoPreview != nil) {
        [self.contentView addSubview:_yoPreview];
    }
    
    [self invalidateConstraints];
}

- (void)invalidateConstraints {
    if (self.constraints) {
        [self.contentView removeConstraints:self.constraints];
    }
    self.constraints = nil;
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    if (_constraints) {
        [super updateConstraints];
        return;
    }
    
    _constraints = [[NSMutableArray alloc] init];
    
    UIEdgeInsets contentInsets = self.contentInsets;
    
    CGFloat paddingBetweenText = 2.0f;
    
    if (self.yoPreview != nil) {
        CGSize yoPreviewSize = [self sizeForImageType:self.yoSizeType];
        
        NSDictionary *metrics = @{@"Left":@(contentInsets.left),
                                  @"Top":@(contentInsets.top),
                                  @"Right":@(contentInsets.right),
                                  @"Bottom":@(contentInsets.bottom),
                                  @"PreviewLeft":@(contentInsets.left),
                                  @"PreviewWidth":@(yoPreviewSize.width),
                                  @"PreviewHeight":@(yoPreviewSize.height),
                                  @"PaddingBetweenText":@(paddingBetweenText)};
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_yoPreview, _senderLabel, _sentDateLabel, _bottomRightLabel);
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|-Top-[_yoPreview(PreviewHeight@999)]-(>=Bottom)-|"
          options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
          metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|-PreviewLeft-[_yoPreview(PreviewWidth)]-Left-[_senderLabel]-Right-|"
          options:0 metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|-Top-[_senderLabel]-PaddingBetweenText-[_sentDateLabel]"
          options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
          metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:[_sentDateLabel]-(>=0)-[_bottomRightLabel]-Bottom-|"
          options:0 metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|-(>=Left)-[_bottomRightLabel]-Right-|"
          options:0 metrics:metrics views:views]];
    }
    else {
        NSDictionary *metrics = @{@"Left":@(contentInsets.left),
                                  @"Top":@(contentInsets.top),
                                  @"Right":@(contentInsets.right),
                                  @"Bottom":@(contentInsets.bottom),
                                  @"PaddingBetweenText":@(paddingBetweenText)};
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_senderLabel, _sentDateLabel, _bottomRightLabel);
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|-Left-[_senderLabel]-Right-|"
          options:0 metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|-Top-[_senderLabel]-PaddingBetweenText-[_sentDateLabel]"
          options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight
          metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:[_sentDateLabel]-(>=0)-[_bottomRightLabel]-Bottom-|"
          options:0 metrics:metrics views:views]];
        
        [self.constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|-(>=Left)-[_bottomRightLabel]-Right-|"
          options:0 metrics:metrics views:views]];
    }
    
    [self.contentView addConstraints:self.constraints];
    [super updateConstraints];
}

- (CGSize)yo_systemLayoutSizeFittingSize:(CGSize)targetSize {
    NSArray *constraints = @[
                             [NSLayoutConstraint
                              constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth
                              relatedBy:NSLayoutRelationLessThanOrEqual
                              toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                              multiplier:1.0 constant:targetSize.width],
                             [NSLayoutConstraint
                              constraintWithItem:self.contentView attribute:NSLayoutAttributeHeight
                              relatedBy:NSLayoutRelationLessThanOrEqual
                              toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                              multiplier:1.0 constant:UILayoutFittingExpandedSize.height]
                             ];
    [self.contentView addConstraints:constraints];
    [self layoutSubviews];
    CGSize size = [self.contentView systemLayoutSizeFittingSize:targetSize];
    [self.contentView removeConstraints:constraints];
    return size;
}


@end
