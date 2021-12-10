//
//  YOMainController.m
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YoMainController.h"
#import "YOMenuController.h"
#import <Crashlytics/Crashlytics.h>
#import "RavenClient.h"
#import "YOEnableLocationController.h"
#import "YOActionCell.h"
#import "YOShareCell.h"
#import "YoThemeManager.h"
#import "NSDate_Extentions.h"
#import "YOAppDelegate.h"
#import "MobliConfigManager.h"
#import "MBProgressHUD.h"
#import "YoLocationManager.h"
#import "YoAddController.h"
#import "YoImgUploadClient.h"
#import "YoShareSheet.h"
#import "YoConfigManager.h"
#import "YOFacebookManager.h"
#import "YoContacts.h"
#import <JBWhatsAppActivity/JBWhatsAppActivity.h>
#import "YoStoreController.h"
#import "YoStoreDataManager.h"
#import "YoServiceActionCell.h"
#import "YoStoreTabBarController.h"
#import "YoCreateGroupController.h"
#import <MapKit/MapKit.h>
#import "YoUserProfileViewController.h"
#import "YoGroup.h"
#import "YoViewGroupController.h"
#import "YoMenuTransitionAnimator.h"
#import "YoNavigationController.h"
#import "YoService.h"
#import "YoNavigationController.h"
#import "YoAddPickerController.h"
#import "YoCardTransitionAnimator.h"
#import "YoAddFriendController.h"
#import <FXBlurView/FXBlurView.h>
#import "YoiOSAssistant.h"
#import "UIView_Extensions.h"
#import "YoInbox.h"
#import "YoTipController.h"

#import "YoPushNotificationPermissionRequestor.h"
#import "YoNotification.h"
#import "YoBannerNotificationPresentationManager.h"
#import "YoBannerStore.h"
#import "YoBannerView.h"
#import "YoDataAccessManager.h"
#import "YoContextFactory.h"
#import "YoContextConfiguration.h"

// contexts
#import "YoContextObject.h"
#import "YoEasterEggContext.h"
#import "YoEmojiContext.h"
#import "YoLastPhotoContext.h"
#import "YoCameraContext.h"
#import "YoClipboardContext.h"
#import "YoLastPhotoContext.h"

#import "YoUserTableViewCell.h"
#import "YoRecordingView.h"

#import "YoCreateGroupSuggestor.h"

#import "YoContact.h"

#import "YoCreateGroupPopupViewController.h"

#import "YoContextView.h"
#import "YoInboxViewController.h"

#define kTimeForDoubleTap 0.3
#define kTagTextFieldUsername 452
#define CellColorOpacity 1.f

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

enum {
    SignupStepEnterUsername       = 0,
    SignupStepSendYo = 1,
    SignupStepShowIndex = 2,
    SignupStepDisplayAskForNumber = 3,
};

enum {
    AddActionSheetAddFriend,
    AddActionSheetCreateGroup
};

typedef NS_ENUM(NSUInteger, YoMCLoadingState) {
    YoMCLoadingStateInitial,
    YoMCLoadingStateLoading,
    YoMCLoadingStateRefreshing,
    YoMCLoadingStateNoContent,
    YoMCLoadingStateContentAvailble,
    YoMCLoadingStateError
};

NSString *const YoConfigurationShowsLoaderKey = @"YoConfigurationShowsLoaderKey";
NSString *const YoConfigurationShowsPlaceholderKey = @"YoConfigurationShowsPlaceholderKey";
NSString *const YoConfigurationPlaceholderTextKey = @"YoConfigurationPlaceholderTextKey";
NSString *const YoConfigurationUserInteractionDisabledKey = @"YoConfigurationUserInteractionDisabled";
NSString *const YoConfigurationFakedLastYoSucessKey = @"YoConfigurationFakedLastYoSucessKey";

@interface YoMainController () <UIGestureRecognizerDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UIViewControllerTransitioningDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, YoBannerViewDelegate, YoCreateGroupSuggestorDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer *longGr;

@property (nonatomic, strong) YoContacts *contacts;

@property (nonatomic, strong) YoNavigationController *addFriendsNavigationController;
@property (nonatomic, strong) YoNavigationController *storeController;

@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UIView *plusButtonContainer;
@property (nonatomic, weak) IBOutlet YoButton *inboxButton;
@property (nonatomic, weak) IBOutlet UIButton *clearBigInboxButton;

@property (nonatomic, strong) NSTimer *displayStatusesTimer;
@property (nonatomic, assign) BOOL isShowingStatuses;

@property (nonatomic, strong) YoBannerNotificationPresentationManager *bannerManager;

@property (nonatomic, strong) IBOutlet UIButton *menuButton;
@property (nonatomic, strong) IBOutlet YoStatusBar *statusBar;
@property (nonatomic, strong) IBOutlet UIImageView *arrowUpIcon;

@property (nonatomic, strong) IBOutlet UIView *placeholderView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) YoBannerStore *bannerStore;
@property (nonatomic, assign) BOOL isShowingBanner;

@property (nonatomic, strong) NSMutableDictionary *usernameToCellConfiguration;
@property (nonatomic, weak) YoRecordingView *recordingOptions;

@property (nonatomic, strong) NSMutableArray *reloadedTableViewsDuringScroll;
@property (nonatomic, strong) YoCreateGroupSuggestor *createGroupSuggestor;

@property (nonatomic, strong) NSMutableArray *alreadyPresentedBanners;

// Yo Context
@property (nonatomic, strong) NSArray *contextIDs;
@property (nonatomic, strong) NSString *defaultContextID;

@property (nonatomic, strong) NSMutableArray *contextScrollViewConstraints;

@property (nonatomic, weak) IBOutlet UIScrollView *contextScrollView;
@property (nonatomic, assign) NSInteger currentContextIndex;

@property (nonatomic, strong) NSMutableArray *yoContextObjects;

@property (nonatomic, strong) NSMutableDictionary *contextIDToContextView;

@property (nonatomic, strong) NSMutableArray *contextViews;
@property (nonatomic, strong) NSMutableArray *contextTableViews;

@property (nonatomic, copy) void (^contextScrollViewAnimationCompletionBlock)();

@property (nonatomic, strong) YoEasterEggContext *easterEggContext;
@property (nonatomic, strong) YoCameraContext *cameraContext;
@property (nonatomic, strong) YoLastPhotoContext *lastPhotoContext;

@property (nonatomic, strong) YoUserTableViewCell *recordingCell;

@property (nonatomic, assign) BOOL moveToEasterEggWhenLoaded;

@property (nonatomic, assign) BOOL canceFakinglLastYo;

@property (nonatomic, assign) BOOL contextLocked;

@property (nonatomic, assign) YoMCLoadingState contactsLoadingState;

@end

@implementation YoMainController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.bannerManager = [[YoBannerNotificationPresentationManager alloc] init];
        self.bannerStore = [[YoBannerStore alloc] init];
        self.usernameToCellConfiguration = [[NSMutableDictionary alloc] init];
        self.reloadedTableViewsDuringScroll = [[NSMutableArray alloc] init];
        
        self.createGroupSuggestor = [[YoCreateGroupSuggestor alloc] init];
        self.createGroupSuggestor.timeProximityForGroupSuggestion = 2.0;
        self.createGroupSuggestor.delegate = self;
        
        self.alreadyPresentedBanners = [[NSMutableArray alloc] init];
        self.easterEggContext = [[YoEasterEggContext alloc] init];
        self.lastPhotoContext = [[YoLastPhotoContext alloc] init];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForgroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout:) name:kYoUserLoginDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLoginNotification:) name:kYoUserDidLoginNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidSigupNotification:) name:kYoUserDidSignupNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSessionRestoredNotification:) name:kYoUserSessionRestoredNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidBeginToSendYoFromYoCardNotification:) name:YoUserYoBackFromYoCardStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidFinishSendingYoFromYoCardNotification:) name:YoUserYoBackFromYoCardFinished object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContacts) name:kNotificationListChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxUpdated) name:@"YoInboxUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchedEasterEgg) name:YoNotificationFetchedEasterEgg object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(easterEggFailed) name:YoNotificationEasterEggFailed object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationServicesWhereDeniedNote:) name:YoNotificaitonLocationServicesDenied object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVMediaTypeVideoServicesWhereDeniedNote:) name:YoNotificaitonAVMediaTypeVideoServicesDenied object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextConfigurationDidChangeWithNotification:) name:YoNotificationContextDidUpdateConfiguration object:nil];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* [[YoContextConfiguration sharedInstance] updateWithCompletionHandler:^(BOOL didUpdate) {
     if (didUpdate) {
     [self reloadContextsIfNeeded];
     [self notifiyAllContextViewsToConfigure];
     }
     }];*/
    
    self.inboxButton.hidden = YES; // @or: fetching new yos in appDidBecomeActive
    self.contextScrollView.pagingEnabled = YES;
    self.contextScrollView.bounces = YES;
    self.contextScrollView.delegate = self;
    
    self.activityIndicator.center = self.view.center;
    [self.view addSubview:self.activityIndicator];
    
    [self reloadContexts];
    
    YoContextView *currentContextView =  self.contextIDToContextView[self.defaultContextID];
    [currentContextView setupForContextIfNeeded];
    
    if ([YoApp currentSession].isLoggedIn) {
        
        [[YoApp currentSession] refreshUserProfileWithCompletionBlock:nil];
        
        if ([YoUser me].contactsManager != nil) {
            
            [self reloadContacts];
            
            if ([self.contacts allContacts].count == 0) {
                [self updateContactsWithCompletionBlock:^(bool success) {
                    if ([self.contacts allContacts].count > 0) {
                        [self showLastYoStatuses];
                        [self presentBannerIfNeeded];
                    }
                }];
            }
        }
    }
    
    UISwipeGestureRecognizer *swipeGr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(presentMenuConroller)];
    swipeGr.direction = UISwipeGestureRecognizerDirectionDown;
    [self.placeholderView addGestureRecognizer:swipeGr];
    
    self.plusButtonContainer.layer.cornerRadius = self.plusButtonContainer.width/2.0;
    [self.plusButtonContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(presentYoPeoplePicker)]];
    
    self.plusButtonContainer.layer.masksToBounds = NO;
    self.plusButtonContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    self.plusButtonContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.plusButtonContainer.layer.shadowOffset = CGSizeMake(-3,-3);
    self.plusButtonContainer.layer.shadowOpacity = 1.0;
    self.plusButtonContainer.layer.shadowRadius = 5.0;
    
    [self.statusBar.pageControl addTarget:self action:@selector(valueChangedForPageControl:) forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusBarTapped)];
    [self.statusBar addGestureRecognizer:tapGr];
    
    CGRect initialContextViewBounds = [[UIScreen mainScreen] bounds];
    NSInteger defaultContextIndex = NSNotFound;
    for (NSInteger index = 0; index < self.yoContextObjects.count; index++) {
        YoContextObject *context = [self.yoContextObjects objectAtIndex:index];
        if ([[[context class] contextID] isEqualToString:self.defaultContextID]) {
            defaultContextIndex = index;
            break;
        }
    }
    
    if (defaultContextIndex != NSNotFound) {
        [self.contextScrollView setContentOffset:CGPointMake(initialContextViewBounds.size.width * defaultContextIndex, 0.0f)
                                        animated:NO];
        self.currentContextIndex = defaultContextIndex;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (APPDELEGATE.oauthURL && [[YoApp currentSession] isLoggedIn]) {
        [APPDELEGATE presentAuthorizationController:APPDELEGATE.oauthURL];
        APPDELEGATE.oauthURL = nil;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.inboxButton.layer.masksToBounds = NO;
    self.inboxButton.layer.shadowOffset = CGSizeMake(0.0f, 3.0f);
    self.inboxButton.layer.shadowRadius = 3.0f;
    self.inboxButton.layer.shadowOpacity = 0.5f;
    self.inboxButton.layer.borderColor = self.inboxButton.backgroundColor.CGColor;
    self.inboxButton.layer.borderWidth = 0.0f;
    self.inboxButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    self.inboxButton.layer.cornerRadius = self.inboxButton.width/2.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.currentContextObject contextDidAppear];
    [YoAnalytics logEvent:@"OpenedToContext" withParameters:@{@"context":[[self.currentContextObject class] contextID]?:@"NULL"}];
    [self hideBlurredBackground];
    
    if ([[YoApp currentSession] isLoggedIn]) {
        [self displayPermissionsBannerForCurrentContextIfNeeded];
    }
}

