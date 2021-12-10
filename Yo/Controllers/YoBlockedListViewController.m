//
//  YOBlockedViewController.m
//  Yo
//
//  Created by Or Arbel on 4/7/14.
//
//

#import "YoBlockedListViewController.h"
#import "YoContactManager.h"
#import "YoBlockedUserCell.h"
#import "YoThemeManager.h"
#import "YoBlockedListDataSource.h"
#import "YoLayoutMetrics.h"
#import "YoCollectionViewGridLayout.h"

@interface YoBlockedListViewController () <UITextFieldDelegate, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet YOTextField *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *unblockButton;
@property (strong, nonatomic) NSMutableArray *objectsToUnblock;

@property (strong, nonatomic) YoBlockedListDataSource *blockedListDataSource;
@end

NSString *const YoBLockedUserCellID = @"YoBLockedUserCell";

@implementation YoBlockedListViewController

#pragma mark Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    YoCollectionViewGridLayout *layout = [[YoCollectionViewGridLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    
    YoBlockedListDataSource *dataSource = [YoBlockedListDataSource sharedInstance];
    
    YoLayoutSectionMetrics *metrics = dataSource.defaultMetrics;
    metrics.separatorInsets = UIEdgeInsetsZero;
    metrics.rowHeight = 69.0f;
    metrics.backgroundColor = [UIColor clearColor];
    
    self.blockedListDataSource = dataSource;
    self.collectionView.dataSource = dataSource;
    
    [self setupUI];
    
    _objectsToUnblock = [NSMutableArray new];
    
    _titleLabel.text = NSLocalizedString(@"blocked list", nil).capitalizedString;
    _titleLabel.userInteractionEnabled = NO;
    
    [_unblockButton setTitle:[self getUnblockButtonTitle] forState:UIControlStateNormal];
    _unblockButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
    _unblockButton.enabled = self.objectsToUnblock.count ? YES : NO;
    
    self.collectionView.allowsMultipleSelection = YES;
}

- (void)setupUI {
    self.contentView.layer.cornerRadius = 10.0;
    self.contentView.layer.masksToBounds = YES;
    
    self.collectionView.backgroundColor = [UIColor clearColor];
}

- (void)closeWithCompletionBlock:(void (^)())block {
    [UIView animateWithDuration:0.2 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    }];
    [super closeWithCompletionBlock:block];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (NSString *)title {
    return NSLocalizedString(@"blocked list", nil).capitalizedString;
}

#pragma mark - Internal

- (NSString *)getUnblockButtonTitle {
    return MakeString(NSLocalizedString(@"unblock (%lu)", nil), self.objectsToUnblock.count).capitalizedString;
}

- (void)unblockSelectedUsers {
    if (![APPDELEGATE hasInternet]) {
        // can't unblock if there's no internet
        [APPDELEGATE checkInternet];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    for (YoModelObject *object in self.objectsToUnblock) {
        [[[YoUser me] contactsManager] unblockObject:object withCompletionBlock:nil];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.contentView animated:YES];
        [self close];
    });
}

- (void)selectedUsersDidChange {
    [self.unblockButton setTitle:[self getUnblockButtonTitle] forState:UIControlStateNormal];
    self.unblockButton.enabled = self.objectsToUnblock.count?YES:NO;
}

#pragma mark - Gestures

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    if (!CGRectContainsPoint(self.containerView.frame, touchPoint)) {
        [self closeWithCompletionBlock:nil];
    }
}

#pragma mark - Actions

- (IBAction)didTapCloseButton:(UIButton *)sender {
    [self closeWithCompletionBlock:nil];
}

- (IBAction)didTapUnblockButton:(UIButton *)sender {
    [self unblockSelectedUsers];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoModelObject *objectToUnblock = [self.blockedListDataSource itemAtIndexPath:indexPath];
    [self.objectsToUnblock addObject:objectToUnblock];
    [self selectedUsersDidChange];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoModelObject *object = [self.blockedListDataSource itemAtIndexPath:indexPath];
    [self.objectsToUnblock removeObject:object];
    [self selectedUsersDidChange];
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
