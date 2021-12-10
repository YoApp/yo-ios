//
//  YoAddPickerController.h
//  Yo
//
//  Created by Or Arbel on 5/20/15.
//
//

#import "YoBaseViewController.h"

@interface YoAddPickerController : YoBaseViewController

@property(nonatomic, weak) IBOutlet UIView *backgroundView;

@property(nonatomic, weak) IBOutlet YoLabel *titleLabel;

@property(nonatomic, weak) IBOutlet YoButton *yofriendButton;
@property(nonatomic, weak) IBOutlet YoButton *createGroupButton;
@property(nonatomic, weak) IBOutlet YoButton *subscribeButton;

@property(nonatomic, weak) IBOutlet UIView *friendTipView;
@property(nonatomic, weak) IBOutlet UIView *groupTipView;
@property(nonatomic, weak) IBOutlet UIView *subscribeTipView;

@property(nonatomic, weak) IBOutlet YoLabel *friendTipLabel;
@property(nonatomic, weak) IBOutlet YoLabel *groupTipLabel;
@property(nonatomic, weak) IBOutlet YoLabel *subscribeTipLabel;

@end