- (void)showFirstFriendPopupIfNeeded {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:MakeString(@"should_show_first_yo_tip_for_%@", [YoUser me].username)]) {
        YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Added friends" desciption:@"Tap their name to Yo them."];
        [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Sweet!", nil) tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:alert];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MakeString(@"did.show.first.yo.tip.%@", [YoUser me].username)];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MakeString(@"should_show_first_yo_tip_for_%@", [YoUser me].username)];
    }
}

#pragma mark - Interacting with Context Views

- (UITableView *)currentContextTableView {
    YoContextView *currentContextView = [self.contextViews objectAtIndex:self.currentContextIndex];
    if ([currentContextView respondsToSelector:@selector(tableView)]) {
        return currentContextView.tableView;
    }
    else {
        return nil;
    }
}

- (void)scrollToContextWithID:(NSString *)contextID animated:(BOOL)animated {
    for (NSInteger contextIndex = 0; contextIndex < self.yoContextObjects.count; contextIndex++) {
        YoContextObject *context = [self.yoContextObjects objectAtIndex:contextIndex];
        if ([[[context class] contextID] isEqualToString:contextID]) {
            [self scrollToContextAtIndex:contextIndex animated:animated];
            return;
        }
    }
}

- (void)scrollToContextAtIndex:(NSInteger)contextIndex animated:(BOOL)animated {
    if (contextIndex < self.contextViews.count) {
        CGRect contextFrame = [[self.contextViews objectAtIndex:contextIndex] frame];
        if (CGRectEqualToRect(CGRectZero, contextFrame)) {
            contextFrame = [self getDefaultContextFrameForContextAtIndex:contextIndex];
        }
        [self.contextScrollView scrollRectToVisible:contextFrame animated:animated];
        self.currentContextIndex = contextIndex;
    }
}

- (CGRect)getDefaultContextFrameForContextAtIndex:(NSUInteger)index {
    CGSize defaultSize = CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]),
                                    CGRectGetHeight([[UIScreen mainScreen] bounds]));
    CGRect defaultFrame = CGRectMake(defaultSize.width * index,
                                     0.0f,
                                     defaultSize.width,
                                     defaultSize.height);
    return defaultFrame;
}

- (void)setCurrentContextIndex:(NSInteger)currentContextIndex {
    if (_currentContextIndex != currentContextIndex) {
        NSInteger oldContextIndex = _currentContextIndex;
        _currentContextIndex = currentContextIndex;
        [self contextDidChangeFromIndex:oldContextIndex toIndex:currentContextIndex];
    }
}

- (void)contextDidChangeFromIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex {
    
    if (self.isShowingBanner) {
        [self.bannerManager hideCurrentNotificationWithCompletionBlock:nil];
    }
    
    if (newIndex == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did.swipe.right"];
    }
    else if (newIndex == 2) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did.swipe.left"];
    }
    
    self.statusBar.pageControl.currentPage = newIndex;
    
    [self updateContextButtonLayoutAtIndex:oldIndex animated:NO];
    [self updateContextButtonLayoutAtIndex:newIndex animated:YES];
    
    if (newIndex >= self.yoContextObjects.count) { // Yo Store screen
        self.menuButton.hidden = YES;
        self.plusButtonContainer.hidden = YES;
        self.inboxButton.hidden = YES;
        self.clearBigInboxButton.hidden = YES;
        return;
    }
    
    YoContextObject *oldContextObject = nil;
    if (oldIndex < self.yoContextObjects.count) {
        oldContextObject = self.yoContextObjects[oldIndex];
    }
    YoContextObject *newContextObject = self.yoContextObjects[newIndex];
    
    self.currentContextObject = newContextObject;
    
    [oldContextObject contextDidDisappear];
    [newContextObject contextDidAppear];
    
    if ([self.currentContextObject doesNeedSpecialPermission]) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:[self.currentContextObject titleForPermissionAlert]
                                               desciption:[self.currentContextObject textForPopupPriorToAskingPermission]];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:[self.currentContextObject textForPermissionButton] tapBlock:^{
            [self.currentContextObject askForSpecialPermission];
        }]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
    
    self.menuButton.hidden = NO;
    self.plusButtonContainer.hidden = NO;
    self.statusBar.hidden = NO;
    self.inboxButton.hidden = [[[[YoUser me] yoInbox] getYosWithStatus:YoStatusReceived] count] == 0;
    self.clearBigInboxButton.hidden = [[[[YoUser me] yoInbox] getYosWithStatus:YoStatusReceived] count] == 0;
    
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:MakeString(@"banner.tip.show.count.%@", [newContextObject class])];
    if ([[self.contacts allContacts] count] > 0 && (count < 5 || [newContextObject alwaysShowBanner])) {
        [[NSUserDefaults standardUserDefaults] setInteger:(count+1) forKey:MakeString(@"banner.tip.show.count.%@", [newContextObject class])];
        [self.statusBar flashText:[newContextObject textForStatusBar]];
    }
    else {
        [self.statusBar hideLabel];
    }
    
    [self displayPermissionsBannerForCurrentContextIfNeeded];
}

- (void)updateContextButtonLayoutAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= self.yoContextObjects.count) {
        return;
    }
    YoContextView *contextView = [self.contextViews objectAtIndex:index];
    if (contextView.utilityButton) {
        if (self.currentContextIndex == index) {
            if (self.inboxButton.hidden == NO) {
                void (^shiftContextButtonRight)() = ^() {
                    contextView.utilityButton.left = self.inboxButton.right + 20.0f;
                };
                if (animated) {
                    [UIView animateWithDuration:0.2 animations:^{
                        shiftContextButtonRight();
                    }];
                }
                else {
                    shiftContextButtonRight();
                }
            }
            else {
                void (^alignContextButtonToInboxButtonLeft)() = ^() {
                    contextView.utilityButton.left = 20.0f;
                };
                if (animated) {
                    [UIView animateWithDuration:0.2 animations:^{
                        alignContextButtonToInboxButtonLeft();
                    }];
                }
                else {
                    alignContextButtonToInboxButtonLeft();
                }
            }
        }
        else {
            void (^alignContextButtonToInboxButtonLeft)() = ^() {
                contextView.utilityButton.left = 20.0;
            };
            if (animated) {
                [UIView animateWithDuration:0.2 animations:^{
                    alignContextButtonToInboxButtonLeft();
                }];
            }
            else {
                alignContextButtonToInboxButtonLeft();
            }
        }
    }
}

- (void)invalidateContextViews {
    if (self.contextViews.count > 0) {
        [self.contextViews removeAllObjects];
    }
    [self.contextScrollView removeAllSubviews];
    [self setupContextViews];
}

- (void)setupContextViews {
    [self.contextViews removeAllObjects];
    [self.contextTableViews removeAllObjects];
    
    self.statusBar.pageControl.numberOfPages = self.yoContextObjects.count;
    
    if (self.contextViews == nil) {
        self.contextViews = [[NSMutableArray alloc] init];
    }
    
    if (self.contextIDToContextView == nil) {
        self.contextIDToContextView = [[NSMutableDictionary alloc] init];
    }
    
    if (self.contextTableViews == nil) {
        self.contextTableViews = [[NSMutableArray alloc] init];
    }
    
    // @or: layout all the context views, one after another on the scroll view
    [self.contextScrollView removeAllSubviews];
    for (YoContextObject *contextObject in self.yoContextObjects) {
        
        NSString *contextID = [[contextObject class] contextID];
        YoContextView *contextView = [self.contextIDToContextView objectForKey:contextID];
        
        if (contextView == nil) {
            contextView = [[YoContextView alloc] init];
            contextView.translatesAutoresizingMaskIntoConstraints = NO;
            contextView.layer.masksToBounds = YES;
            contextView.layer.cornerRadius = self.view.layer.cornerRadius;
            
            /////// Recents List Table View ///////
            
            contextView.tableView.delegate = self;
            contextView.tableView.dataSource = self;
            
            self.contextIDToContextView[contextID] = contextView;
        }
        
        contextView.context = contextObject;
        
        [self.contextScrollView addSubview:contextView];
        [self.contextTableViews addObject:contextView.tableView];
        [self.contextViews addObject:contextView];
    }
    
    /*UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoStoreStoryboard bundle:nil];
     YoStoreTabBarController *storeController = [mainStoryBoard instantiateInitialViewController];
     
     self.storeController = [[YoNavigationController alloc] initWithRootViewController:storeController];
     [self.contextScrollView addSubview:self.storeController.view];
     [self.contextViews addObject:self.storeController.view];
     
     self.storeController.view.translatesAutoresizingMaskIntoConstraints = NO;
     self.storeController.view.layer.masksToBounds = YES;
     self.storeController.view.layer.cornerRadius = self.view.layer.cornerRadius;
     
     self.storeController.navigationController.navigationBar.topItem.rightBarButtonItem = nil;
     self.storeController.navigationItem.rightBarButtonItem = nil;*/
    
    self.contextScrollView.contentSize = CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]) * self.contextViews.count,
                                                    CGRectGetHeight([[UIScreen mainScreen] bounds]));
    
    [self invalidateContextScrollViewConstraints];
}

