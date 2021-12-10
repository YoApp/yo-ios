//
//  YoStoreItemController.m
//  Yo
//
//  Created by Or Arbel on 2/15/15.
//
//

#import "YoStoreItemController.h"
#import "YoStoreItemHeaderCollectionViewCell.h"
#import "YoStoreItemDescriptionCollectionViewCell.h"
#import "YoStoreItemScreenShotsCollectionViewCell.h"
#import <SwipeView/SwipeView.h>
#import <JBWhatsAppActivity/JBWhatsAppActivity.h>
#import "YoShareSheet.h"
#import "YoWebBrowserController.h"

#define kTagImageView 33524

@interface YoStoreItemController () <SwipeViewDataSource, SwipeViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
@property (nonatomic, strong) YoStoreItem *item;
@property(nonatomic, strong) NSMutableArray *screenshotURLStrings;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property(nonatomic, weak) YoStoreItemHeaderCollectionViewCell *weakHeaderCell;
@property(nonatomic, weak) YoStoreItemDescriptionCollectionViewCell *weakDescriptionCell;
@property(nonatomic, weak) YoStoreItemScreenShotsCollectionViewCell *weakScreenShotCell;

@property (nonatomic, strong) UIImage *itemShareImage;
@end

@implementation YoStoreItemController

#pragma mark - Life

- (instancetype)initForItem:(YoStoreItem *)item {
    self = [super init];
    if (self) {
        //setup
        [self configureWithItem:item];
    }
    return self;
}

- (void)configureWithItem:(YoStoreItem *)item {
    if (![_item isEqualToItem:item]) {
        _item = item;
        self.screenshotURLStrings = [[NSMutableArray alloc] initWithCapacity:item.screenShotFileNames.count];
        for (NSString *filename in item.screenShotFileNames) {
            [self.screenshotURLStrings addObject:[self screenshotURLForFilename:filename]];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.minimumLineSpacing = 0.0f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"YoStoreItemHeaderCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:@"YoStoreItemHeaderCellID"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"YoStoreItemDescriptionCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"YoStoreItemDescriptionCellID"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"YoStoreItemScreenShotsCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"YoStoreItemScreenShotCellID"];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.backgroundColor = self.view.backgroundColor;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (IS_OVER_IOS(8.0)) {
        self.navigationController.hidesBarsOnSwipe = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [YoAnalytics logEvent:YoEventStoreItemOpened withParameters:@{YoParam_USER_IDS:@[self.item.itemID?:@"no_id"]}];
}

- (void)setupUI {
    UIBarButtonItem *fixedWidth = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidth.width = 5.0f;
    
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(userDidTapShareButton)];
    self.navigationItem.rightBarButtonItems = @[fixedWidth, shareItem];
}

//- (NSString *)title {
//    return self.itemName;
//}

#pragma mark - Actions

- (void)userDidTapShareButton {
    UIImage *shareImage = self.itemShareImage;
    
    NSString *yoURlString = @"http://justyo.co/";
    
    if ([self.item.username length]) {
        yoURlString = [yoURlString stringByAppendingString:self.item.username];
    }
    
    NSURL *yoURL = [[NSURL alloc] initWithString:yoURlString];
    
    NSString *standardShareText = MakeString(@"%@ - Yo", self.item.username?:self.item.name);
    
    NSArray *sharingItems = @[standardShareText, yoURL, shareImage];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [APPDELEGATE.topVC presentViewController:activityController animated:YES completion:nil];

    
    //YoShareSheet *shareVC = [[YoShareSheet alloc] initForURL:yoURL message:standardShareText image:shareImage];
    //[shareVC show];
}

- (void)subscribedButtonTapped:(YoStoreButton *)sender {
    if (self.item.username) {
        if ([[[[YoUser me] contactsManager] subscriptionsUsernames] containsObject:self.item.username]) {
            sender.userInteractionEnabled = NO;
            [self unsubscribeToService:self.item withCompletionBlock:nil];
            [self performTitleChangeAnimationOnButton:sender
                                                delay:0.1
                                             newTitle:NSLocalizedString(@"subscribe", nil).capitalizedString
                                  withCompletionBlock:^(BOOL finished) {
                                      sender.userInteractionEnabled = YES;
                                  }];
            
            [YoAnalytics logEvent:YoEventTappedUnsubscribeButton
                   withParameters:@{YoParam_USERNAME:self.item.username?:@"no_username"}];
        }
        else {
            sender.userInteractionEnabled = NO;
            [self subscribeToService:self.item withCompletionBlock:nil];
            // delaying animation to avoid weird UI affect if user quickly
            // taps the button.
            [self performTitleChangeAnimationOnButton:sender
                                                delay:0.1
                                             newTitle:NSLocalizedString(@"subscribed!", nil).capitalizedString
                                  withCompletionBlock:^(BOOL finished) {
                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                          [UIView animateWithDuration:0.2 animations:^{
                                              sender.titleLabel.alpha = 0.0f;
                                          } completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.2 animations:^{
                                                  sender.titleLabel.alpha = 1.0f;
                                                  [sender setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
                                              } completion:^(BOOL finished) {
                                                  sender.userInteractionEnabled = YES;
                                              }];
                                          }];
                                      });
                                  }];
            
            [YoAnalytics logEvent:YoEventTappedSubscribeButton
                   withParameters:@{YoParam_USERNAME:self.item.username?:@"no_username"}];
        }
    }
    else if (self.item.url) {
        [self pushWebControllerForItem:self.item];
    }
    else {
        DDLogWarn(@"%@ | %@ | Failed to subscribe due to missing info", [self class], NSStringFromSelector(@selector(subscribedButtonTapped:)));
    }
}

