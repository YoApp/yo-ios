//
//  YOEnablePushController.h
//  Yo
//
//  Created by Or Arbel on 3/4/14.
//
//

#import "YoBaseTableViewController.h"
#import "YoInfoPresentatationViewController.h"

@protocol YoEnablePushControllerDelegate <NSObject>

- (void)enablePushControllerDidDismiss;

@end

@interface YOEnablePushController : YoInfoPresentatationViewController

@property (nonatomic, weak) id delegate;

@property(nonatomic, strong) IBOutlet UITableViewCell *cell;

@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) IBOutlet UILabel *topLabel;
@property(nonatomic, strong) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) IBOutlet UIButton *openSettingButton;

- (IBAction)close;

@end
