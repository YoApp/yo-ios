//
//  UIScrollView+KeyboardSupport.h
//  Yo
//
//  Created by Peter Reveles on 4/16/15.
//
//

#import <UIKit/UIKit.h>

@interface UIScrollView (KeyboardSupport)

/**
 Listens for keyboard presentations and adjusts scrollview accordingly to keep
 content accessable.
 */
- (void)adjustContentWithKeyboard;

@end
