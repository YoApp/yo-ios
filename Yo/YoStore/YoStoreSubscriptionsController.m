//
//  YoStoreItemsViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/28/15.
//
//

#import "YoStoreSubscriptionsController.h"
#import "YoStore.h"
#import "YoStoreItemCell.h"
#import "YoStoreItemController.h"
#import "YoWebBrowserController.h"
#import "YoStoreDataManager.h"
#import "YoLabel.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "YoThemeManager.h"

static void *YoContext = &YoContext;

@interface YoStoreSubscriptionsController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;
@property (nonatomic, strong) NSArray *storeItems;
@property (nonatomic, weak) UILabel *sectionHeaderLabel;
@property (nonatomic, assign) BOOL isLoading;

@property (nonatomic, assign) BOOL isListeningForSubscriptionUpdates;
@end

@implementation YoStoreSubscriptionsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"YoStoreItemCell" bundle:nil] forCellReuseIdentifier:YoStoreItemCellReuseID];
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.tableView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateData];
    self.navigationController.navigationBar.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.98f];
    
    [[YoUser me].contactsManager updateSubscriptionsWithCompletionBlock:^{
        [self updateData];
        [self.tableView reloadData];
    }];
}

- (void)updateData {
    NSMutableArray *subscriptions = [NSMutableArray array];
    for (NSDictionary *dic in [[[YoUser me] contactsManager] subscriptionsObjects]) {
        [subscriptions addObject:[YoUser objectFromDictionary:dic]];
    }
    self.storeItems = subscriptions;
    [self.tableView reloadData];
}

#pragma mark Setters

- (void)setIsLoading:(BOOL)isLoading {
    if (_isLoading != isLoading) {
        _isLoading = isLoading;
        BOOL isOnScreen = self.view.window!=nil?YES:NO;
        if (isLoading) {
            [MBProgressHUD showHUDAddedTo:self.view animated:isOnScreen];
        }
        else {
            [MBProgressHUD hideHUDForView:self.view animated:isOnScreen];
        }
    }
}

#pragma mark Action

- (void)subscribeButtonTappedForCell:(YoStoreItemCell *)cell {
    if (cell.item) {
        cell.subscribeButton.userInteractionEnabled = NO;
        __weak YoStoreSubscriptionsController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf startLoadingAnimationForYoStoreButton:cell.subscribeButton];
            [weakSelf unsubscribeToService:cell.item withCompletionBlock:^(BOOL success) {
                [weakSelf stopLoadingAnimationForYoStoreButton:cell.subscribeButton];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf removeCellWithItem:cell.item animated:YES];
                });
            }];
        });
    }
}

- (void)removeCellWithItem:(YoStoreItem *)item animated:(BOOL)animated {
    NSInteger itemRow = [self.storeItems indexOfObject:item];
    if (itemRow != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:itemRow inSection:0];
        NSMutableArray *updatedStoreItems = [self.storeItems mutableCopy];
        [updatedStoreItems removeObjectAtIndex:indexPath.row];
        self.storeItems = updatedStoreItems;
        UITableViewRowAnimation rowanimation = animated?UITableViewRowAnimationLeft:UITableViewRowAnimationNone;
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:rowanimation];
        self.sectionHeaderLabel.text = [self getSubscriptionCountHeaderText];
        [self reloadTableViewCellsColors];
    }
}

- (void)startLoadingAnimationForYoStoreButton:(YoStoreButton *)button {
    CGFloat finalWidth = button.frame.size.height;
    CGPoint finalFrameOrigin = CGPointMake(button.frame.origin.x + (button.width - finalWidth), button.frame.origin.y);
    
    [UIView animateWithDuration:0.3 animations:^{
        button.layer.frame = CGRectMake(finalFrameOrigin.x, finalFrameOrigin.y, finalWidth, button.height);
        button.layer.cornerRadius = button.layer.frame.size.height/2.0f;
        button.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    } completion:^(BOOL finished) {
        NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:2*2];
        for (int index = 0; index < 3; index++) {
            [values addObject:(id)[[UIColor clearColor] CGColor]];
            [values addObject:(id)[[UIColor whiteColor] CGColor]];
        }
        
        CAKeyframeAnimation *colorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
        
        colorAnimation.duration = 1.5f;
        colorAnimation.values = values;
        colorAnimation.repeatCount = 0;
        
        [button.layer addAnimation:colorAnimation forKey:@"backgroundColor"];
    }];
}

