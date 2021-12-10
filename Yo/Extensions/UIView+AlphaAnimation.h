//
//  UIView+Animations.h
//  Yo
//
//  Created by Peter Reveles on 4/17/15.
//
//

#import <UIKit/UIKit.h>

@interface UIView (AlphaAnimation)

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated completionBlock:(void (^)(BOOL finished))block;

@end
