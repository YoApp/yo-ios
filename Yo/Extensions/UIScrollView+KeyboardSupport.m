//
//  UIScrollView+KeyboardSupport.m
//  Yo
//
//  Created by Peter Reveles on 4/16/15.
//
//

#import "UIScrollView+KeyboardSupport.h"

@implementation UIScrollView (KeyboardSupport)

- (void)adjustContentWithKeyboard {
    // remove self observer in case we already are observing. Multiple observers
    // will result in multuple calls
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    // register
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    if (IS_OVER_IOS(7.0)) {
        UIEdgeInsets e = self.contentInset;
        e.bottom = keyboardBounds.size.height;
        [self setScrollIndicatorInsets:e];
        [self setContentInset:e];
    }
    else if ([[YoApp currentSession] isLoggedIn]){ // dont want keyboard shifting during logged out state
        CGRect frame = self.frame;
        frame.origin.y -= keyboardBounds.size.height;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self setFrame:frame];
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    if (IS_OVER_IOS(7.0)) {
        UIEdgeInsets e = self.contentInset;
        e.bottom = 0;
        NSNumber *value = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [UIView animateWithDuration:[value doubleValue] animations:^{
            [self setScrollIndicatorInsets:e];
            [self setContentInset:e];
        }];
    }
    else if ([[YoApp currentSession] isLoggedIn]){ // dont want keyboard shifting during logged out state
        CGRect tableViewFrame = self.frame;
        tableViewFrame.origin.y = 0.0f;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self setFrame:tableViewFrame];
        [UIView commitAnimations];
    }
}

@end