- (void)stopLoadingAnimationForYoStoreButton:(YoStoreButton *)button {
    [button.layer removeAnimationForKey:@"backgroundColor"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.emptyLabel.hidden = self.storeItems.count > 0;
    return self.storeItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat heightAscpectRatio = 106.0f/375.0f;
    CGFloat height = width * heightAscpectRatio;
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YoStoreItemCell *cell = [tableView dequeueReusableCellWithIdentifier:YoStoreItemCellReuseID forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = LOAD_NIB(@"YoStoreItemCell");
        cell.detailsButton.hidden = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    __weak YoStoreSubscriptionsController *weakSelf = self;
    cell.subscribeButtonTappedBlock = ^(YoStoreItemCell *cell) {
        [weakSelf subscribeButtonTappedForCell:cell];
    };
    
    /*cell.detailsButtonTappedBlock = ^(YoStoreItemCell *cell) {
     [weakSelf pushItemControllerForItem:cell.item andBackgroundColor:[[YoThemeManager sharedInstance] colorForRow:indexPath.row]];
     [YoAnalytics logEvent:YoEventDetailsButtonTapped withParameters:@{YoParam_USER_IDS:@[cell.item.itemID?:@"no_itemID"]}];
     };*/
    
    YoStoreItem *item = self.storeItems[indexPath.row];
    [self prepareCell:cell forItem:item];
    cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    cell.backgroundColor = cell.contentView.backgroundColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YoStoreItem *item = self.storeItems[indexPath.row];
    //[self pushItemControllerForItem:item andBackgroundColor:[[YoThemeManager sharedInstance] colorForRow:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
    UIView *sectionHeader = nil;
    if (section == 0) {
        YoLabel *headerLabel = [YoLabel new];
        headerLabel.edgeInsets = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);
        headerLabel.text = [self getSubscriptionCountHeaderText];
        headerLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        headerLabel.backgroundColor = [UIColor colorWithHexString:@"F0F0F0"];
        sectionHeader = headerLabel;
        self.sectionHeaderLabel = headerLabel;
    }
    return sectionHeader;
}

- (NSString *)getSubscriptionCountHeaderText {
    NSString *headerText = MakeString(NSLocalizedString(@"my subscriptions %i", nil), self.storeItems.count);
    return headerText.capitalizedString;
}

- (void)prepareCell:(YoStoreItemCell *)cell forItem:(YoUser *)user {
    if (user.photoURL) {
        [cell.profileImageView setImageWithURL:user.photoURL placeholderImage:[UIImage imageNamed:@"180x180"]];
    }
    else {
        UIImage *image = [UIImage imageNamed:@"180x180"];
        [cell.profileImageView setImage:image];
    }
    cell.nameLabel.text = user.username; // @or: here full name is actually description of store item
    [cell.nameLabel sizeToFit];
    cell.descriptionLabel.text = user.fullName;
    [cell.descriptionLabel sizeToFit];
    cell.needsLocationImageView.hidden = user.needsLocation?NO:YES;
    //    cell.isVerifiedImageView.hidden = item.isOfficial?NO:YES;
    
    cell.item = user;
    if (user.username) {
        [cell.subscribeButton setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
    }
    else {
        [cell.subscribeButton setTitle:NSLocalizedString(@"open", nil).capitalizedString forState:UIControlStateNormal];
    }
}

- (void)reloadTableViewCellsColors {
    for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:0]; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"unsubscribe", nil).capitalizedString;
}

- (void)pushItemControllerForItem:(YoStoreItem *)item andBackgroundColor:(UIColor *)backgroundColor {
    YoStoreItemController *itemController = [self.storyboard instantiateViewControllerWithIdentifier:YoStoreItemControllerID];
    [itemController configureWithItem:item];
    itemController.view.backgroundColor = backgroundColor;
    [self.navigationController pushViewController:itemController animated:YES];
}

- (void)pushWebControllerForItem:(YoStoreItem *)item {
    YoWebBrowserController *vc = [[YoWebBrowserController alloc] initWithUrl:item.url];
    vc.navigationItem.title = item.username?:item.name;
    [self.navigationController pushViewController:vc animated:YES];
    
    vc.navigationController.navigationBar.backgroundColor = [self.navigationController.navigationBar.backgroundColor colorWithAlphaComponent:1.0f];
    if (IS_OVER_IOS(8.0)) {
        vc.navigationController.hidesBarsOnSwipe = NO;
    }
    [vc.navigationController setNavigationBarHidden:NO animated:YES];
}

@end
