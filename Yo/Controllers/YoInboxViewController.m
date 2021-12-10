//
//  YoInboxViewController.m
//  Yo
//
//  Created by Peter Reveles on 8/4/15.
//
//

#import "YoInboxViewController.h"
#import "YoPlaceholderView.h"
#import "YoInbox.h"
#import "YoObjectProvider.h"
#import "YoInboxThumbnailTableViewCell.h"
#import "YoInboxAudioTableViewCell.h"
#import "Yo+Utility.h"

@interface YoInboxCache : NSCache
- (void)cacheHeight:(NSNumber *)height forYo:(Yo *)yo;
- (NSNumber *)cachedHeightForYo:(Yo *)yo;
- (void)cacheUtilityButtons:(NSArray *)utilityButtons forYo:(Yo *)yo;
- (NSArray *)cachedUtilityButtonsForYo:(Yo *)yo;
@end

@interface YoInboxViewController () <UITableViewDelegate, UITableViewDataSource, SWTableViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) YoPlaceholderView *noContentPlaceholder;
@property (nonatomic, strong) YoObjectProvider *provider;
@property (nonatomic, strong) UIView *clearInboxFooterView;
@property (nonatomic, strong) YoInboxCache *cache;
@property (nonatomic, strong) UIImage *dismissYoImage;
@property (nonatomic, strong) NSDictionary *categoryIdentifierToCategory; // NSString to  UIUserNotificationCategory
@end

@interface YoInboxViewController (IOS7) <UIActionSheetDelegate>
@end

@implementation YoInboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // navigation controller
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:EMERALD];
    self.navigationController.navigationBar.translucent = NO;
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(dismiss)];
    
    UIBarButtonItem *fixedWidthItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidthItem.width = 8.0f;
    
    self.navigationController.navigationBar.topItem.rightBarButtonItems = @[fixedWidthItem, closeButton];
    
    // view
    self.view.layer.cornerRadius = 0.0;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.estimatedRowHeight = 90.0f;
    //self.tableView.rowHeight = 120.0f;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // register tableview cells
    [self.tableView registerClass:[YoInboxThumbnailTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([YoInboxThumbnailTableViewCell class])];
    [self.tableView registerClass:[YoInboxTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([YoInboxTableViewCell class])];
    [self.tableView registerClass:[YoInboxAudioTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([YoInboxAudioTableViewCell class])];
    
    [self.view addSubview:self.tableView];
    
    self.noContentPlaceholder = [self newPlaceholderViewWithEmptyContentMessage];
    self.noContentPlaceholder.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.noContentPlaceholder.hidden = YES;
    [self.view addSubview:self.noContentPlaceholder];
    
    self.cache = [[YoInboxCache alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inboxUpdatedWithNotification:)
                                                 name:@"YoInboxUpdated"
                                               object:nil];
    
    __weak YoInboxViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note)
    {
        [weakSelf.cache removeAllObjects];
    }];
    
    self.dismissYoImage = [UIImage imageNamed:@"yo_inbox_dismiss"];
}

- (void)viewWillAppear:(BOOL)animated {
    // compute categories
    [super viewWillAppear:animated];
    self.categoryIdentifierToCategory = [self newCategoryIdentifierToCategoryDictionary];
    [self reloadData];
}

- (NSDictionary *)newCategoryIdentifierToCategoryDictionary {
    NSMutableDictionary *categoryIdentifierToCategoryDictionary = nil;
    
    if (IS_OVER_IOS(8.0)) {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        NSSet *categories = [settings.categories copy];
        
        categoryIdentifierToCategoryDictionary = [[NSMutableDictionary alloc] initWithCapacity:categories.count];
        
        [categories enumerateObjectsUsingBlock:^(UIUserNotificationCategory *category, BOOL *stop) {
            if (category.identifier != nil) {
                categoryIdentifierToCategoryDictionary[category.identifier] = category;
            }
        }];
    }
    
    return categoryIdentifierToCategoryDictionary;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[AVAudioSession sharedInstance] setActive:NO error: nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismiss {
    [self closeWithCompletionBlock:nil];
}

- (UIView *)newFooterView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.width, 60.0f)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor clearColor];
    // divider
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, view.width, 0.5f)];
    divider.backgroundColor = [UIColor whiteColor];
    divider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:divider];
    // clear inbox button
    UIButton *clearInboxButton = [self newClearInboxButton];
    [view addSubview:clearInboxButton];
    clearInboxButton.center = view.center;
    clearInboxButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    return view;
}