- (void)invalidateContextScrollViewConstraints {
    if (self.contextScrollViewConstraints.count) {
        [self.contextScrollViewConstraints removeAllObjects];
    }
    self.contextScrollViewConstraints = nil;
    [self updateContextViewConstraints];
}

- (void)updateContextViewConstraints {
    if (self.contextScrollViewConstraints) {
        return;
    }
    
    self.contextScrollViewConstraints = [[NSMutableArray alloc] init];
    
    NSArray *contextViews = self.contextViews;
    
    for (NSUInteger contextIndex = 0; contextIndex < contextViews.count; contextIndex++) {
        UIView *contextView = [contextViews objectAtIndex:contextIndex];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(contextView);
        
        // relative constrains
        BOOL isFirstContextView = (contextIndex == 0);
        if (isFirstContextView) {
            [self.contextScrollViewConstraints addObjectsFromArray:
             [NSLayoutConstraint
              constraintsWithVisualFormat:@"H:|[contextView]"
              options:0 metrics:nil views:views]];
        }
        else {
            UIView *previousContextView = [contextViews objectAtIndex:(contextIndex - 1)];
            NSDictionary *thisCaseViews = NSDictionaryOfVariableBindings(contextView, previousContextView);
            
            [self.contextScrollViewConstraints addObjectsFromArray:
             [NSLayoutConstraint
              constraintsWithVisualFormat:@"H:[previousContextView][contextView]"
              options:0 metrics:nil views:thisCaseViews]];
        }
        
        NSUInteger lastContextIndex = contextViews.count - 1;
        BOOL isLastContextView = (contextIndex == lastContextIndex);
        if (isLastContextView) {
            [self.contextScrollViewConstraints addObjectsFromArray:
             [NSLayoutConstraint
              constraintsWithVisualFormat:@"H:[contextView]|"
              options:0 metrics:nil views:views]];
        }
        
        // default constrainsts
        [self.contextScrollViewConstraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[contextView]|"
          options:0 metrics:nil views:views]];
        [self.contextScrollViewConstraints addObject:
         [NSLayoutConstraint
          constraintWithItem:contextView attribute:NSLayoutAttributeHeight
          relatedBy:NSLayoutRelationEqual
          toItem:self.contextScrollView attribute:NSLayoutAttributeHeight
          multiplier:1.0f constant:0.0f]];
        
        [self.contextScrollViewConstraints addObject:
         [NSLayoutConstraint
          constraintWithItem:contextView attribute:NSLayoutAttributeWidth
          relatedBy:NSLayoutRelationEqual
          toItem:self.contextScrollView attribute:NSLayoutAttributeWidth
          multiplier:1.0f constant:0.0f]];
    }
    
    [self.contextScrollView addConstraints:self.contextScrollViewConstraints];
}

- (void)removeContext:(YoContextObject *)contextObject
{
    if (contextObject == nil) {
        return;
    }
    
    NSInteger indexOfContext = [self.yoContextObjects indexOfObject:contextObject];
    if (indexOfContext != NSNotFound) {
        [self.yoContextObjects removeObjectAtIndex:indexOfContext];
        if (self.currentContextIndex == indexOfContext) {
            self.currentContextIndex = MAX(indexOfContext-1, 0);
        }
        [self.contextIDToContextView removeObjectForKey:[[contextObject class] contextID]];
        [self setupContextViews];
    }
}

- (void)addContext:(YoContextObject *)context moveToContext:(BOOL)moveToContext animated:(BOOL)animated
{
    [self.yoContextObjects addObject:context];
    [self setupContextViews];
    
    // because this was added manually we need to make sure it gets a chance to configure.
    // preferably before scrolling to it.
    NSString *contextID = [[context class] contextID];
    YoContextView *contextView = self.contextIDToContextView[contextID];
    [contextView setupForContextIfNeeded];
    
    if (moveToContext) {
        NSInteger newContextIndex = self.yoContextObjects.count - 1;
        [self scrollToContextAtIndex:newContextIndex
                            animated:animated];
    }
}

#pragma mark - Context Processing

- (void)reloadContextsIfNeeded {
    [[YoContextConfiguration sharedInstance] load];
    NSArray *contextIDs = [YoContextConfiguration sharedInstance].contextIDs;
    if ([_contextIDs isEqualToArray:contextIDs] == NO) {
        [self reloadContexts];
    }
}

- (void)reloadContexts {
    [[YoContextConfiguration sharedInstance] load];
    self.contextIDs = [YoContextConfiguration sharedInstance].contextIDs;
    self.defaultContextID = [YoContextConfiguration sharedInstance].defaultContextID;
    
    NSArray *contexts = [self getContextsFromContextIDs:_contextIDs];
    contexts = [self filterUnavailableContexts:contexts];
    self.yoContextObjects = [contexts mutableCopy];
    
    [self setupContextViews];
    [self notifiyAllContextViewsToConfigure];
    
    if (self.currentContextIndex >= self.contextViews.count) {
        self.currentContextIndex = self.contextViews.count - 1; // last context view, scroll is automatic
    }
}

- (NSArray *)filterUnavailableContexts:(NSArray *)contexts {
    NSMutableArray *availableContexts = [[NSMutableArray alloc] initWithCapacity:contexts.count];
    
    for (YoContextObject *context in contexts) {
        if ([context canDisplay]) {
            [availableContexts addObject:context];
        }
    }
    
    return availableContexts;
}

- (NSArray *)getContextsIDsArrayFromContexts:(NSArray *)contexts
{
    NSMutableArray *contextIDS = [[NSMutableArray alloc] initWithCapacity:contexts.count];
    for (YoContextObject *context in contexts) {
        [contextIDS addObject:[[context class] contextID]];
    }
    return contextIDS;
}

- (NSMutableArray *)getContextsFromContextIDs:(NSArray *)contextIDs
{
    NSMutableArray *contexts = [[NSMutableArray alloc] initWithCapacity:contextIDs.count];
    for (NSString *contextID in contextIDs) {
        YoContextObject *context = [YoContextFactory newContextOfIdentifier:contextID];
        [contexts addObject:context];
    }
    return contexts;
}

#pragma mark - Last Yo Status

- (void)showLastYoStatuses {
    if (self.isShowingBanner ||
        [self.contacts allContacts].count == 0) {
        return;
    }
    
    NSArray *users = [[self.contacts allContacts] subarrayWithRange:NSMakeRange(0, MIN(10, [self.contacts allContacts].count))];
    if (users.count > 0) {
        [[[YoUser me] contactsManager] fetchStatusesForObjects:users withCompletionHandler:^(NSArray *statuses) {
            self.isShowingStatuses = YES;
            [self reloadVisibleTableViews];
            [self resetDisplayStatusesTimer];
        }];
    }
}

- (void)resetDisplayStatusesTimer {
    [self.displayStatusesTimer invalidate];
    self.displayStatusesTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                 target:self
                                                               selector:@selector(displayStatusTimerExpired)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)displayStatusTimerExpired {
    self.isShowingStatuses = NO;
    [self hideVisibleCellStatuses];
    [self.displayStatusesTimer invalidate];
    self.displayStatusesTimer = nil;
}

- (void)hideVisibleCellStatuses {
    [self reloadVisibleTableViews];
}

#pragma mark - Contacts

- (void)reloadContacts {
    self.contacts = [[YoContacts alloc] initWithData:[[YoUser me] list]];
    if ([self.contacts allContacts].count > 0) {
        self.contactsLoadingState = YoMCLoadingStateContentAvailble;
        
        if (IS_OVER_IOS(9.0)) {
            YoUser *user = [[self.contacts allContacts] objectAtIndex:0];
            NSString *displayName = [user displayName];
            
            UIApplicationShortcutItem *item1 = [[UIApplicationShortcutItem alloc] initWithType:@"yo" localizedTitle:MakeString(@"Yo %@", displayName) localizedSubtitle:nil icon:nil userInfo:@{@"username": user.username, @"type": @"just_yo"}];
            UIApplicationShortcutItem *item2 = [[UIApplicationShortcutItem alloc] initWithType:@"yo" localizedTitle:MakeString(@"Yo 📍 %@", displayName) localizedSubtitle:nil icon:nil userInfo:@{@"username": user.username, @"type": @"location"}];
            [UIApplication sharedApplication].shortcutItems = @[item2, item1];
        }
    }
    else {
        self.contactsLoadingState = YoMCLoadingStateNoContent;
    }
    [self.contextTableViews makeObjectsPerformSelector:@selector(reloadData)];
}

- (void)updateContactsWithCompletionBlock:(void (^)(bool success))block {
    if ([[YoUser me] contactsManager] != nil) {
        
        if (self.contactsLoadingState == YoMCLoadingStateLoading ||
            self.contactsLoadingState == YoMCLoadingStateRefreshing) {
            return;
        }
        
        if (self.contactsLoadingState == YoMCLoadingStateInitial) {
            self.contactsLoadingState = YoMCLoadingStateLoading;
        }
        else {
            self.contactsLoadingState = YoMCLoadingStateRefreshing;
        }
        
        [[[YoUser me] contactsManager] updateContactsWithCompletionBlock:^(bool success) {
            [self reloadContacts];
            
            if (block) {
                block(success);
            }
        }];
    }
}

- (void)setContactsLoadingState:(YoMCLoadingState)contactsLoadingState {
    if (_contactsLoadingState == contactsLoadingState) {
        return;
    }
    
    _contactsLoadingState = contactsLoadingState;
    switch (contactsLoadingState) {
            case YoMCLoadingStateInitial:
            break;
            
            case YoMCLoadingStateLoading:
        {
            self.placeholderView.hidden = YES;
            self.contextScrollView.hidden = YES;
            self.activityIndicator.hidden = NO;
            [self.activityIndicator startAnimating];
        }
            break;
            
            case YoMCLoadingStateRefreshing:
        {
            self.placeholderView.hidden = YES;
            if ([self.contacts allContacts].count == 0) {
                self.contextScrollView.hidden = YES;
                self.activityIndicator.hidden = NO;
                [self.activityIndicator startAnimating];
            }
            else {
                self.contextScrollView.hidden = NO;
            }
        }
            break;
            
            case YoMCLoadingStateContentAvailble:
        {
            [self.activityIndicator stopAnimating];
            self.placeholderView.hidden = YES;
            self.contextScrollView.hidden = NO;
        }
            break;
            
            case YoMCLoadingStateNoContent:
        {
            [self.activityIndicator stopAnimating];
            self.placeholderView.hidden = NO;
            self.contextScrollView.hidden = YES;
        }
            break;
            
            case YoMCLoadingStateError:
            break;
    }
    
}

