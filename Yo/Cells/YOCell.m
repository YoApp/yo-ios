//
//  YOCell.m
//  Yo
//
//  Created by Or Arbel on 2/28/14.
//
//

#import "YOCell.h"
#import "NSDate_Extentions.h"
#import "MobliConfigManager.h"
#import "YoThemeManager.h"
#import "YoGroup.h"
#import "YoConfigManager.h"

@interface YOCell ()

@property(nonatomic, assign)     CGPoint                firstPoint;

@property (nonatomic, assign)   CGFloat                 originalPanTapX;
@property (nonatomic, assign)   CGFloat                 originalProfileCenterX;

@property (weak, nonatomic)     IBOutlet UIView         *containerView;

@property (nonatomic) BOOL isAnimatingLongTapProgress;
@property (weak, nonatomic) IBOutlet UIView *paramountCell;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerLeftConstraint;

@property (nonatomic, assign) BOOL isAnimatingProfile;
@end

@implementation YOCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.label.font = [UIFont fontWithName:@"Montserrat-Bold" size:36];
    self.label.minimumScaleFactor = 0.5;
    self.label.numberOfLines = 1;
    self.label.textColor = [[YoThemeManager sharedInstance] textColor];
    
    self.aiView.hidden = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.yoObject = nil;
    self.containerLeftConstraint.constant = 0.0f;
    self.label.text = nil;
    self.label.hidden = NO;
    self.label.alpha = 1.0;
    self.statusLabel.text = nil;
    self.shouldShowActivityWhenTapped = NO;
    self.aiView.hidden = YES;
    self.progressView.hidden = YES;
}

- (void)showStatus {
    if (self.yoObject.lastYoStatus && self.yoObject.lastYoDate && ! [self.yoObject.lastYoStatus isEqualToString:@"Received"]) {
        self.statusLabel.text = MakeString(@"%@ - %@", [self.yoObject getStatusStringForStatus:self.yoObject.lastYoStatus], [self.yoObject.lastYoDate agoString]);
    }
    if (self.statusLabel.alpha != 1.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            self.statusLabel.alpha = 1.0f;
        }];
    }
}

- (void)hideStatus {
    if (self.statusLabel.alpha != 0.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            self.statusLabel.alpha = 0.0f;
        }];
    }
}

- (void)flashStatus {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.statusLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[YoConfigManager sharedInstance] timeForShowingStatus] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [UIView animateWithDuration:0.2 animations:^{
                                 self.statusLabel.alpha = 0.0;
                             }];
                         });
                         
                     }];
}

#pragma mark - Yo User

- (void)setYoObject:(YoModelObject *)yoObject {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ObjectChanged" object:_yoObject];
    
    _yoObject = yoObject;
    
    if (yoObject.lastYoStatus && yoObject.lastYoDate) {
        self.statusLabel.text = MakeString(@"%@ - %@", [yoObject getStatusStringForStatus:yoObject.lastYoStatus], [yoObject.lastYoDate agoString]);
    }
    
    self.label.text = [yoObject displayName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectChanged:) name:@"ObjectChanged" object:yoObject];
}

- (void)objectChanged:(NSNotification *)notification {
    self.label.text = [self.yoObject displayName];
    if (self.yoObject.lastYoStatus && self.yoObject.lastYoDate) {
        self.statusLabel.text = MakeString(@"%@ - %@", [self.yoObject getStatusStringForStatus:self.yoObject.lastYoStatus], [self.yoObject.lastYoDate agoString]);
        [self flashStatus];
    }
}

#pragma mark - Swiping

- (void)animateProgressWithDuration:(NSTimeInterval)durationInSeconds {
    [[self.containerView viewWithTag:543] removeFromSuperview];
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.containerView.height)];
    progressView.tag = 543;
    progressView.backgroundColor = [UIColor redColor];
    [self.containerView insertSubview:progressView belowSubview:self.label];
    [UIView animateWithDuration:4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        progressView.width = self.containerView.width;
    } completion:^(BOOL finished) {
        [progressView removeFromSuperview];
    }];
}

- (void)removeProgressView {
    [self.containerView viewWithTag:543].backgroundColor = [UIColor clearColor];
    [[self.containerView viewWithTag:543] removeFromSuperview];
}

- (void)animateLongTapWithCompletion:(void(^)(bool finished))block{
    
    if (self.isAnimatingLongTapProgress) {
        return;
    }
    self.progressView.hidden = NO;
    self.progressView.frame = CGRectMake(0, 0, 0, self.height);
    
    self.isAnimatingLongTapProgress = YES;
    NSTimeInterval duration = [[MobliConfigManager sharedInstance] yoLinkLongTapDuration];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.progressView.frame = CGRectMake(0, 0, self.width, self.height);
    } completion:^(BOOL finished) {
        self.isAnimatingLongTapProgress = NO;
        if (block) {
            block(finished);
        }
    }];
}

- (void)startActivityIndicator{
    self.label.hidden = YES;
    self.progressView.hidden = YES;
    [self.aiView startAnimating];
}

- (void)endActivityIndicator{
    [self.aiView stopAnimating];
    self.label.hidden = NO;
}

- (void)flashText:(NSString *)text completionBlock:(void (^)())block {
    
    self.label.text = text;
    
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        self.userInteractionEnabled = YES;
        if (block) block();
    });
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.lastTouch = [[event allTouches] anyObject];
}

@end