- (UIButton *)newClearInboxButton {
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [UIColor clearColor];
    [button setTitle:@"Dismiss All" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clearInbox:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont fontWithName:MontserratRegular size:17.0f];
    button.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    button.showsTouchWhenHighlighted = YES;
    [button sizeToFit];
    return button;
}

- (YoPlaceholderView *)newPlaceholderViewWithEmptyContentMessage {
    YoPlaceholderView *placeholderView = [[YoPlaceholderView alloc] initWithFrame:self.view.frame
                                                                            title:NSLocalizedString(@"All Done", nil)
                                                                          message:NSLocalizedString(@"You've seen all your Yos.", nil)
                                                                            image:nil
                                                                      buttonTitle:nil
                                                                     buttonAction:nil];
    return placeholderView;
}

- (void)reloadData {
    self.provider = [[YoObjectProvider alloc] initWithObjects:[[YoUser me].yoInbox getYosWithStatus:YoStatusReceived]];
    [self.tableView reloadData];
    [self updatePlaceholder];
}

- (void)updatePlaceholder {
    self.noContentPlaceholder.hidden = (self.provider.objects.count > 0);
    self.tableView.hidden = !self.noContentPlaceholder.hidden;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self.cache removeAllObjects];
}

#pragma mark - Notifications