#pragma mark - Banners

- (void)presentBannerIfNeeded
{
    if (self.isShowingBanner) {
        return;
    }
    
    // context promotion banner
    NSInteger openCount = [[YoApp currentSession] openCountForUser:[YoUser me].username];
    [self.bannerStore getContextBannerForOpenCount:openCount
                                   currentContexts:self.yoContextObjects
                                          location:[YoApp currentSession].lastKnownLocation
                             withCompletionHandler:^(YoContextBanner *banner, NSError *error) {
                                 if (banner != nil) {
                                     BOOL bannerHasAlreadyBeenPresented = [self.alreadyPresentedBanners containsObject:banner];
                                     if (bannerHasAlreadyBeenPresented == NO) {
                                         YoBannerView *bannerView = [[YoBannerView alloc] init];
                                         [bannerView configureForBanner:banner];
                                         bannerView.delegate = self;
                                         [bannerView showInView:self.view];
                                         [self.alreadyPresentedBanners addObject:banner];
                                         self.isShowingBanner = YES;
                                     }
                                 }
                                 else {
                                     [self checkPasteboard];
                                 }
                             }];
}

#pragma mark YoBannerViewDelegate

- (void)bannerView:(YoBannerView *)bannerView didDismissWithResult:(YoBannerViewResult)result
{
    switch (result) {
            case YoBannerViewResultOpened:
        {
            YoContextBanner *banner = (YoContextBanner *)bannerView.banner;
            if (banner.link) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:banner.link]];
                [[YoDataAccessManager sharedDataManager] acknowledgeBannerWithID:banner.ID result:@"opened"];
            }
            else if (banner.contextID != nil) {
                [self scrollToContextWithID:banner.contextID animated:YES];
                [[YoDataAccessManager sharedDataManager] acknowledgeBannerWithID:banner.ID result:@"opened"];
            }
        }
            break;
            
            case YoBannerViewResultDismissed:
        {
            YoContextBanner *banner = (YoContextBanner *)bannerView.banner;
            if (banner.contextID != nil) {
                [[YoDataAccessManager sharedDataManager] acknowledgeBannerWithID:banner.ID result:@"dismissed"];
            }
        }
            break;
            
        default:
            break;
    }
    
    self.isShowingBanner = NO;
}

#pragma mark - Device Sepcific Contexts

// public.jpeg
// public.png
// public.text -> even if URL pastboard does not try and do this for you.
// public.url
// com.compuserve.gif

- (void)checkPasteboard {
    if (self.isShowingBanner || [self.currentContextObject isKindOfClass:[YoClipboardContext class]]) {
        return;
    }
    
    NSInteger lastChangeCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"paste.board.change.count"];
    if (lastChangeCount != [UIPasteboard generalPasteboard].changeCount) {
        [[NSUserDefaults standardUserDefaults] setInteger:[UIPasteboard generalPasteboard].changeCount forKey:@"paste.board.change.count"];
        
        id currentPastboardItem = [self getPastBoardItem];
        
        YoClipboardContext *clipBoardContext = (YoClipboardContext *)[self getContextOfClass:[YoClipboardContext class]];
        
        BOOL pastboardItemsAreEqual = NO;
        
        if ([currentPastboardItem isKindOfClass:[UIImage class]] &&
            [clipBoardContext.item isKindOfClass:[UIImage class]]) {
            pastboardItemsAreEqual = [currentPastboardItem isEqualToImage:clipBoardContext.item];
        }
        else {
            pastboardItemsAreEqual = [clipBoardContext.item isEqual:currentPastboardItem];
        }
        if (pastboardItemsAreEqual == NO) {
            [self removeContext:clipBoardContext];
            
            if ([YoClipboardContext canPresentItem:currentPastboardItem]) {
                __weak YoMainController *weakSelf = self;
                YoNotification *note = [[YoNotification alloc] initWithMessage:@"Tap here to Yo what you have copied." tapBlock:^{
                    YoClipboardContext *clipBoardContext = [[YoClipboardContext alloc] initWithClipboardItem:currentPastboardItem];
                    [weakSelf addContext:clipBoardContext
                           moveToContext:YES
                                animated:YES];
                }];
                
                [self.bannerManager showNotification:note];
            }
        }
    }
}

- (void)checkLastPhoto {
    if (self.isShowingBanner || [self.currentContextObject isKindOfClass:[YoLastPhotoContext class]]) {
        return;
    }
    [self.lastPhotoContext hasNewPhoto:^(BOOL hasNewPhoto) {
        if (hasNewPhoto) {
            __weak YoMainController *weakSelf = self;
            YoNotification *note = [[YoNotification alloc] initWithMessage:@"Tap here to Yo your latest photo." tapBlock:^{
                [weakSelf addContext:self.lastPhotoContext
                       moveToContext:YES
                            animated:YES];
                self.isShowingBanner = NO;
            }];
            [self.bannerManager showNotification:note];
            self.isShowingBanner = YES;
        }
    }];
    
}

- (id)getPastBoardItem
{
    UIImage *image = [UIPasteboard generalPasteboard].image;
    if (image != nil) {
        return image;
    }
    
    NSString *string = [UIPasteboard generalPasteboard].string;
    if (string != nil) {
        return string;
    }
    
    NSURL *URL = [UIPasteboard generalPasteboard].URL;
    if (URL != nil) {
        return URL;
    }
    
    return nil;
}

#pragma mark - Application

- (void)fetchedEasterEgg {
    YoEasterEggContext *easterEggContext = (YoEasterEggContext *)[self getContextOfClass:[YoEasterEggContext class]];
    if (easterEggContext == nil) {
        [self addContext:self.easterEggContext
           moveToContext:self.moveToEasterEggWhenLoaded
                animated:YES];
        
        self.moveToEasterEggWhenLoaded = NO;
    }
}

- (YoContextObject *)getContextOfClass:(Class)class
{
    YoContextObject *contextOfClass = nil;
    for (YoContextObject *context in self.yoContextObjects) {
        if ([context isKindOfClass:class]) {
            contextOfClass = context;
            break;
        }
    }
    return contextOfClass;
}

#pragma mark - Context Permission Banner

- (void)displayPermissionsBannerForCurrentContextIfNeeded {
    [self reloadCurrentContextTableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NS_DURING
    if (self.currentContextIndex >= self.yoContextObjects.count) {
        return 0.0;
    }
    YoContextObject *context = self.yoContextObjects[self.currentContextIndex];
    if (section == 0 &&
        [context shouldShowPermissionsBanner]) {
        return [context permissionsBanner].height;
    }
    else {
        return 0.0f;
    }
    NS_HANDLER
    return 0.0;
    NS_ENDHANDLER
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.currentContextIndex >= self.yoContextObjects.count) {
        return nil;
    }
    YoContextObject *context = self.yoContextObjects[self.currentContextIndex];
    if (section == 0 &&
        [context shouldShowPermissionsBanner]) {
        return [context permissionsBanner];
    }
    else {
        return nil;
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger recentsCount = [[self.contacts allContacts] count];
    return recentsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YoUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YoUserTableViewCell class])];
    if (cell == nil) {
        cell = [[YoUserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([YoUserTableViewCell class])];
        cell.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer  *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCellWithTapGR:)];
        [cell addGestureRecognizer:tapGR];
        
        UILongPressGestureRecognizer *longGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapCellWithTapGR:)];
        longGr.minimumPressDuration = 0.5;
        [cell addGestureRecognizer:longGr];
    }
    
    YoModelObject *user = [self.contacts allContacts][indexPath.row];
    [cell congifureForUser:user];
    
    [self reloadConfigurationForUser:user onCell:cell];
    
    NSInteger index = [self.contextTableViews indexOfObject:tableView];
    YoContextObject *contextObject = [self.yoContextObjects objectAtIndex:index];
    
    if ([contextObject isLabelGlowing]) {
        cell.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
        cell.nameLabel.glowColor = [UIColor blackColor];
        cell.nameLabel.glowAmount = 2.0;
        cell.nameLabel.glowOffset = CGSizeMake(0.0, 0.0);
    }
    else if ([contextObject isTableViewTransparent]) {
        cell.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
    }
    else {
        cell.backgroundView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    }
    
    if (self.isShowingStatuses) {
        [cell showLastYoStatus];
    }
    else {
        [cell hideLastYoStatus];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - User Cell Display Configuration

- (NSMutableDictionary *)newUserConfigurationDictionary {
    NSMutableDictionary *configurationDictionary = [[NSMutableDictionary alloc] init];
    configurationDictionary[YoConfigurationShowsLoaderKey] = @(NO);
    configurationDictionary[YoConfigurationShowsPlaceholderKey] = @(NO);
    configurationDictionary[YoConfigurationUserInteractionDisabledKey] = @(NO);
    configurationDictionary[YoConfigurationFakedLastYoSucessKey] = @(NO);
    return configurationDictionary;
}

- (NSMutableDictionary *)configurationDictionaryForUser:(YoModelObject *)user {
    NSMutableDictionary *configuration = [self.usernameToCellConfiguration objectForKey:user.username];
    if (configuration == nil) {
        configuration = [self newUserConfigurationDictionary];
        self.usernameToCellConfiguration[user.username] = configuration;
    }
    return configuration;
}

- (void)updateConfigurationKey:(NSString *)key withObject:(id)object forUser:(YoModelObject *)user {
    NS_DURING
    NSMutableDictionary *configuration = [self configurationDictionaryForUser:user];
    configuration[key] = object;
    DDLogDebug(@"%@ - %@ - %@", key, object, user.username);
    NS_HANDLER
    DDLogError(@"%@", localException);
    NS_ENDHANDLER
}

- (void)reloadConfigurationForUser:(YoModelObject *)user onCell:(YoUserTableViewCell *)cell {
    NSDictionary *cellConfiguration = [self configurationDictionaryForUser:user];
    [cellConfiguration enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        // loading
        // placeholder text
        // progress indicator ?
        if ([key isEqualToString:YoConfigurationShowsLoaderKey]) {
            BOOL cellShouldBeLoading = [obj boolValue];
            if (cellShouldBeLoading &&
                [cell isAnimatingActivityIndicator] == NO) {
                [cell startAnimatingActivityIndicator];
            }
            else if ([cell isAnimatingActivityIndicator]) {
                [cell stopAnimatingActivityIndicator];
            }
        }
        else if ([key isEqualToString:YoConfigurationShowsPlaceholderKey]) {
            BOOL cellShouldShowPlaceholder = [obj boolValue];
            if (cellShouldShowPlaceholder) {
                NSString *placeholderText = [cellConfiguration objectForKey:YoConfigurationPlaceholderTextKey];
                [cell showPlaceHolderWithText:placeholderText];
            }
            else if ([cell isShowingPlaceholder]) {
                [cell hidePlaceHolder];
            }
        }
        else if ([key isEqualToString:YoConfigurationUserInteractionDisabledKey]) {
            BOOL cellShouldBeDisabled = [obj boolValue];
            cell.userInteractionEnabled = !cellShouldBeDisabled;
        }
        
    }];
}

