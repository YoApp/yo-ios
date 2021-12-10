//
//  YoButton.h
//  Yo
//
//  Created by Peter Reveles on 5/15/15.
//
//

#import <UIKit/UIKit.h>

@interface YoButton : UIButton

@property (assign, nonatomic) BOOL disableRoundedCorners;

- (void)animateProgressWithDuration:(NSTimeInterval)durationInSeconds;
- (void)removeProgressView;

@end
