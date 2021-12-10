//
//  YoInfoPresentatationViewController.h
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoBaseViewController.h"

/**
 This is the base controller for controllers who present contained information.
 Defaults to disallowing notifications.
 */
@interface YoInfoPresentatationViewController : YoBaseViewController

- (void)playYoSound;

@end