#pragma mark -

- (void)onScrollViewAnimationCompletionPerformBlock:(void (^)())block {
    if (self.contextScrollViewAnimationCompletionBlock == nil) {
        self.contextScrollViewAnimationCompletionBlock = block;
    }
    else {
        void (^currentBlock)() = self.contextScrollViewAnimationCompletionBlock;
        self.contextScrollViewAnimationCompletionBlock = ^() {
            currentBlock();
            block();
        };
    }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.displayStatusesTimer invalidate];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NS_DURING
    if (self.currentContextIndex >= self.contextTableViews.count) {
        return;
    }
    if ([scrollView isEqual:[self.contextTableViews objectAtIndex:self.currentContextIndex]]) {
        CGFloat maxOffset = 80.0;
        if (scrollView.contentOffset.y < -maxOffset) {
            [self presentMenuConroller];
        }
        else if (scrollView.contentOffset.y <= 0) {
            self.headerView.alpha = (maxOffset-fabs(scrollView.contentOffset.y))/maxOffset;
            self.arrowUpIcon.alpha = 1.0 - self.headerView.alpha;
        }
    }
    
    if ([self.contextTableViews containsObject:scrollView]) {
        CGPoint offset = scrollView.contentOffset;
        if (offset.y >= 0.0f) {
            for (UITableView *tableView in self.contextTableViews) {
                if (![tableView isEqual:scrollView]) {
                    [tableView setContentOffset:offset];
                }
            }
        }
    }
    
    if ([self.contextScrollView isEqual:scrollView]) {
        [self reloadTableViewsOnScreen];
    }
    
    NS_HANDLER
    NS_ENDHANDLER
}

- (void)reloadTableViewsOnScreen {
    if (self.contextLocked) {
        return;
    }
    
    if ([self.currentContextObject conformsToProtocol:@protocol(YoContextRecording)] &&
        [(id <YoContextRecording>)self.currentContextObject isRecording]) {
        return;
    }
    
    CGRect visibleRect = self.contextScrollView.bounds;
    for (NSInteger index = 0; index < self.contextViews.count; index++) {
        UIView *contextView = [self.contextViews objectAtIndex:index];
        if (CGRectIntersectsRect(visibleRect, contextView.frame)) {
            if (index < self.contextTableViews.count) {
                UITableView *contextTableView = [self.contextTableViews objectAtIndex:index];
                if ([self.reloadedTableViewsDuringScroll containsObject:contextTableView]) {
                    continue;
                }
                [self.reloadedTableViewsDuringScroll addObject:contextTableView];
                [contextTableView reloadData];
            }
        }
    }
}

- (void)reloadVisibleTableViews {
    if (self.contextLocked) {
        return;
    }
    
    if ([self.currentContextObject conformsToProtocol:@protocol(YoContextRecording)] &&
        [(id <YoContextRecording>)self.currentContextObject isRecording]) {
        return;
    }
    
    CGRect visibleRect = self.contextScrollView.bounds;
    for (NSInteger index = 0; index < self.contextViews.count; index++) {
        YoContextView *contextView = [self.contextViews objectAtIndex:index];
        if ([contextView respondsToSelector:@selector(tableView)]) {
            if (CGRectIntersectsRect(visibleRect, contextView.frame)) {
                [contextView.tableView reloadData];
            }
        }
    }
}

/**
 Call this instead of reloading tablviews directly.
 **/
- (void)reloadCurrentContextTableView {
    if (self.contextLocked) {
        return;
    }
    UITableView *tableView = [self currentContextTableView];
    [tableView reloadData];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if ([scrollView isEqual:self.contextScrollView]) {
        int page = scrollView.contentOffset.x / scrollView.width;
        self.currentContextIndex = page;
        
        if (self.currentContextIndex >= self.yoContextObjects.count) {
            return;
        }
        
        YoContextObject *fromContext = [self.yoContextObjects objectAtIndex:self.currentContextIndex];
        YoContextObject *toContext = [self.yoContextObjects objectAtIndex:self.currentContextIndex];
        
        [YoAnalytics logEvent:@"ChangedContextThroughSwipe" withParameters:@{@"from_context":[[fromContext class] contextID]?:@"NULL",
                                                                             @"to_context":[[toContext class] contextID]?:@"NULL"}];
        
        [self.reloadedTableViewsDuringScroll removeAllObjects];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.contextScrollView]) {
        int page = MAX(0, scrollView.contentOffset.x / scrollView.width);
        self.currentContextIndex = page;
        if (self.contextScrollViewAnimationCompletionBlock) {
            self.contextScrollViewAnimationCompletionBlock();
            self.contextScrollViewAnimationCompletionBlock = nil;
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.contextTableViews containsObject:scrollView]) {
        for (UITableView *contextTableView in self.contextTableViews) {
            [contextTableView setContentOffset:scrollView.contentOffset];
        }
    }
    if (self.isShowingStatuses) {
        [self resetDisplayStatusesTimer];
    }
}

#pragma mark - Context Locking

- (void)setContextLocked:(BOOL)contextLocked {
    [self setContextLocked:contextLocked excludingCell:nil];
}

- (void)setContextLocked:(BOOL)contextLocked excludingCell:(YoUserTableViewCell *)cell {
    _contextLocked = contextLocked;
    
    self.statusBar.hidden = contextLocked;
    cell.userInteractionEnabled = !contextLocked;
    
    UITableView *tableView = [self currentContextTableView];
    
    [[tableView visibleCells] enumerateObjectsUsingBlock:^(YoUserTableViewCell *obj, NSUInteger idx, BOOL *stop) {
        if ([cell isEqual:obj] == NO) {
            if (contextLocked) {
                [obj showPlaceHolderWithText:nil];
            }
            else {
                [obj hidePlaceHolder];
            }
        }
    }];
    
    tableView.scrollEnabled = !contextLocked;
    tableView.userInteractionEnabled = !contextLocked;
    self.contextScrollView.scrollEnabled = !contextLocked;
    
    
    if ([[[[YoUser me] yoInbox] getYosWithStatus:YoStatusReceived] count] > 0) {
        self.inboxButton.hidden = contextLocked;
    }
    
    YoContextView *currentContextView = [self.contextViews objectAtIndex:self.currentContextIndex];
    currentContextView.utilityButton.hidden = contextLocked;
    self.menuButton.hidden = contextLocked;
    self.plusButtonContainer.hidden = contextLocked;
    
    if (contextLocked == NO) {
        [self reloadCurrentContextTableView]; // to make sure everything is as it should be
    }
}

- (void)showRecordingOptionsWithStyle:(YoRecordingViewStyle)style animated:(BOOL)animated {
    if (_recordingOptions == nil) {
        [self addRecordingOptionView];
    }
    
    self.recordingOptions.style = style;
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.4
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^
     {
         self.recordingOptions.bottom = CGRectGetMaxY(self.view.frame) - 60.0f;
     } completion:nil];
}

- (void)hideRecordingOptionsAnimated:(BOOL)animated {
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.4
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^
     {
         self.recordingOptions.top = CGRectGetMaxY(self.view.frame) + 20.0f;
     } completion:nil];
}

