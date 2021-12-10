//
//  YONotificationView.h
//  Yo
//
//  Created by Or Arbel on 5/24/14.
//
//

@class CLLocation;
@class Yo;
@class YoView;

@protocol YoViewActionDelegate <NSObject>

- (void)closeButtonTouchedUpInsideInYoView:(YoView *)view;
- (void)openButtonTouchedUpInsideInYoView:(YoView *)view;

@end

@interface YoView : UIView

@property (nonatomic, strong) Yo *yo;

@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) id <YoViewActionDelegate> actionDelegate;

@property (nonatomic, weak) NSString *displayText;

/**
 Resets this views frame to fit all content.
 */
- (void)updateFrameToFitContent;

@property (nonatomic, assign) BOOL requiresOpen;

@end
