//
//  YoStoreController.m
//  Yo
//
//  Created by Or Arbel on 2/14/15.
//
//

#import "YoStoreController.h"
#import "YoAPIClient.h"
#import "YoStoreItemCell.h"
#import "YoStoreItemController.h"
#import "YoWebBrowserController.h"
#import <JBWhatsAppActivity/JBWhatsAppActivity.h>
#import "YoShareSheet.h"
#import <SwipeView/SwipeView.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "YOLocationManager.h"
#import "Yo.h"
#import "YoStoreDataManager.h"
#import "YoStore.h"
#import "YoThemeManager.h"

#define kTagImageView 33524

NSString *const YoStoreCategoryNameAll = @"All";

static void *YoContext = &YoContext;

@interface YoStoreController () <UITableViewDataSource, UITableViewDelegate, SwipeViewDataSource, SwipeViewDelegate>
@property (nonatomic, strong) NSArray *banners;
@property (nonatomic, strong) NSArray *categoryNames;
@property (nonatomic, strong) NSArray *storeItems;

@property (nonatomic, strong) NSString *selectedCategoryName;
@property (nonatomic, strong) AFHTTPRequestOperationManager *apiClient;
@property (nonatomic, strong) NSTimer *bannerTimer;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet SwipeView *bannersSwipeView;
@property (nonatomic, weak) IBOutlet UIScrollView *categoriesScrollView;
@property (nonatomic, weak) IBOutlet UIView *headerView;
@end

@implementation YoStoreController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:BGCOLOR];
    self.navigationController.navigationBar.translucent = NO;
    
    if (NO) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(close)];
        
        self.navigationController.navigationBar.topItem.rightBarButtonItem = closeButton;
    }
    
    [self createSwipeViewAndCategoriesView];
    
    [[YoStoreDataManager sharedInstance] addObserver:self
                                          forKeyPath:NSStringFromSelector(@selector(loadingStatus))
                                             options:NSKeyValueObservingOptionNew
                                             context:YoContext];
    
    switch ([YoStoreDataManager sharedInstance].loadingStatus) {
        case YoLoadingStatusInProgress:
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            break;
            
        case YoLoadingStatusComplete:
            [self performInitialSetup];
            break;
            
        default:
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[YoStoreDataManager sharedInstance] update];
            break;
    }
    
    self.view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
    if (self.isViewLoaded) {
        @try {
            [[YoStoreDataManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(loadingStatus))];
        }
        @catch (NSException * __unused exception) {}
    }
}

- (void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)createSwipeViewAndCategoriesView {
    // container
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat categoriesViewHeight = 80.0f;
    CGRect headerViewFrame = CGRectMake(0.0f,
                                        0.0f,
                                        screenWidth,
                                        (screenWidth/2.0f)+categoriesViewHeight);
    UIView *headerView = [[UIView alloc] initWithFrame:headerViewFrame];
    
    // swipe view
    CGRect swipeViewFrame = headerViewFrame;
    swipeViewFrame.size.height -= categoriesViewHeight;
    SwipeView *bannerSwipeView = [[SwipeView alloc] initWithFrame:swipeViewFrame];
    bannerSwipeView.pagingEnabled = YES;
    bannerSwipeView.delegate = self;
    bannerSwipeView.dataSource = self;
    bannerSwipeView.itemsPerPage = 1;
    bannerSwipeView.wrapEnabled = YES;
    bannerSwipeView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:bannerSwipeView];
    self.bannersSwipeView = bannerSwipeView;
    
    // categories view
    CGRect categoriesViewFrame = CGRectMake(0.0f,
                                            CGRectGetMaxY(swipeViewFrame),
                                            headerViewFrame.size.width,
                                            categoriesViewHeight);
    
    UIScrollView *catergoriesScrollView = [[UIScrollView alloc] initWithFrame:categoriesViewFrame];
    catergoriesScrollView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:catergoriesScrollView];
    self.categoriesScrollView = catergoriesScrollView;
    
    self.tableView.tableHeaderView = headerView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.98f];
    [self.tableView reloadData];
    if ([YoUser me].contactsManager.subscriptionsObjects == nil) {
        [[YoUser me].contactsManager updateSubscriptionsWithCompletionBlock:^{
            [self.tableView reloadData];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self resetBannerTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.bannerTimer invalidate];
}

#pragma mark - KVO

- (void)yoStoreDataManager:(YoStoreDataManager *)dataManager didUpdateLoadingStatus:(YoLoadingStatus)loadStatus {
    if ([dataManager isEqual:[YoStoreDataManager sharedInstance]]) {
        if (loadStatus == YoLoadingStatusInProgress) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        else if (loadStatus == YoLoadingStatusComplete) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self performInitialSetup];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isKindOfClass:[YoStoreDataManager class]]) {
        YoStoreDataManager *dataManager = (YoStoreDataManager *)object;
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(loadingStatus))]) {
            [self yoStoreDataManager:object didUpdateLoadingStatus:dataManager.loadingStatus];
            return;
        }
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Hygene