- (void)addRecordingOptionView {
    YoRecordingView *recordingOptions = [[YoRecordingView alloc] init];
    recordingOptions.layer.cornerRadius = 7.0f;
    recordingOptions.layer.masksToBounds = YES;
    
    
    [recordingOptions.sendButton addTarget:self
                                    action:@selector(didTapSendRecordingOption:)
                          forControlEvents:UIControlEventTouchUpInside];
    
    [recordingOptions.cancelButton addTarget:self
                                      action:@selector(didTapCancelRecordingOption:)
                            forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat buttonHeight = 70.0f;
    CGFloat buttonHeightToWidthRatio = 2.0f;
    CGFloat buttonWidth = buttonHeight * buttonHeightToWidthRatio;
    
    recordingOptions.frame = CGRectMake(0.0f,
                                        0.0f,
                                        2 * buttonWidth,
                                        buttonHeight);
    
    recordingOptions.left = CGRectGetMidX(self.view.frame) - recordingOptions.width/2.0f;
    recordingOptions.top = CGRectGetMaxY(self.view.frame) + 20.0f;
    
    [self.view addSubview:recordingOptions];
    
    self.recordingOptions = recordingOptions;
}

#pragma mark - Handle Taps

- (void)didLongTapCellWithTapGR:(UILongPressGestureRecognizer *)longGr {
    YoUserTableViewCell *cell = (YoUserTableViewCell *)longGr.view;
    
    if (longGr.state == UIGestureRecognizerStateBegan) {
        if ([self.currentContextObject supportsLongPress]) {
            [self handleTapForCell:cell isLongTap:YES];
        }
        else if ([cell.user isKindOfClass:[YoUser class]]) {
            [self presentProfileViewControllerForUser:(YoUser *)cell.user];
        }
        else if ([cell.user isKindOfClass:[YoGroup class]]) {
            [self presentControllerForGroup:(YoGroup *)cell.user];
        }
    }
}

- (void)statusBarTapped {
    NSIndexPath *firstIndexPath = nil;
    UITableView *tableView = [self currentContextTableView];
    for (int sectionIndex = 0; sectionIndex < [tableView numberOfSections]; sectionIndex++) {
        if ([tableView numberOfRowsInSection:sectionIndex]) {
            firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
            break;
        }
    }
    if (firstIndexPath) {
        for (UITableView *tableView in self.contextTableViews) {
            [tableView scrollToRowAtIndexPath:firstIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)didTapCellWithTapGR:(UITapGestureRecognizer *)tapGR {
    [self didTapCell:(YoUserTableViewCell *)tapGR.view];
}

- (void)didTapCell:(YoUserTableViewCell *)cell {
    [self handleTapForCell:cell];
}

- (void)handleTapForCell:(YoUserTableViewCell *)cell {
    [self handleTapForCell:cell isLongTap:NO];
}

- (void)handleTapForCell:(YoUserTableViewCell *)cell isLongTap:(BOOL)isLongTap {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did.tap.on.username.in.main.screen"];
    
    if ([self showNoInternetIfNeededOnCell:cell]) {
        return;
    }
    
    YoModelObject *user = cell.user; // put the modelObj * on the stack
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([user.username rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Send as Text"
                                               desciption:[NSString stringWithFormat:@"%@ is not on Yo. do you want to send as a text?", user.displayName]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Nah", nil)
                                     tapBlock:^{
                                         
                                     }]];
        [yoAlert addAction:
         [[YoAlertAction alloc] initWithTitle:@"Yes"
                                     tapBlock:^{
                                         NSString *text = MakeString(@"Yo from %@.\n\nget the Yo app it's cool", [YoUser me].displayName);
                                         NSString *number = MakeString(@"%@", user.username);
                                         [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:@[number]
                                                                                                        text:text
                                                                                                 resultBlock:^(MessageComposeResult result) {
                                                                                                 }];
                                     }]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
        return;
    }
    
    if ([user isKindOfClass:[YoUser class]]) {
        [self.createGroupSuggestor didYoUser:(YoUser *)user];
    }
    
    YoContextObject *context = self.currentContextObject;
    
    if ([context conformsToProtocol:@protocol(YoContextRecording)] &&
        ([(YoContextObject <YoContextRecording> *)context recordsOnTap] ||
         (isLongTap && [(YoContextObject <YoContextRecording> *)context recordsOnLongTap]))) {
            
            self.recordingCell = cell;
            [self startRecordingContext:(YoContextObject <YoContextRecording> *)context
                                forCell:cell
                              isLongTap:isLongTap];
            
        }
    else {
        [self setLoaderSpinning:YES onCellForUser:user];
        
        [self fakeYoSuccussResultForUser:user
                                   after:2.0
                               inContext:context];
        
        [self sendYoWithContext:context toUser:user isLongTap:isLongTap];
    }
}

- (void)startRecordingContext:(YoContextObject <YoContextRecording> *)context
                      forCell:(YoUserTableViewCell *)cell isLongTap:(BOOL)isLongTap {
    /////////////// @or: Throw away code! ///////////////
    
    [context checkPermissionsIsLongTap:isLongTap completionHandler:^(BOOL granted, NSString *errorMessage) {
        if (granted) {
            [self setContextLocked:YES excludingCell:cell];
            
            YoRecordingViewStyle recordingViewStyle = [context recordingStyleIsLongTap:isLongTap];
            [self showRecordingOptionsWithStyle:recordingViewStyle animated:YES];
            
            NSTimeInterval recordingTime = [context getRecordingTimeIsLongTap:isLongTap];
            
            NSString *recordingMessage = [context getTextToDisplayWhileRecordingIsLongTap:isLongTap];
            
            if (recordingMessage) {
                [cell showPlaceHolderWithText:recordingMessage];
            }
            
            [cell indicateProgressWithDuration:recordingTime];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(recordingTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [cell hidePlaceHolder];
                [self setContextLocked:NO excludingCell:cell];
                [self hideRecordingOptionsAnimated:YES];
            });
            
            [self fakeYoSuccussResultForUser:cell.user
                                       after:recordingTime
                                   inContext:context];
            
            [self sendYoWithContext:context toUser:cell.user isLongTap:isLongTap];
            
        }
        else {
            [[YoAlertManager sharedInstance] showAlertWithTitle:errorMessage];
        }
    }];
    
    /////////////// @or: End of Throw away code ///////////////
}

- (IBAction)didTapCancelRecordingOption:(UIButton *)sender {
    [self stopRecordingAndCancelYo:YES];
    [self hideRecordingOptionsAnimated:YES];
}

- (IBAction)didTapSendRecordingOption:(UIButton *)sender {
    [self stopRecordingAndCancelYo:NO];
    [self hideRecordingOptionsAnimated:YES];
}

- (void)stopRecordingAndCancelYo:(BOOL)cancelYo {
    if ([self.currentContextObject conformsToProtocol:@protocol(YoContextRecording)]) {
        YoContextObject <YoContextRecording> *context = (YoContextObject <YoContextRecording> *)self.currentContextObject;
        
        [self.recordingCell stopIndicatingProgress];
        
        if (cancelYo) {
            self.canceFakinglLastYo = YES;
            [self.recordingCell showPlaceHolderWithText:@"Cancelled"];
        }
        if (cancelYo == NO) {
            [self.recordingCell showPlaceHolderWithText:@"Sending..."];
        }
        
        [context stopRecordingAndCancelYo:cancelYo];
    }
}

#pragma mark - YoCreateGroupSuggestorDelegate

- (void)suggestor:(YoCreateGroupSuggestor *)suggestor suggestsUserCreateGroupWithUsers:(NSSet *)users {
    if (self.isShowingBanner) {
        return;
    }
    
    NSArray *usersArray = [users allObjects];
    
    BOOL userAlreadyCreatedAGroup = NO;
    for (YoModelObject *contact in [self.contacts allContacts]) {
        if ([contact isKindOfClass:[YoGroup class]]) {
            userAlreadyCreatedAGroup = YES;
            break;
        }
    }
    
    if (userAlreadyCreatedAGroup) {
        self.createGroupSuggestor = nil;
        return;
    }
    
    NSString *firstUserDisplayName = [(YoUser *)[usersArray objectAtIndex:0] displayName];
    NSString *secondUserDisplayName = [(YoUser *)[usersArray objectAtIndex:1] displayName];
    
    NSString *createGroupMessage;
    if (usersArray.count == 2) {
        createGroupMessage = MakeString(@"Create Group with %@ & %@?", firstUserDisplayName, secondUserDisplayName);
    }
    else {
        NSUInteger remainingUser = (usersArray.count - 2);
        createGroupMessage = MakeString(@"Create Group with %@, %@ and %lu other%@?", firstUserDisplayName, secondUserDisplayName, (unsigned long)remainingUser, remainingUser==1?@"":@"s");
    }
    
    YoNotification *createGroupNotice = [[YoNotification alloc] initWithMessage:createGroupMessage tapBlock:^{
        // need to show a popup to get the group name
        
        YoCreateGroupPopupViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:YoCreateGroupPopupViewControllerID];
        vc.modalPresentationStyle = UIModalPresentationCustom;
        vc.transitioningDelegate = self;
        vc.groupMembers = usersArray;
        [self showBlurredBackgroundWithViewController:vc];
    }];
    
    [self.bannerManager showNotification:createGroupNotice];
}

#pragma mark - Send Yo

- (void)sendYoWithContext:(YoContextObject *)context toUser:(YoModelObject *)user isLongTap:(BOOL)isLongTap {
    
    START_BACKGROUND_TASK
    
    [context prepareContextParametersLongTap:isLongTap withCompletionBlock:^(NSDictionary *contextParameters, BOOL cancelled) {
        
        if (cancelled) {
            END_BACKGROUND_TASK
            return;
        }
        
        if (contextParameters == nil) {
            self.canceFakinglLastYo = YES;
            
            [self setLoaderSpinning:NO onCellForUser:user];
            
            [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed 😔"];
            END_BACKGROUND_TASK
            return;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:contextParameters];
        params[@"context_identifier"] = [[self.currentContextObject class] contextID];
        
        [[YoManager sharedInstance] yo:user
                 withContextParameters:params
                     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
         {
             END_BACKGROUND_TASK
             
             if (responseObject[@"not_on_yo"]) {
                 
                 YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Send as Text"
                                                        desciption:[NSString stringWithFormat:@"Some of the people in the group are not on Yo. Send Yo as text?"]];
                 [yoAlert addAction:
                  [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Nah", nil)
                                              tapBlock:^{
                                                  
                                              }]];
                 [yoAlert addAction:
                  [[YoAlertAction alloc] initWithTitle:@"Yes"
                                              tapBlock:^{
                                                  NSString *text = MakeString(@"Yo from %@.\n\nget the Yo app it's cool", [YoUser me].displayName);
                                                  [[YoiOSAssistant sharedInstance] presentSMSControllerWithRecipients:responseObject[@"not_on_yo"]
                                                                                                                 text:text
                                                                                                          resultBlock:^(MessageComposeResult result) {
                                                                                                          }];
                                              }]];
                 [[YoAlertManager sharedInstance] showAlert:yoAlert];
                 
             }
             [self showYoResult:result
                     statusCode:statusCode
                        forUser:user
                      inContext:context];
         }];
    }];
}

- (void)fakeYoSuccussResultForUser:(YoModelObject *)user
                             after:(NSTimeInterval)duration
                         inContext:(YoContextObject *)context {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.canceFakinglLastYo) {
            self.canceFakinglLastYo = NO;
            return;
        }
        
        [self updateConfigurationKey:YoConfigurationFakedLastYoSucessKey
                          withObject:@(NO)
                             forUser:user];
        
        [self showYoResult:YoResultSuccess
                statusCode:200
                   forUser:user
                 inContext:context];
        
        [self updateConfigurationKey:YoConfigurationFakedLastYoSucessKey
                          withObject:@(YES)
                             forUser:user];
    });
}

- (void)showYoResult:(YoResult)result
          statusCode:(NSInteger)statusCode
             forUser:(YoModelObject *)user
           inContext:(YoContextObject *)context {
    
    BOOL alreadyFakedSuccess = [self.usernameToCellConfiguration[user.username][YoConfigurationFakedLastYoSucessKey] boolValue];
    
    if (alreadyFakedSuccess) {
        [self updateConfigurationKey:YoConfigurationFakedLastYoSucessKey
                          withObject:@(NO)
                             forUser:user];
        
        [self reloadCurrentContextTableView];
        
        return;
    }
    
    // @or: end background task once sending done or failed
    if (result == YoResultSuccess) {
        
        NSString *successText = [context textForSentYo];
        
        [self showMessage:successText forDuration:1.5 onCellForUser:user completionBlock:^{
            [self promoteContactToTop:user];
            
            NSTimeInterval timeNeededToPromotingCell = 0.25;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeNeededToPromotingCell * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self reloadVisibleTableViews];
                [self showFirstYoTipIfNeededForContext:context];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([user isKindOfClass:[YoUser class]]) {
                    [YoTipController showTipIfNeeded:@"TAP AND HOLD to see a profile"];
                }
                else if ([user isKindOfClass:[YoGroup class]]) {
                    [YoTipController showTipIfNeeded:@"TAP AND HOLD to edit or mute a group"];
                }
            });
        }];
    }
    else {
        if (statusCode == 404) {
            [self showMessage:@"No such user 😏" forDuration:1.5 onCellForUser:user];
        }
        else {
            [self showMessage:@"Failed Yo 😔" forDuration:1.5 onCellForUser:user];
        }
    }
}

/*
 Returns BOOL of whether message was shown.
 */
- (BOOL)showNoInternetIfNeededOnCell:(YoUserTableViewCell *)cell {
    if ( ! [APPDELEGATE hasInternet]) {
        [self showMessage:NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", nil).lowercaseString.capitalizedString
              forDuration:1.5
            onCellForUser:cell.user];
        return YES;
    }
    return NO;
}

/**
 Updates user display configuration to run a loading indicator. If a user's display
 is set to show a plcaholder it will be removed.
 **/
