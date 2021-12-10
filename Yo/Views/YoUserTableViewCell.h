//
//  YoContactTableViewCell.h
//  Yo
//
//  Created by Peter Reveles on 7/14/15.
//
//

#import <UIKit/UIKit.h>
@class YoModelObject;
@class YoLabel;

@interface YoUserTableViewCell : UITableViewCell

- (void)congifureForUser:(YoModelObject *)user;

@property (nonatomic, readonly) YoModelObject *user;

@property (nonatomic, readonly) YoLabel *nameLabel;
@property (nonatomic, readonly) YoLabel *lastYoStatusLabel;

// last yo status

- (void)showLastYoStatus;

- (void)hideLastYoStatus;

- (BOOL)isShowingLastYoStatus;

// Activity Indicating

- (void)startAnimatingActivityIndicator;

- (void)stopAnimatingActivityIndicator;

- (BOOL)isAnimatingActivityIndicator;

// Message Flashing

- (void)flashText:(NSString *)text forDuration:(NSTimeInterval)duration completionHandler:(void (^)())handler;

@property (nonatomic, readonly) BOOL isFlashingText;

- (void)showPlaceHolderWithText:(NSString *)text;

- (void)hidePlaceHolder;

- (BOOL)isShowingPlaceholder;

// Progress Indicating

- (void)indicateProgressWithDuration:(NSTimeInterval)duration;

- (void)stopIndicatingProgress;

@property (nonatomic, readonly) BOOL isIndicatingProgress;

@end
