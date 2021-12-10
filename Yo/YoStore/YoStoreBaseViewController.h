//
//  YoStoreBaseViewController.h
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import <UIKit/UIKit.h>
#import "YoBaseViewController.h"
@class YoStoreButton;
#import "YoStoreItem.h"

@interface YoStoreBaseViewController : YoBaseViewController

#pragma mark - Getting Data

- (NSURL *)photoURLForForFileName:(NSString *)fileName;

- (NSURL *)screenshotURLForFilename:(NSString *)filename;

#pragma mark - Subscribing

- (void)unsubscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block;

- (void)subscribeToService:(YoStoreItem *)service withCompletionBlock:(void (^)(BOOL success))block;

#pragma mark - Animations

- (void)performTitleChangeAnimationOnButton:(YoStoreButton *)button
                                      delay:(NSTimeInterval)delay
                                   newTitle:(NSString *)newTitle
                        withCompletionBlock:(void (^)(BOOL finished))block;

@end