- (void)inboxUpdatedWithNotification:(NSNotification *)notification {
    NS_DURING
    NSArray *oldYos = self.provider.objects;
    NSArray *newYos = [[[YoUser me] yoInbox] getYosWithStatus:YoStatusReceived];
    
    if (newYos.count == 0) {
        [self reloadData];
        return;
    }
    
    NSOrderedSet *oldItemSet = [NSOrderedSet orderedSetWithArray:oldYos];
    NSOrderedSet *newItemSet = [NSOrderedSet orderedSetWithArray:newYos];
    
    NSMutableOrderedSet *deletedItems = [oldItemSet mutableCopy];
    [deletedItems minusOrderedSet:newItemSet];
    
    NSMutableOrderedSet *newItems = [newItemSet mutableCopy];
    [newItems minusOrderedSet:oldItemSet];
    
    NSMutableOrderedSet *movedItems = [newItemSet mutableCopy];
    [movedItems intersectOrderedSet:oldItemSet];
    
    NSMutableArray *deletedIndexPaths = [NSMutableArray arrayWithCapacity:[deletedItems count]];
    for (id deletedItem in deletedItems) {
        [deletedIndexPaths addObject:[NSIndexPath indexPathForItem:[oldItemSet indexOfObject:deletedItem] inSection:0]];
    }
    
    NSMutableArray *insertedIndexPaths = [NSMutableArray arrayWithCapacity:[newItems count]];
    for (id newItem in newItems) {
        [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:[newItemSet indexOfObject:newItem] inSection:0]];
    }
    
    NSMutableArray *fromMovedIndexPaths = [NSMutableArray arrayWithCapacity:[movedItems count]];
    NSMutableArray *toMovedIndexPaths = [NSMutableArray arrayWithCapacity:[movedItems count]];
    for (id movedItem in movedItems) {
        [fromMovedIndexPaths addObject:[NSIndexPath indexPathForItem:[oldItemSet indexOfObject:movedItem] inSection:0]];
        [toMovedIndexPaths addObject:[NSIndexPath indexPathForItem:[newItemSet indexOfObject:movedItem] inSection:0]];
    }
    
    self.provider = [[YoObjectProvider alloc] initWithObjects:newYos];
    
    [self.tableView beginUpdates];
    
    if ([deletedIndexPaths count]) {
        [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    
    if ([insertedIndexPaths count]) {
        [self.tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    
    [fromMovedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSUInteger idx, BOOL *stop) {
        NSIndexPath *toIndexPath = toMovedIndexPaths[idx];
        [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }];
    
    [self.tableView endUpdates];
    
    [self updatePlaceholder];
    
    NS_HANDLER
    [self reloadData];
    NS_ENDHANDLER
}

#pragma mark - Actions

- (void)clearInbox:(id)sender {
    if (IS_OVER_IOS(8.0)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", nil)
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss All?", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action)
                          {
                              [[YoUser me].yoInbox updateYos:self.provider.objects withStatus:YoStatusDismissed];
                              [self closeWithCompletionBlock:nil];
                          }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil)
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                   destructiveButtonTitle:NSLocalizedString(@"Dismiss All?", nil)
                                                        otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
}

#pragma mark - Lazy Load

- (UIView *)clearInboxFooterView {
    if (_clearInboxFooterView == nil) {
        _clearInboxFooterView = [self newFooterView];
    }
    return _clearInboxFooterView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section > 0) {
        return 0;
    }
    return self.provider.objects.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.provider.objects.count > 0) {
        return 2;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && self.provider.objects.count > 0) {
        return self.clearInboxFooterView.size.height;
    }
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1 && self.provider.objects.count > 0) {
        return self.clearInboxFooterView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Yo *yo = [self.provider objectAtIndex:indexPath.row];
    
    NSNumber *heightThatFits = [self.cache cachedHeightForYo:yo];
    if (heightThatFits == nil) {
        YoInboxTableViewCell *cell = [self dequeueReusableCellForYo:yo fromTableView:tableView atIndexPath:nil];
        [cell configureForYo:yo];
        NSArray *rightButtons = [self rightButtonItemsForYo:yo];
        if (rightButtons.count > 0) {
            cell.bottomRightLabel.text = NSLocalizedString(@"Swipe to Reply", nil);
        }
        CGSize maxWidthMinHeightSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), 0.0f);
        CGSize size = [cell yo_systemLayoutSizeFittingSize:maxWidthMinHeightSize];
        heightThatFits = [NSNumber numberWithFloat:size.height];
        [self.cache cacheHeight:heightThatFits forYo:yo];
    }
    
    return [heightThatFits floatValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Yo *yo = [self.provider objectAtIndex:indexPath.row];
    YoInboxTableViewCell *cell = [self dequeueReusableCellForYo:yo fromTableView:tableView atIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    [cell configureForYo:yo];
    NSMutableArray *rightButtons = [[NSMutableArray alloc] initWithCapacity:3];
    [rightButtons sw_addUtilityButtonWithColor:[UIColor clearColor]
                                          icon:self.dismissYoImage];
    NSArray *yoSpecififcRightButtons = [self rightButtonItemsForYo:yo];
    if (yoSpecififcRightButtons.count > 0) {
        cell.bottomRightLabel.text = NSLocalizedString(@"Swipe to Reply", nil);
        [rightButtons addObjectsFromArray:yoSpecififcRightButtons];
    }
    cell.rightUtilityButtons = rightButtons;
    cell.delegate = self;
    return cell;
}

- (YoInboxTableViewCell *)dequeueReusableCellForYo:(Yo *)yo fromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath != nil) {
        if ([yo hasAudioURL]) {
            return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxAudioTableViewCell class]) forIndexPath:indexPath];
        }
        
        if (yo.thumbnailURL != nil) {
            return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxThumbnailTableViewCell class]) forIndexPath:indexPath];
        }
        
        // default basic Yo Cell.
        return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxTableViewCell class]) forIndexPath:indexPath];
    }
    else {
        if ([yo hasAudioURL]) {
            return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxAudioTableViewCell class])];
        }
        
        if (yo.thumbnailURL != nil) {
            return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxThumbnailTableViewCell class])];
        }
        
        // default basic Yo Cell.
        return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoInboxTableViewCell class])];
    }
}

