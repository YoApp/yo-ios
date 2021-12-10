//
//  YoContextView.h
//  Yo
//
//  Created by Peter Reveles on 7/28/15.
//
//

#import <UIKit/UIKit.h>

@interface YoContextView : UIView

- (instancetype)init;

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) UIButton *utilityButton;

@property (nonatomic, strong) YoContextObject *context;

- (void)setupForContextIfNeeded; // allows for lazy setup

- (void)reloadConfiguration;

@end