- (void)cleanUp {
    [self.bannerTimer invalidate];
}

- (void)performInitialSetup {
    self.bannersSwipeView.backgroundColor = [UIColor whiteColor];
    self.categoriesScrollView.backgroundColor = [UIColor whiteColor];
    
    [self setupBanners];
    [self setupCategories];
    
    self.selectedCategoryName = YoStoreCategoryNameAll;
}

- (void)updateStoreItems {
    if ([self.selectedCategoryName isEqualToString:YoStoreCategoryNameAll]) {
        self.storeItems = [YoStoreDataManager sharedInstance].featuredStoreItems;
    }
    else {
        self.storeItems = [self getStoreItemsInCategoryWithName:self.selectedCategoryName];
    }
    [self.tableView reloadData];
}

- (void)setupBanners {
    self.banners = [[YoStoreDataManager sharedInstance] getFeauturedStoreBanners];
    [self reloadBanners];
}

- (void)setupCategories {
    NSArray *categories = [YoStoreDataManager sharedInstance].storeCategories;
    NSMutableArray *categoryNames = [[NSMutableArray alloc] initWithCapacity:categories.count];
    for (YoStoreCategory *category in categories) {
        [categoryNames addObject:category.name];
    }
    if ([categoryNames indexOfObject:YoStoreCategoryNameAll] == NSNotFound) {
        [categoryNames insertObject:YoStoreCategoryNameAll atIndex:0];
    }
    
    self.categoryNames = [categoryNames copy];
    
    [self reloadCategories];
}

- (void)reloadStoreItems {
    if ([self.selectedCategoryName isEqualToString:YoStoreCategoryNameAll]) {
        self.storeItems = [YoStoreDataManager sharedInstance].featuredStoreItems;
    }
    else {
        self.storeItems = [self getStoreItemsInCategoryWithName:self.selectedCategoryName];
    }
    
    self.categoriesScrollView.backgroundColor = [UIColor whiteColor];
    self.bannersSwipeView.backgroundColor = [UIColor whiteColor];
    
    [self reloadBanners];
    
    [self reloadCategories];
}

- (NSArray *)getStoreItemsInCategoryWithName:(NSString *)categoryName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ IN SELF.%@",categoryName, NSStringFromSelector(@selector(categories))];
    NSArray *storeItems = [[YoStoreDataManager sharedInstance] fetchItemsMathcingPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES];
    storeItems = [[storeItems sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    
    return storeItems;
}

#pragma mark - Actions

- (void)dismissWithCompeltionHandler:(void (^)())completionHandler {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (completionHandler) {
            completionHandler();
        }
        [YoAnalytics logEvent:YoEventYoStoreClosed withParameters:nil];
    }];
}

#pragma mark - Banners