- (NSArray *)rightButtonItemsForYo:(Yo *)yo {
    
    if (IS_UNDER_IOS(8.0)) {
        // should handle this.
        return nil;
    }
    
    NSArray *utilityButtons = [self.cache cachedUtilityButtonsForYo:yo];
    if (utilityButtons == nil) {
        NSString *categoryIdentifier = yo.payload[@"category"];
        
        if (categoryIdentifier == nil) {
            return nil; // Yo doesn't have category
        }
        
        UIUserNotificationCategory *categoryForYo = [self categoryWithIdentifier:categoryIdentifier];
        
        if (categoryForYo == nil) {
            return nil; // The category specified by this Yo has not been registered
        }
        
        NSArray *actions = [categoryForYo actionsForContext:UIUserNotificationActionContextDefault];
        
        NSMutableArray *rightUtilityButtons = [[NSMutableArray alloc] init];
        
        NSArray *colors = @[
                            [UIColor colorWithRed:12.0f/255.0f green:96.0f/255.0f blue:254.0f/255.0f alpha:1.0f],
                            [[UIColor whiteColor] colorWithAlphaComponent:0.14f]
                            ];
        
        for (NSInteger actionIndex = actions.count - 1; actionIndex >= 0; actionIndex--) {
            UIUserNotificationAction *action = actions[actionIndex];
            [rightUtilityButtons sw_addUtilityButtonWithColor:colors[actionIndex] title:action.title];
        }
        
        utilityButtons = rightUtilityButtons;
        [self.cache cacheUtilityButtons:utilityButtons forYo:yo];
    }
    
    return utilityButtons;
}

- (UIUserNotificationCategory *)categoryWithIdentifier:(NSString *)identifier {
    return self.categoryIdentifierToCategory[identifier];
}

#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.row >= [self.provider.objects count]) {
        return;
    }
    Yo *yo = [self.provider objectAtIndex:indexPath.row];
    
    if (index != 0) { // default action delete yo 0
        NSInteger actionIndex = index - 1;
        NSString *categoryIdentifier = yo.payload[@"category"];
        
        UIUserNotificationCategory *categoryForYo = [self categoryWithIdentifier:categoryIdentifier];
        
        NSArray *actions = [categoryForYo actionsForContext:UIUserNotificationActionContextDefault];
        
        UIUserNotificationAction *action = (actionIndex == 0) ? [actions lastObject] : [actions firstObject];
        
        [APPDELEGATE application:[UIApplication sharedApplication] handleActionWithIdentifier:action.identifier forRemoteNotification:yo.payload completionHandler:^{}];
    }
    
    [[YoUser me].yoInbox updateYos:@[yo] withStatus:YoStatusRead];
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NS_DURING
    Yo *yoObject = [self.provider objectAtIndex:indexPath.row];
    [yoObject open];
    
    NS_HANDLER
    DDLogError(@"%@", localException);
    NS_ENDHANDLER
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[YoInboxAudioTableViewCell class]]) {
        [(YoInboxAudioTableViewCell *)cell pauseAudio];
    }
}

@end

@implementation YoInboxViewController (IOS7)

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [[YoUser me].yoInbox updateYos:self.provider.objects withStatus:YoStatusDismissed];
    }
}

@end

@implementation YoInboxCache

- (void)cacheHeight:(NSNumber *)height forYo:(Yo *)yo {
    NSString *heightKey = [NSString stringWithFormat:@"yo_height_%@", yo.yoID];
    [self setObject:height forKey:heightKey];
}

- (NSNumber *)cachedHeightForYo:(Yo *)yo {
    NSString *heightKey = [NSString stringWithFormat:@"yo_height_%@", yo.yoID];
    return [self objectForKey:heightKey];
}

- (void)cacheUtilityButtons:(NSArray *)utilityButtons forYo:(Yo *)yo {
    NSString *utilityButtonsKey = [NSString stringWithFormat:@"yo_utility_buttons_%@", yo.yoID];
    [self setObject:utilityButtons forKey:utilityButtonsKey];
}

- (NSArray *)cachedUtilityButtonsForYo:(Yo *)yo {
    NSString *utilityButtonsKey = [NSString stringWithFormat:@"yo_utility_buttons_%@", yo.yoID];
    return [self objectForKey:utilityButtonsKey];
}

@end