#pragma mark - Internal

- (UIImage *)itemShareImage {
    if (!_itemShareImage) {
        _itemShareImage = [YoShareSheet yoBrandGraphicFormessage:MakeString(@"%@ Yo", self.item.username?:self.item.name) purpleTop:YES];
    }
    return _itemShareImage;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateTitleInNavigationBar:self.navigationController.navigationBar ifNeededForScrollViewContentOffset:scrollView.contentOffset];
}

- (void)updateTitleInNavigationBar:(UINavigationBar *)navigationBar ifNeededForScrollViewContentOffset:(CGPoint)contentOffset {
    if (self.weakHeaderCell) {
        CGFloat bottomOfItemNameLabel = CGRectGetMaxY(self.weakHeaderCell.itemTitleLabel.frame);
        CGPoint bottomCenterPointOFNameLabel = CGPointMake(self.weakHeaderCell.itemTitleLabel.center.x, bottomOfItemNameLabel);
        bottomCenterPointOFNameLabel = [self.view convertPoint:bottomCenterPointOFNameLabel fromView:self.weakHeaderCell];
        
        CATransition *fadeTextAnimation = [CATransition animation];
        fadeTextAnimation.duration = 0.3;
        fadeTextAnimation.type = kCATransitionFade;
        
        [navigationBar.layer addAnimation:fadeTextAnimation forKey:@"fadeText"];
        
        if (![navigationBar.topItem.title length] && contentOffset.y > bottomCenterPointOFNameLabel.y) {
            // display item name in navigation bar
            navigationBar.topItem.title = self.item.username?:self.item.name;
        }
        else if ([navigationBar.topItem.title length] && contentOffset.y <= bottomCenterPointOFNameLabel.y) {
            // clear title
            navigationBar.topItem.title = nil;
        }
    }
}

- (void)updateNavigationBarRightItemsToIncludeSubscribeButton:(BOOL)includeSubscribeButton aniamted:(BOOL)aniamted {
    NSMutableArray *rightBarButtonItems = [[self.navigationItem rightBarButtonItems] mutableCopy];
    
    if (includeSubscribeButton) {
        CGFloat width = 84.0f;
        CGFloat heightAscpectRatio = 1.0f/3.0f;
        CGFloat height = width * heightAscpectRatio;
        
        YoStoreButton *yoButton = [[YoStoreButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, height)];
        yoButton.style = YoStoreButtonStyleBordered;
        
        if (self.item) {
            if ([[[[YoUser me] contactsManager] subscriptionsObjects] containsObject:self.item]) {
                [yoButton setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
            }
            else {
                [yoButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
            }
        }
        else if (self.item.url) {
            [yoButton setTitle:NSLocalizedString(@"open", nil).capitalizedString forState:UIControlStateNormal];
        }
        
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:yoButton];
        [barButtonItem setTarget:self];
        [barButtonItem setAction:nil];
        
        [rightBarButtonItems insertObject:barButtonItem atIndex:0];
        
        [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:YES];
    }
    else {
        id firstBarButtonItem = [rightBarButtonItems firstObject];
        [rightBarButtonItems removeObject:firstBarButtonItem];
        [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:YES];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            YoStoreItemHeaderCollectionViewCell *headerCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YoStoreItemHeaderCellID" forIndexPath:indexPath];
            
            [headerCell.itemImageView setImageWithURL:[self photoURLForForFileName:self.item.profilePictureFileName] placeholderImage:nil];
            headerCell.itemTitleLabel.text = self.item.username?:self.item.name;
            self.weakHeaderCell = headerCell;
            headerCell.isOfficialImageView.hidden = self.item.isOfficial?NO:YES;
            __weak YoStoreItemHeaderCollectionViewCell *weakHeaderCell = headerCell;
            
            if (self.item.username) {
                if ([[[[YoUser me] contactsManager] subscriptionsUsernames] containsObject:self.item.username]) {
                    [headerCell.itemSubscriptionButton setTitle:NSLocalizedString(@"unsubscribe", nil).capitalizedString forState:UIControlStateNormal];
                }
                else {
                    [headerCell.itemSubscriptionButton setTitle:NSLocalizedString(@"subscribe", nil).capitalizedString forState:UIControlStateNormal];
                }
            }
            else if (self.item.url) {
                [headerCell.itemSubscriptionButton setTitle:NSLocalizedString(@"open", nil).capitalizedString forState:UIControlStateNormal];
            }
            
            headerCell.subcribeButtonTapBlock = ^() {
                [self subscribedButtonTapped:weakHeaderCell.itemSubscriptionButton];
            };
            return headerCell;
        }
            break;
            
        case 1:{
            YoStoreItemDescriptionCollectionViewCell *descriptionCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YoStoreItemDescriptionCellID" forIndexPath:indexPath];
            descriptionCell.itemDescriptionLabel.text = self.item.itemDescription;
            self.weakDescriptionCell = descriptionCell;
            return descriptionCell;
        }
            break;
            
        case 2:{
            YoStoreItemScreenShotsCollectionViewCell *screenShotCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YoStoreItemScreenShotCellID" forIndexPath:indexPath];
            screenShotCell.swipeView.pagingEnabled = YES;
            
            screenShotCell.swipeView.layer.masksToBounds = NO;
            screenShotCell.swipeView.dataSource = self;
            screenShotCell.swipeView.delegate = self;
            screenShotCell.swipeView.alignment = SwipeViewAlignmentCenter;
            screenShotCell.swipeView.backgroundColor = self.view.backgroundColor;
            
            screenShotCell.pageControl.numberOfPages = self.screenshotURLStrings.count;
            
            [screenShotCell.swipeView reloadData];
            self.weakScreenShotCell = screenShotCell;
            return screenShotCell;
        }
            break;
            
        default:
            return nil;
            break;
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            CGFloat aspectRatio = 105.0f/320.0f;
            CGFloat height = width * aspectRatio;
            CGSize size = CGSizeMake(width, height);
            return size;
        }
            break;
            
        case 1: {
            CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            //CGFloat aspectRatio = 96.0f/320.0f;
            //CGFloat height = width * aspectRatio;
            NSInteger numberOfLinesRequiredToDisplayText = [self numberOfLinesRequiredToDisplayText:self.item.itemDescription
                                                                                           withFont:[UIFont fontWithName:@"Montserrat-Bold" size:14] inWidth:(width - 24.0f)];
            CGFloat height = (numberOfLinesRequiredToDisplayText * 22.0f) + 24.0f + 20.0f;
            height = MAX(height, 78.0f);
            CGSize size = CGSizeMake(width, height);
            return size;
        }
            break;
            
        case 2: {
            CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            CGFloat aspectRatio = 511.0f/320.0f;
            CGFloat height = width * aspectRatio;
            CGSize size = CGSizeMake(width, height);
            return size;
        }
            break;
            
        default:
            return CGSizeZero;
            break;
    }
}

