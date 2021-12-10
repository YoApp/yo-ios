//
//  YOCell.h
//  Yo
//
//  Created by Or Arbel on 2/28/14.
//
//

#import "YOTextField.h"
#import "YOProfileView.h"
#import "YoModelObject.h"
#import "YoLabel.h"

@class YOCell;

typedef void (^Block) (void);

@interface YOCell : UITableViewCell <UITextFieldDelegate>

@property(nonatomic, strong) YoModelObject *yoObject;

@property(nonatomic, strong) IBOutlet YoLabel                   *label;
@property(nonatomic, strong) IBOutlet UILabel                   *statusLabel;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView   *aiView;

@property (nonatomic, assign) BOOL                              shouldShowActivityWhenTapped;
@property (nonatomic, assign) UITouch                           *lastTouch;

@property (nonatomic, strong)   IBOutlet UIView                 *progressView;

- (void)animateLongTapWithCompletion:(void(^)(bool finished))block;
@property (nonatomic, readonly) BOOL isAnimatingLongTapProgress;

- (void)startActivityIndicator;
- (void)endActivityIndicator;
- (void)flashStatus;

- (void)showStatus;
- (void)hideStatus;

- (void)flashText:(NSString *)text completionBlock:(void (^)())block;

- (void)animateProgressWithDuration:(NSTimeInterval)durationInSeconds;
- (void)removeProgressView;

@end
