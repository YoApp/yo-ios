//
//  YoFormViewController.h
//  Yo
//
//  Created by Peter Reveles on 4/15/15.
//
//

#import "YoBaseViewController.h"
#import "YOTextField.h"
#import <MBProgressHUD/MBProgressHUD.h>

@class YoFormViewController;

@protocol YoFormControllerDelegate <NSObject>

/**
 Called after this controller has been dismissed
 */
- (void)formControllerDidDismiss:(YoFormViewController *)formController;

@end

@interface YoFormViewController : YoBaseViewController

@property (nonatomic, weak) id <YoFormControllerDelegate> delegate;

- (void)dismissWithCompletionBlock:(void (^)())block;

@property(assign, nonatomic) CGFloat keyboardTop;

@end