- (void)setLoaderSpinning:(BOOL)isSpinning onCellForUser:(YoModelObject *)user {
    [self updateConfigurationKey:YoConfigurationUserInteractionDisabledKey
                      withObject:@(isSpinning)
                         forUser:user];
    
    [self updateConfigurationKey:YoConfigurationShowsLoaderKey
                      withObject:@(isSpinning)
                         forUser:user];
    
    // dont show place holder while loading
    [self updateConfigurationKey:YoConfigurationShowsPlaceholderKey
                      withObject:@(NO)
                         forUser:user];
    
    [self reloadCurrentContextTableView];
}

- (void)showMessage:(NSString *)message onCellForUser:(YoModelObject *)user {
    [self showMessage:message forDuration:INFINITY onCellForUser:user];
}

- (void)showMessage:(NSString *)message forDuration:(NSTimeInterval)duration onCellForUser:(YoModelObject *)user {
    [self showMessage:message forDuration:duration onCellForUser:user completionBlock:nil];
}

/**
 Updates user display configuration to include a placeholder message. Stops the users loading
 indicator if running. message cannot be nil. block will be executed if issue is encountered.
 **/
- (void)showMessage:(NSString *)message forDuration:(NSTimeInterval)duration onCellForUser:(YoModelObject *)user completionBlock:(void (^)())block {
    if (message == nil) {
        if (block) {
            block();
        }
        return;
    }
    
    [self updateConfigurationKey:YoConfigurationShowsPlaceholderKey
                      withObject:@(YES)
                         forUser:user];
    
    [self updateConfigurationKey:YoConfigurationPlaceholderTextKey
                      withObject:message
                         forUser:user];
    
    [self updateConfigurationKey:YoConfigurationUserInteractionDisabledKey
                      withObject:@(YES)
                         forUser:user];
    
    // dont show loader while showing place holder
    [self updateConfigurationKey:YoConfigurationShowsLoaderKey
                      withObject:@(NO)
                         forUser:user];
    
    [self reloadCurrentContextTableView];
    
    if (duration != INFINITY) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateConfigurationKey:YoConfigurationShowsPlaceholderKey
                              withObject:@(NO)
                                 forUser:user];
            
            [self updateConfigurationKey:YoConfigurationUserInteractionDisabledKey
                              withObject:@(NO)
                                 forUser:user];
            
            [self reloadCurrentContextTableView];
            
            if (block) {
                block();
            }
        });
    }
    else if (block) {
        block();
    }
}

- (void)showFirstYoTipIfNeededForContext:(YoContextObject *)context {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        BOOL hasShownFirstYoTip = [[NSUserDefaults standardUserDefaults] boolForKey:@"did.tap.on.username.in.main.screen"];
        if (hasShownFirstYoTip == NO) {
            [self displayFirstTimeYoMessageForContext:context];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did.tap.on.username.in.main.screen"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)displayFirstTimeYoMessageForContext:(YoContextObject *)context
{
    NSMutableArray *alertActions = [NSMutableArray new];
    NSString *description = MakeString(@"😜\n\nThey'll get a message that says '%@ from %@' along with a sound that says 'Yo'.", [context getFirstTimeYoText], [YoUser me].displayName);
    if (![APPDELEGATE isRegisteredForPushNotifications]) {
        description = MakeString(@"%@\n\n%@", description, NSLocalizedString(@"Get a Yo back by enabling push notifications.", nil));
        [alertActions addObject:[[YoAlertAction alloc] initWithTitle:@"Enable Notifications".capitalizedString tapBlock:^{
            [[YoPushNotificationPermissionRequestor sharedInstance] makeRequestWithCompletionBlock:nil];
        }]];
    }
    else {
        [alertActions addObject:[[YoAlertAction alloc] initWithTitle:@"awesome".capitalizedString tapBlock:nil]];
    }
    NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:description
                                                                                              attributes:[YoAlertManager sharedInstance].defaultDescriptionTextAttributes];
    NSDictionary *boldAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Bold" size:20]};
    NSDictionary *bigEmojiAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:24]};
    [attributedDescription addAttributes:boldAttributes
                                   range:[attributedDescription.string
                                          rangeOfString:@"\"Yo\""]];
    [attributedDescription addAttributes:bigEmojiAttributes
                                   range:[attributedDescription.string
                                          rangeOfString:@"😜"]];
    
    YoAlert *alert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"first yo sent!", nil).capitalizedString
                                              image:[UIImage imageNamed:@"yo_icon_framed"]
                               attributedDesciption:attributedDescription];
    for (YoAlertAction *action in alertActions) {
        [alert addAction:action];
    }
    [[YoAlertManager sharedInstance] showAlert:alert];
}

- (void)promoteContactToTop:(YoModelObject *)object {
    if (!object) return;
    NS_DURING
    NSInteger row = [[self.contacts allContacts] indexOfObject:object];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    if (row == 0) {
        UITableView *tableView = [self currentContextTableView];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return; // @or: already on top
    }
    
    if (indexPath) {
        NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
        [[[YoUser me] contactsManager] promoteObjectToTop:object];
        
        NSMutableArray *allContacts = [[self.contacts allContacts] mutableCopy];
        [allContacts removeObject:object];
        [allContacts insertObject:object atIndex:0];
        self.contacts = [[YoContacts alloc] initWithData:allContacts];
        
        UITableView *tableView = [self currentContextTableView];
        [tableView moveRowAtIndexPath:indexPath toIndexPath:firstIndexPath];
    }
    NS_HANDLER
    NS_ENDHANDLER
}

#pragma mark - Notifications

- (void)appDidEnterForgroundWithNotification:(NSNotification *)note {
    [self reloadContextsIfNeeded];
}

- (void)appDidBecomeActive {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if ([[YoApp currentSession] isLoggedIn]) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //   [self.easterEggContext fetchEasterEgg];
                
                if ([self.contacts allContacts].count > 0) {
                    [self presentBannerIfNeeded];
                }
            });
            
            [self.currentContextObject contextDidAppear];
            [YoAnalytics logEvent:@"OpenedToContext" withParameters:@{@"context":[[self.currentContextObject class] contextID]?:@"NULL"}];
            
            [self fetchUnreadYos];
            
            if ([self.contacts allContacts].count > 0) {
                [self showLastYoStatuses];
            }
            
            [self displayPermissionsBannerForCurrentContextIfNeeded];
            [self checkLastPhoto];
        }
    });
}

- (void)notifiyAllContextViewsToConfigure {
    for (YoContextView *contextView in self.contextViews) {
        if ([contextView respondsToSelector:@selector(setupForContextIfNeeded)]) {
            [contextView setupForContextIfNeeded];
        }
    }
}

- (void)easterEggFailed {
    if ([self.yoContextObjects containsObject:self.easterEggContext]) {
        [self removeContext:self.easterEggContext];
    }
}

- (void)userDidLoginNotification:(NSNotification *)notification {
    [self updateContactsWithCompletionBlock:^(bool success) {
        if ([self.contacts allContacts].count > 0) {
            [self showLastYoStatuses];
            [self presentBannerIfNeeded];
        }
    }];
    [self fetchUnreadYos];
    [self.yoContextObjects makeObjectsPerformSelector:@selector(fetchDataIfNeeded)];
}

- (void)userDidSigupNotification:(NSNotification *)notification {
    [self reloadVisibleTableViews];
    
    self.contactsLoadingState = YoMCLoadingStateNoContent;
    
    [self.yoContextObjects makeObjectsPerformSelector:@selector(fetchDataIfNeeded)];
    
    // call update context configuration so we can allow
    // server to pick configuration for new users
    /*[[YoContextConfiguration sharedInstance] updateWithCompletionHandler:^(BOOL didUpdate) {
     if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
     if (didUpdate) {
     [self reloadContextsIfNeeded];
     [self notifiyAllContextViewsToConfigure];
     }
     }
     }];*/
}

- (void)userSessionRestoredNotification:(NSNotification *)notification {
    if (self.isViewLoaded) {
        
        if ([self.contacts allContacts].count == 0) {
            [self reloadContacts];
        }
        
        // if after reloading  we're still at 0 update contacts
        if ([_contacts allContacts].count == 0) {
            [self updateContactsWithCompletionBlock:^(bool success) {
                if ([self.contacts allContacts].count > 0) {
                    [self showLastYoStatuses];
                    [self presentBannerIfNeeded];
                }
            }];
        }
    }
}

- (void)userDidLogout:(NSNotification *)notification {
    self.contacts = nil;
    //[self recoverTableView];
    [self.contextTableViews makeObjectsPerformSelector:@selector(reloadData)];
}

- (void)appDidEnterBackGround:(NSNotification *)notification {
    
    START_BACKGROUND_TASK
    /*[[YoContextConfiguration sharedInstance] updateWithCompletionHandler:^(BOOL didUpdate) {
     if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
     if (didUpdate) {
     [self reloadContexts];
     }
     }
     
     END_BACKGROUND_TASK
     }];*/
    
    if ([YoApp currentSession].isLoggedIn) {
        YoMCLoadingState loadingStateBeforeUpdate = self.contactsLoadingState;
        
        void (^endUpdatingContacts)(UIBackgroundTaskIdentifier bgTask) = ^(UIBackgroundTaskIdentifier bgTask) {
            if (self.contactsLoadingState == YoMCLoadingStateLoading) {
                self.contactsLoadingState = loadingStateBeforeUpdate;
            }
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        };
        
        __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"YoReloadContactBGTask" expirationHandler:^{
            // Clean up any unfinished task business by marking where you
            // stopped or ending the task outright.
            endUpdatingContacts(bgTask);
        }];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            // Do the work associated with the task, preferably in chunks.
            [self updateContactsWithCompletionBlock:^(bool success) {
                endUpdatingContacts(bgTask);
            }];
        });
    }
}

- (void)userDidBeginToSendYoFromYoCardNotification:(NSNotification *)notification {
    if ([notification.userInfo[@"type"] isEqualToString:@"location"]) {
        [self scrollToContextAtIndex:-1 animated:YES];
    }
    NSString *username = [notification.userInfo objectForKey:Yo_USERNAME_KEY];
    YoUserTableViewCell *userCell = nil;
    UITableView *tableView = [self currentContextTableView];
    for (YoUserTableViewCell *cell in tableView.visibleCells) {
        if ([cell.user.username isEqualToString:username]) {
            userCell = cell;
            break;
        }
    }
    [userCell startAnimatingActivityIndicator];
}

