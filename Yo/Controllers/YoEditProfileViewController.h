//
//  YoEditProfileViewController.h
//  Yo
//
//  Created by Peter Reveles on 5/19/15.
//
//

#import "YoBaseViewController.h"

typedef NS_ENUM(NSUInteger, YoEditProfileState) {
    YoEditProfileStateGeneral,
    YoEditProfileStatePassword
};

@interface YoEditProfileViewController : YoBaseViewController

@property (readonly, nonatomic) YoEditProfileState editingState;

@end