- (NSUInteger)numberOfLinesRequiredToDisplayText:(NSString *)text withFont:(UIFont *)font inWidth:(CGFloat)maxWidth{
    CGSize textDisplaySize = CGSizeZero;
    
    if (![text length] || !font || !maxWidth) return 0.0;
    
    NSDictionary *attributes = @{NSFontAttributeName: font};
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    textDisplaySize = rect.size;
    
    NSUInteger linesRequiredBasedOfTextSize = ceil(textDisplaySize.height/22);
    
    //    if (IS_OVER_IOS(7.0)) linesRequiredBasedOfTextSize++;
    
    NSUInteger linesRequired = linesRequiredBasedOfTextSize;
    
    return linesRequired;
}

// 3
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//    return UIEdgeInsetsMake(50, 20, 50, 20);
//}

#pragma mark SwipView Delegate

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView {
    self.weakScreenShotCell.pageControl.currentPage = swipeView.currentItemIndex;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView {
    return self.screenshotURLStrings.count;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    self.weakScreenShotCell.swipeView.itemsPerPage = 1.3;
    
    if ([self.screenshotURLStrings count] == 1) {
        swipeView.truncateFinalPage = YES;
    }
    else {
        swipeView.alignment = SwipeViewAlignmentEdge;
    }
    
    swipeView.truncateFinalPage = YES;
    if ( ! view) {
        CGFloat imageSpacing = (CGRectGetWidth([[UIScreen mainScreen] bounds]) - self.weakScreenShotCell.swipeView.frame.size.width)/2.0f;
        
        CGFloat heightAscpectRatio = 568.0f/320.0f;
        
        CGFloat widthAspectRatio = 280.0f/375.0f;
        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]) * widthAspectRatio;
        CGFloat height = width * heightAscpectRatio;
        
        CGFloat sideMargin = ([self.screenshotURLStrings count] == 1)?0.0f:imageSpacing;
        
        //320 x 568
        view = [UIView new];
        view.frame = CGRectMake(0.0f,
                                0.0f,
                                width + sideMargin,
                                height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, height)];
        imageView.tag = kTagImageView;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [view addSubview:imageView];
    }
    
    [(UIImageView *)[view viewWithTag:kTagImageView] setImageWithURL:self.screenshotURLStrings[index]];
    return view;
}

#pragma mark - Navigation

- (void)pushWebControllerForItem:(YoStoreItem *)item {
    YoWebBrowserController *vc = [[YoWebBrowserController alloc] initWithUrl:item.url];
    vc.navigationItem.title = item.username?:item.name;
    vc.extendedLayoutIncludesOpaqueBars = YES;
    vc.navigationController.navigationBar.backgroundColor = [self.navigationController.navigationBar.backgroundColor colorWithAlphaComponent:1.0f];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
