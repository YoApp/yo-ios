//
//  YoTableViewActionSheet.h
//  Yo
//
//  Created by Peter Reveles on 11/18/14.
//
//

#import <UIKit/UIKit.h>
#import "YoTableViewSheetController.h"

@interface YoTableViewAction : NSObject

- (instancetype)initWithTitle:(NSString *)title tapBlock:(void (^)())block;

@end

@interface YoThisExtensionController : YoTableViewSheetController

- (void)addAction:(YoTableViewAction *)action;

- (void)showOnView:(UIView *)view;

@end
