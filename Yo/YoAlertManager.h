//
//  YoAlertView.h
//  Yo
//
//  Created by Peter Reveles on 12/17/14.
//
//

#import <UIKit/UIKit.h>
#import "YoAlert.h"

@interface YoAlertManager : NSObject

@property (readonly, nonatomic) NSDictionary *defaultDescriptionTextAttributes;

+ (instancetype)sharedInstance;

#ifndef IS_APP_EXTENSION
- (void)showAlert:(YoAlert *)alert;

- (void)showAlert:(YoAlert *)alert
  completionBlock:(void (^)(bool finished))block NS_EXTENSION_UNAVAILABLE("App extensions must explicitly provide the presenting viewcontroller");

- (void)showAlert:(YoAlert *)alert
         animated:(BOOL)animated completionBlock:(void (^)(bool finished))block NS_EXTENSION_UNAVAILABLE("App extensions must explicitly provide the presenting viewcontroller");
#endif

- (void)showAlert:(YoAlert *)alert;

- (void)showAlert:(YoAlert *)alert
 onViewController:(UIViewController *)presentingViewController
  completionBlock:(void (^)(bool finished))block;

- (void)showAlert:(YoAlert *)alert
 onViewController:(UIViewController *)presentingViewControllera
         animated:(BOOL)animated completionBlock:(void (^)(bool finished))block;

- (void)dismissAllPopupsWithCompletionHandler:(void (^)())completionHandler;

- (void)showAlertWithTitle:(NSString *)title
                      text:(NSString *)text
            yesButtonTitle:(NSString *)yesButtonTitle
             noButtonTitle:(NSString *)noButtonTitle
                  yesBlock:(void (^)(void))yesBlock;

- (void)showAlertWithTitle:(NSString *)title
                      text:(NSString *)text;

- (void)showAlertWithTitle:(NSString *)title;

@end
