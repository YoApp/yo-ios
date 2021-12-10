//
//  YoStatusBar.h
//  Yo
//
//  Created by Or Arbel on 5/27/15.
//
//

@interface YoStatusBar : UIView

@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet YoLabel *label;

- (void)flashText:(NSString *)text;
- (void)hideLabel;

@end