#pragma mark SwipView Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView {
    return self.banners.count;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    swipeView.alignment = SwipeViewAlignmentEdge;
    if (!view) {
        view = [[UIView alloc] initWithFrame:self.bannersSwipeView.frame];
        view.autoresizingMask = self.bannersSwipeView.autoresizingMask;
        view.backgroundColor = [UIColor clearColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
        imageView.autoresizingMask = view.autoresizingMask;
        imageView.tag = kTagImageView;
        
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [view addSubview:imageView];
    }
    
    YoStoreBanner *banner = [self.banners objectAtIndex:index];
    UIImageView *imageView = (UIImageView *)[view viewWithTag:kTagImageView];
    [[YoStoreDataManager sharedInstance] getBannerImageForStoreItem:banner.associatedStoreItem
                                                withCompletionBlock:^(UIImage *bannerImage)
     {
         [imageView setImage:bannerImage];
     }];
    
    return view;
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView {
    [self resetBannerTimer];
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index {
    [self bannerTapped];
}

- (void)bannerTapped {
    NSInteger bannerIndex = self.bannersSwipeView.currentPage;
    YoStoreBanner *banner = self.banners[bannerIndex];
    [self pushItemControllerForItem:banner.associatedStoreItem
                 andBackgroundColor:[UIColor colorWithHexString:WISTERIA]];
    [YoAnalytics logEvent:YoEventTappedBanner
           withParameters:@{YoParam_USER_IDS:@[banner.associatedStoreItem.itemID?:@"no_id"]}];
}

- (void)nextBanner {
    if (!self.bannersSwipeView.isScrolling) {
        NSInteger currentItemIndex = self.bannersSwipeView.currentItemIndex;
        [self.bannersSwipeView scrollToItemAtIndex:(currentItemIndex + 1) duration:0.6];
    }
}

- (void)reloadBanners {
    [self resetBannerTimer];
    [self.bannersSwipeView reloadData];
}

- (void)resetBannerTimer {
    [self.bannerTimer invalidate];
    self.bannerTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(nextBanner) userInfo:nil repeats:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateBannerIfNeededForCurrentScrollViewContentOffset:scrollView.contentOffset];
}

- (void)updateBannerIfNeededForCurrentScrollViewContentOffset:(CGPoint)scrollViewContentOffset {
    if ([self.view window]) {
        BOOL bannerIsOffScreen = (scrollViewContentOffset.y > CGRectGetMaxY(self.bannersSwipeView.frame));
        if (bannerIsOffScreen && self.bannerTimer.isValid) {
            [self.bannerTimer invalidate];
        }
        else if (!bannerIsOffScreen && !self.bannerTimer.isValid) {
            [self resetBannerTimer];
        }
    }
}

#pragma mark - Categories Buttons

- (void)reloadCategories {
    
    CGFloat xOffset = 10.0;
    
    for (NSInteger categoryIndex = 0; categoryIndex < self.categoryNames.count; categoryIndex++) {
        UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self setupUIForCategoryButton:categoryButton atIndex:categoryIndex];
        
        NSString *categoryName = self.categoryNames[categoryIndex];
        
        CGFloat categoryButtonWidth = [categoryName sizeWithFont:categoryButton.titleLabel.font].width;
        categoryButtonWidth += 16.0f; //padding
        categoryButtonWidth = MAX(60.0f, categoryButtonWidth);
        CGFloat categoryButtonHeight = self.categoriesScrollView.height * 3.0f/4.0f;
        categoryButton.frame = CGRectMake(xOffset,
                                          (self.categoriesScrollView.height - categoryButtonHeight)/2.0f ,
                                          categoryButtonWidth,
                                          categoryButtonHeight);
        
        [categoryButton setTitle:categoryName forState:UIControlStateNormal];
        [categoryButton addTarget:self action:@selector(categoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.categoriesScrollView addSubview:categoryButton];
        
        xOffset += categoryButton.width + 10.0;
    }
    
    self.categoriesScrollView.contentSize = CGSizeMake(xOffset, self.categoriesScrollView.height);
}

- (void)setupUIForCategoryButton:(UIButton *)categoryButton atIndex:(NSInteger)index {
    categoryButton.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:index];
    
    categoryButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:12];
    //categoryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    //categoryButton.titleLabel.minimumScaleFactor = 0.1f;
    
    categoryButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 8.0f);
    
    [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    categoryButton.layer.cornerRadius = 5.0;
    categoryButton.layer.masksToBounds = YES;
    
    // drop shadow
    //    categoryButton.layer.shadowColor = [[UIColor colorWithHexString:ASPHALT] CGColor];
    //    categoryButton.layer.shadowRadius = 2.0f;
    //    categoryButton.layer.shadowOpacity = 3.0f;
    //    categoryButton.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
    
    categoryButton.titleLabel.numberOfLines = 1;
    categoryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)categoryButtonPressed:(UIButton *)button {
    NSString *toCategoryName = [button titleForState:UIControlStateNormal];
    
    if (![toCategoryName isEqualToString:self.selectedCategoryName]) {
        self.selectedCategoryName = toCategoryName;
    }
    
    [YoAnalytics logEvent:YoEventTappedCategoryButton withParameters:@{YoParam_CATEGORY:toCategoryName?:@"no_category"}];
}

