//
//  YoCreateGroupPopupViewController.h
//  Yo
//
//  Created by Peter Reveles on 7/23/15.
//
//

#import "YoBaseViewController.h"

@interface YoCreateGroupPopupViewController : YoBaseViewController

@property (nonatomic, strong, readonly) YOTextField *textField;
@property (nonatomic, strong, readonly) YoLabel *exampleTitleLabel;
@property (nonatomic, strong, readonly) YoLabel *exampleMessageLabel;
@property (nonatomic, strong, readonly) UIButton *createButton;
@property (nonatomic, strong) NSArray *groupMembers;

@end
