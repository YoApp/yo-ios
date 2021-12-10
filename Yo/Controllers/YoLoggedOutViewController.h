//
//  YoLoginViewController.h
//  Yo
//
//  Created by Peter Reveles on 4/2/15.
//
//

#import "YoBaseViewController.h"

typedef NS_ENUM(NSUInteger, YoViewControllerState) {
    YoViewControllerStateActive, // Controller is dynmic (User interaction enabled)
    YoViewControllerStateIdle // Controller is static (User interaction disabled)
};

@interface YoLoggedOutViewController : YoBaseViewController

/**
 This should be updated to make public this controllers current state.
 */
@property (nonatomic, assign) YoViewControllerState controllerState;

@end