- (void)setSelectedCategoryName:(NSString *)selectedCategoryName {
    if (![_selectedCategoryName isEqualToString:selectedCategoryName]) {
        _selectedCategoryName = selectedCategoryName;
        [self updateStoreItems];
    }
}

- (void)subscribedButtonTappedForCell:(YoStoreItemCell *)cell {
    if (cell.item) {
        if (cell.item.username) {
            __weak YoStoreButton *subscribeButton = cell.subscribeButton;
            NSInteger rowNumber = [self.tableView indexPathForCell:cell].row;
            if ([[[[YoUser me] contactsManager] subscriptionsUsernames] containsObject:cell.item.username]) {
                subscribeButton.userInteractionEnabled = NO;
                [self unsubscribeToService:cell.item withCompletionBlock:nil];
                [self performTitleChangeAnimationOnButton:subscribeButton
                                                    delay:0.1
                                                 newTitle:NSLocalizedString(@"subscribe", nil).capitalizedString
                                      withCompletionBlock:^(BOOL finished) {
                                          subscribeButton.userInteractionEnabled = YES;
                                      }];
                
                [YoAnalytics logEvent:YoEventTappedUnsubscribeButton
                       withParameters:@{YoParam_USERNAME:cell.item.username?:@"no_username",
                                        YoParam_ROW_NUMBER:@(rowNumber),
                                        YoParam_CATEGORY:self.selectedCategoryName?:@"no_category"}];
            }
            else {
                subscribeButton.userInteractionEnabled = NO;
                [self subscribeToService:cell.item withCompletionBlock:nil];
                // delaying animation to avoid weird UI affect if user quickly
                // taps the button.
                
                [self performTitleChangeAnimationOnButton:subscribeButton
                                                    delay:0.1
                                                 newTitle:NSLocalizedString(@"subscribed!", nil).capitalizedString
                                      withCompletionBlock:^(BOOL finished) {
                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                              if (subscribeButton) {
                                                  // change text back appropriate title
                                                  [UIView animateWithDuration:0.2 animations:^{
                                                      subscribeButton.titleLabel.alpha = 0.0f;
                                                  } completion:^(BOOL finished) {
                                                      [UIView animateWithDuration:0.2 animations:^{
                                                          subscribeButton.titleLabel.alpha = 1.0f;
                                                          [subscribeButton setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
                                                      } completion:^(BOOL finished) {
                                                          subscribeButton.userInteractionEnabled = YES;
                                                      }];
                                                  }];
                                              }
                                          });
                                      }];
                
                [YoAnalytics logEvent:YoEventTappedSubscribeButton
                       withParameters:@{YoParam_USERNAME:cell.item.username?:@"no_username",
                                        YoParam_ROW_NUMBER:@(rowNumber),
                                        YoParam_CATEGORY:self.selectedCategoryName?:@"no_category"}];
            }
        }
        else {
            if (cell.item.url) {
                [self pushWebControllerForItem:cell.item];
            }
            else {
                DDLogWarn(@"%@ | %@ | Failed to parse urlString %@", [self class], NSStringFromSelector(@selector(subscribedButtonTappedForCell:)), cell.item.url.absoluteString);
            }
        }
    }
    else {
        DDLogWarn(@"%@ | %@ | Failed to parse itemData", [self class], NSStringFromSelector(@selector(subscribedButtonTappedForCell:)));
    }
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat heightAscpectRatio = 106.0f/375.0f;
    CGFloat height = width * heightAscpectRatio;
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.storeItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YoStoreItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YoStoreItemCell"];
    if ( ! cell) {
        cell = LOAD_NIB(@"YoStoreItemCell");
        __weak YoStoreController *weakSelf = self;
        cell.subscribeButtonTappedBlock = ^(YoStoreItemCell *cell) {
            [weakSelf subscribedButtonTappedForCell:cell];
        };
        
        cell.detailsButtonTappedBlock = ^(YoStoreItemCell *cell) {
            [weakSelf pushItemControllerForItem:cell.item andBackgroundColor:[[YoThemeManager sharedInstance] colorForRow:indexPath.row]];
            [YoAnalytics logEvent:YoEventDetailsButtonTapped withParameters:@{YoParam_USER_IDS:@[cell.item.itemID?:@"no_itemID"]}];
        };
    }
    
    YoStoreItem *item = self.storeItems[indexPath.row];
    [self prepareCell:cell forItem:item];
    cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    cell.backgroundColor = cell.contentView.backgroundColor;
    
    return cell;
}

