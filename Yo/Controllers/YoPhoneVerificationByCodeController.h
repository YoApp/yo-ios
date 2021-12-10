//
//  YoPhoneVerificationByCodeController.h
//  Yo
//
//  Created by Peter Reveles on 6/6/15.
//
//

#import <UIKit/UIKit.h>
#import "YoBaseViewController.h"

@interface YoPhoneVerificationByCodeController : YoBaseViewController
@property(nonatomic, strong) NSMutableArray *countries;
@property (nonatomic, strong) NSMutableArray *countryCodeArray;
@property (nonatomic, strong) NSMutableArray *countryNameArray;
@property (weak, nonatomic) IBOutlet YoLabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet YOTextField *textField;
@property (weak, nonatomic) IBOutlet YoButton *countryCodeButton;
@property (strong, nonatomic) YoButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainerView;

@property (assign, nonatomic) BOOL showsCloseButton;

@property (assign, nonatomic) CGFloat callToActionBottom;
@property (strong, nonatomic) NSString *textForLabel;

- (void)setupViews;

@end