- (void)userDidFinishSendingYoFromYoCardNotification:(NSNotification *)notification {
    NSString *username = [notification.userInfo objectForKey:Yo_USERNAME_KEY];
    NSString *type = [notification.userInfo objectForKey:@"type"];
    BOOL success = [[notification.userInfo objectForKey:@"success"] boolValue];
    NSString *sentText = [type isEqualToString:@"location"] ? [self.yoContextObjects[0] textForSentYo] : [self.currentContextObject textForSentYo];
    YoUserTableViewCell *userCell = nil;
    UITableView *tableView = [self currentContextTableView];
    for (YoUserTableViewCell *cell in tableView.visibleCells) {
        if ([cell.user.username isEqualToString:username]) {
            userCell = cell;
            break;
        }
    }
    [userCell stopAnimatingActivityIndicator];
    if (success == NO) {
        sentText = NSLocalizedString(@"failed", nil).capitalizedString;
    }
    
    [userCell flashText:sentText forDuration:2.5 completionHandler:nil];
}

- (void)locationServicesWhereDeniedNote:(NSNotification *)note {
    [self displayPermissionsBannerForCurrentContextIfNeeded];
}

- (void)AVMediaTypeVideoServicesWhereDeniedNote:(NSNotification *)note {
    [self displayPermissionsBannerForCurrentContextIfNeeded];
}

- (void)contextConfigurationDidChangeWithNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[YoContextObject class]]) {
        YoContextObject *context = (YoContextObject *)notification.object;
        NSInteger indexOfContext = [self.yoContextObjects indexOfObject:context];
        if (indexOfContext != NSNotFound) {
            YoContextView *contextView = [self.contextViews objectAtIndex:indexOfContext];
            [contextView.tableView reloadData];
            [contextView reloadConfiguration];
        }
    }
}

#pragma mark - Actions

- (void)valueChangedForPageControl:(UIPageControl *)pageControl {
    if ([pageControl isEqual:self.statusBar.pageControl]) {
        [self scrollToContextAtIndex:pageControl.currentPage animated:YES];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    YoTransitionAnimator *transitionAnimator = nil;
    UIViewController *keyViewController = presented;
    if ([keyViewController isKindOfClass:[UINavigationController class]]) {
        keyViewController =  [[(UINavigationController *)keyViewController viewControllers] firstObject];
    }
    if ([keyViewController isKindOfClass:[YOMenuController class]]) {
        transitionAnimator = [YoMenuTransitionAnimator new];
    }
    else {
        transitionAnimator = [YoCardTransitionAnimator new];
    }
    [transitionAnimator setTransition:YoPresentatingTransition];
    return transitionAnimator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    YoTransitionAnimator *transitionAnimator = nil;
    UIViewController *keyViewController = dismissed;
    if ([keyViewController isKindOfClass:[UINavigationController class]]) {
        keyViewController =  [[(UINavigationController *)keyViewController viewControllers] firstObject];
    }
    if ([keyViewController isKindOfClass:[YOMenuController class]]) {
        transitionAnimator = [YoMenuTransitionAnimator new];
    }
    else {
        transitionAnimator = [YoCardTransitionAnimator new];
    }
    [transitionAnimator setTransition:YoDismissingTransition];
    return transitionAnimator;
}

#pragma mark - External Navigation

- (IBAction)bottomLeftClearButtonTapped:(id)sender {
    if ( ! self.inboxButton.hidden) {
        [self presentInbox];
    }
    else {
        YoContextView *currentContextView = [self.contextViews objectAtIndex:self.currentContextIndex];
        [currentContextView.utilityButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (IBAction)presentInbox {
    YoInboxViewController *vc = [[YoInboxViewController alloc] init];
    vc.title = NSLocalizedString(@"Inbox", nil);
    
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
    
    nc.modalPresentationStyle = UIModalPresentationCustom;
    nc.transitioningDelegate = self;
    [self showBlurredBackgroundWithViewController:nc];
    [YoAnalytics logEvent:@"TappedNotificationInbox" withParameters:nil];
}

- (IBAction)presentYoPeoplePicker {
    YoAddPickerController *vc = [[YoAddPickerController alloc] initWithNibName:@"YoAddPickerController" bundle:nil];
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationCustom;
    nc.transitioningDelegate = self;
    vc.currentContextObject = self.currentContextObject;
    [self showBlurredBackgroundWithViewController:nc];
    [YoAnalytics logEvent:@"TappedAddButton" withParameters:nil];
}

- (void)presentMenuConroller {
    [self.currentContextObject didPresentSettings];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did.swipe.down"];
    YoNavigationController *nc = [self.storyboard instantiateViewControllerWithIdentifier:YoMenuControllerID];
    nc.allowCustomBarColor = YES;
    //nc.modalPresentationStyle = UIModalPresentationCustom;
    nc.transitioningDelegate = self;
    [self presentViewController:nc animated:YES completion:nil];
    [YoAnalytics logEvent:YoEventTappedMenuButton withParameters:nil];
}

- (void)presentProfileViewControllerForUser:(YoUser *)user {
    YoUserProfileViewController *userProfileVC = [self.storyboard instantiateViewControllerWithIdentifier:YoUserProfileViewControllerID];
    userProfileVC.user = user;
    userProfileVC.modalPresentationStyle = UIModalPresentationCustom;
    userProfileVC.transitioningDelegate = self;
    [self showBlurredBackgroundWithViewController:userProfileVC];
}

- (void)presentControllerForGroup:(YoGroup *)group {
    YoViewGroupController *vc = [self.storyboard instantiateViewControllerWithIdentifier:YoViewGroupViewControllerID];
    vc.group = group;
    YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationCustom;
    nc.transitioningDelegate = self;
    [self showBlurredBackgroundWithViewController:nc];
}

- (IBAction)centerPlusButtonPressed:(id)sender {
    if ([[YoUser me].centerPlusAction isEqualToString:@"friends"]) {
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
        YoAddController *vc = [mainStoryBoard instantiateViewControllerWithIdentifier:YoAddControllerID];
        vc.currentContextObject = self.currentContextObject;
        vc.mode = YoAddControllerAddToRecentsList;
        YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationCustom;
        nc.transitioningDelegate = self;
        [self.navigationController presentViewController:nc animated:YES completion:nil];
        [YoAnalytics logEvent:@"TappedAddFriendsFromEmptyScreen" withParameters:nil];
    }
    else if ([[YoUser me].centerPlusAction isEqualToString:@"group"]) {
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
        YoCreateGroupController *vc = [mainStoryBoard instantiateViewControllerWithIdentifier:YoCreateGroupControllerID];
        YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationCustom;
        nc.transitioningDelegate = self;
        [self.navigationController presentViewController:nc animated:YES completion:nil];
        [YoAnalytics logEvent:@"TappedCreateGroupFromEmptyScreen" withParameters:nil];
    }
    else {
        [self presentYoPeoplePicker];
    }
}

#pragma mark Add Friends ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    if (buttonIndex == AddActionSheetAddFriend) {
        
        YoAddFriendController *vc = [[YoAddFriendController alloc] initWithNibName:@"AddFriendController" bundle:nil];
        YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nc animated:YES completion:nil];
        
    }
    else if (buttonIndex == AddActionSheetCreateGroup) {
        
        YoCreateGroupController *vc = [[YoCreateGroupController alloc] initWithNibName:@"YoCreateGroupController" bundle:nil];
        YoNavigationController *nc = [[YoNavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nc animated:YES completion:nil];
        
    }
}

#pragma mark - Inbox

- (void)inboxUpdated {
    unsigned long count = [[[[YoUser me] yoInbox] getYosWithStatus:YoStatusReceived] count];
    [self updateInboxWithCount:count];
}

- (void)updateInboxWithCount:(NSInteger)newCount
{
    [self.inboxButton setTitle:MakeString(@"%lu", (unsigned long)newCount)
                      forState:UIControlStateNormal];
    
    if (newCount == 0) {
        [self hideInboxAnimated:YES];
    }
    else {
        if (self.inboxButton.isHidden) {
            [self showInboxAnimated:YES];
        }
        else {
            [self callAttentionToInboxWithCompletionBlock:nil];
        }
    }
}

- (void)fetchUnreadYos {
    [[YoUser me].yoInbox updateWithCompletionBlock:^(BOOL sucess) {
        NSArray *unreadYos = [[YoUser me].yoInbox getYosWithStatus:YoStatusReceived];
        [self updateInboxWithCount:unreadYos.count];
    }];
}

- (void)showInboxAnimated:(BOOL)animted
{
    if (self.inboxButton.isHidden == NO ||
        self.contextLocked) {
        return;
    }
    
    [self.inboxButton.superview bringSubviewToFront:self.inboxButton];
    
    if (animted) {
        self.inboxButton.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1.0);
        self.inboxButton.hidden = NO;
        [UIView animateWithDuration:2.0
                              delay:0.0
             usingSpringWithDamping:0.2
              initialSpringVelocity:6.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.inboxButton.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [self didShowInboxButton];
                         }];
    }
    else {
        self.inboxButton.hidden = NO;
        [self didShowInboxButton];
    }
}

- (void)didShowInboxButton {
    [self updateContextButtonLayoutAtIndex:self.currentContextIndex animated:YES];
}

- (void)callAttentionToInboxWithCompletionBlock:(void (^)())block
{
    if (self.inboxButton.isHidden) {
        DDLogWarn(@"<Yo> Tried bouncing the inbox while its hidden.");
        return;
    }
    self.inboxButton.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1.0);
    [UIView animateWithDuration:2.0
                          delay:0.0
         usingSpringWithDamping:0.2
          initialSpringVelocity:6.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.inboxButton.layer.transform = CATransform3DIdentity;
                     }
                     completion:^(BOOL finished) {
                         if (block) {
                             block();
                         }
                     }];
}

- (void)hideInboxAnimated:(BOOL)animted
{
    if (self.inboxButton.isHidden) {
        return;
    }
    if (animted) {
        [UIView animateWithDuration:0.2
                              delay:0.0
             usingSpringWithDamping:0.2
              initialSpringVelocity:4.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.inboxButton.transform = CGAffineTransformMakeScale(0.0, 0.0);
                         }
                         completion:^(BOOL finished) {
                             self.inboxButton.hidden = YES;
                             [self didHideInboxButton];
                         }];
    }
    else {
        self.inboxButton.hidden = YES;
        [self didHideInboxButton];
    }
}

- (void)didHideInboxButton {
    [self updateContextButtonLayoutAtIndex:self.currentContextIndex animated:YES];
}

#pragma mark -

- (void)animateTopCells:(NSInteger)numbersOfCells {
    NS_DURING
    NSMutableArray *indexPaths = [NSMutableArray array];
    UITableView *tableView = [self currentContextTableView];
    for (int i = 0 ; i < numbersOfCells && i < [tableView numberOfRowsInSection:0] ; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    NS_HANDLER
    DDLogError(@"%@", localException);
    NS_ENDHANDLER
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showFirstFriendPopupIfNeeded];
    });
}

@end
