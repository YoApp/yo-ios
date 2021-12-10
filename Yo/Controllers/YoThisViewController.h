//
//  YoThisControllerViewController.h
//  Yo
//
//  Created by Peter Reveles on 11/18/14.
//
//

#import "YoTableViewSheetController.h"
@class Yo;

#define YOALL_ENABLED YES
#define MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL 2

@interface YoThisViewController : YoTableViewSheetController

- (void)presentShareSheetOnView:(UIView *)view toForwardYo:(Yo *)yo;

// ** The current user will be considered the original sender of the provided URL */
- (void)presentShareSheetOnView:(UIView *)view toShare:(NSURL *)url;

@end
