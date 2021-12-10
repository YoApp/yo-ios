//
//  YoPresentorController.h
//  Yo
//
//  Created by Or Arbel on 7/16/15.
//
//

#import "YoBaseViewController.h"
#import "Yo.h"

@interface YoPresentorController : YoBaseViewController

@property(nonatomic, assign) BOOL isCustomReplies;
@property(nonatomic, strong) IBOutlet YoActionButton *rightButton;
@property(nonatomic, strong) IBOutlet YoActionButton *leftButton;
@property(nonatomic, strong) NSString *leftButtonTitle;
@property(nonatomic, strong) NSString *rightButtonTitle;

@property(nonatomic, strong) Yo *yo;

- (NSDictionary *)extraParameters;

- (IBAction)leftButtonPressed:(UIButton *)sender;
- (IBAction)rightButtonPressed:(UIButton *)sender;

- (void)applyCustomActionsIfNeeded;

@end
