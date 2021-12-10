//
//  YoTipView.h
//  Yo
//
//  Created by Or Arbel on 6/5/15.
//
//

@interface YoTipController : YoBaseViewController

@property(nonatomic, strong) IBOutlet UIButton *tipButton;
@property(nonatomic, strong) IBOutlet UIView *tipView;
@property(nonatomic, strong) IBOutlet YoLabel *titleLabel;
@property(nonatomic, strong) IBOutlet YoLabel *tipLabel;
@property(nonatomic, strong) IBOutlet YoButton *okButton;

+ (void)showTipIfNeeded:(NSString *)text;

@end
