//
//  YoPhoneVerificationBySMSController.h
//  Yo
//
//  Created by Peter Reveles on 6/6/15.
//
//

#import <UIKit/UIKit.h>
#import "YoBaseViewController.h"

@interface YoPhoneVerificationBySMSController : YoBaseViewController
@property (assign, nonatomic) NSInteger timesViewed;

/// Defaults to nil.
/**
 Set before calling present view controller
 */
@property (nonatomic, strong) NSString *closeButtonText;

- (void)showEnterPhoneNumber;

@end
