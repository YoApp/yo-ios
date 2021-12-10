//
//  YoStatusBar.m
//  Yo
//
//  Created by Or Arbel on 5/27/15.
//
//

#import "YoStatusBar.h"

@implementation YoStatusBar

- (void)flashText:(NSString *)text {
    
    if (text.length == 0) {
        return;
    }
    
    if (self.label.alpha != 0.0) {
        [UIView animateWithDuration:0.1 animations:^{
            
            self.label.alpha = 0.0;
            
        }];
    }
    
    self.label.text = text;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.pageControl.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              
                                              self.label.alpha = 1.0;
                                              
                                          }
                                          completion:^(BOOL finished) {
                                              
                                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                  [self hideLabel];
                                              });
                                          }];
                     }];
    
}

- (void)hideLabel {
    [UIView animateWithDuration:0.2 animations:^{
        
        self.label.alpha = 0.0;
        
    }
                     completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              
                                              self.pageControl.alpha = 1.0;
                                              
                                          }];
                     }];
}

@end