- (void)prepareCell:(YoStoreItemCell *)cell forItem:(YoStoreItem *)item {
    [cell.profileImageView setImageWithURL:[self photoURLForForFileName:item.profilePictureFileName] placeholderImage:[UIImage imageNamed:@"Yo.png"]];
    cell.nameLabel.text = item.name;
    [cell.nameLabel sizeToFit];
    cell.descriptionLabel.text = item.itemDescription;
    [cell.descriptionLabel sizeToFit];
    cell.needsLocationImageView.hidden = item.needsLocation?NO:YES;
    cell.isVerifiedImageView.hidden = item.isOfficial?NO:YES;
    
    cell.item = item;
    if (cell.item.username) {
        if ([[YoApp currentSession].user.contactsManager.subscriptionsUsernames containsObject:item.username]) {
            [cell.subscribeButton setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
        }
        else {
            [cell.subscribeButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
        }
    }
    else {
        [cell.subscribeButton setTitle:NSLocalizedString(@"open", nil).capitalizedString forState:UIControlStateNormal];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YoStoreItem *item = self.storeItems[indexPath.row];
    [self pushItemControllerForItem:item andBackgroundColor:[[YoThemeManager sharedInstance] colorForRow:indexPath.row]];
}

#pragma mark - Navigation

- (void)pushItemControllerForItem:(YoStoreItem *)item andBackgroundColor:(UIColor *)backgroundColor {
    YoStoreItemController *itemController = [self.storyboard instantiateViewControllerWithIdentifier:YoStoreItemControllerID];
    [itemController configureWithItem:item];
    itemController.view.backgroundColor = backgroundColor;
    [self.navigationController pushViewController:itemController animated:YES];
}

- (void)pushWebControllerForItem:(YoStoreItem *)item {
    YoWebBrowserController *vc = [[YoWebBrowserController alloc] initWithUrl:item.url];
    vc.navigationItem.title = item.username?:item.name;
    // we want this controller to present beneath its navigaiton controller's
    // navigation bar. Since it's not opague at the time of writing this,
    // we need to set extendedLayoutIncludesOpaqueBars to YES
    vc.extendedLayoutIncludesOpaqueBars = YES;
    [self.navigationController pushViewController:vc animated:YES];
    
    vc.navigationController.navigationBar.backgroundColor = [self.navigationController.navigationBar.backgroundColor colorWithAlphaComponent:1.0f];
    if (IS_OVER_IOS(8.0)) {
        vc.navigationController.hidesBarsOnSwipe = NO;
    }
    [vc.navigationController setNavigationBarHidden:NO animated:YES];
}

@end
