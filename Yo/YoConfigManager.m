//
//  YoConfigManager.m
//  Yo
//
//  Created by Peter Reveles on 12/18/14.
//
//

#import "YoConfigManager.h"

#ifndef IS_APP_EXTENSION
#import "YoNotification.h"
#endif

#define URL_ADDRESS_OF_JSON @"https://yoapp.s3.amazonaws.com/yo/config.json"

#define Yo_BANNERS_DIC_KEY @"banners_dic"
#define Yo_BANNERS_KEY @"banners"

#define Yo_BANNERS_SCHEME_KEY @"scheme_version"

@interface YoConfigManager () <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSDictionary *configurationDic;
@property (nonatomic, strong) NSDictionary *openCountToYoNoteDic;

@property (nonatomic, strong) NSMutableOrderedSet *handlersInQueue;

@property (nonatomic, strong) NSArray *comprhendableSchemes;

@end

@implementation YoConfigManager

#pragma mark - Lazy Loading

- (NSMutableOrderedSet *)handlersInQueue{
    if (!_handlersInQueue) {
        _handlersInQueue = [NSMutableOrderedSet new];
    }
    return _handlersInQueue;
}

- (NSArray *)comprhendableSchemes {
    if (!_comprhendableSchemes) {
        _comprhendableSchemes = @[@(1.0)];
    }
    return _comprhendableSchemes;
}

- (BOOL)comprehendsBannerSchemeVersion:(NSInteger)scheme_version {
    BOOL comprehendsScheme = NO;
    if ([self.comprhendableSchemes containsObject:@(scheme_version)]) {
        comprehendsScheme = YES;
    }
    return comprehendsScheme;
}

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    
    static YoConfigManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        _sharedInstance.loadingStatus = YoLoadingStatusUnstarted;
        _sharedInstance.configurationDic = nil;
        [_sharedInstance addListeners];
    });
    
    return _sharedInstance;
}

- (void)addListeners{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didEnterBackground{
    [self clear];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)respondToAllHandlersWithSuccess:(BOOL)success{
    for (void (^handler)(BOOL success) in self.handlersInQueue) {
        handler(success);
    }
    self.handlersInQueue = nil;
}

- (void)respondToHandler:(void (^)(BOOL sucess))handler success:(BOOL)success{
    if (handler) {
        handler(success);
        if (!success) DDLogWarn(@"YoConfigManager failed to provid successful response to a handler");
    }
}

- (void)updateWithCompletionHandler:(void (^)(BOOL sucess))handler{
    
    if (self.loadingStatus == YoLoadingStatusInProgress) {
        // add handler to queue
        [self.handlersInQueue addObject:handler];
        return;
    }
    else if (self.loadingStatus == YoLoadingStatusFailed) {
        [self respondToHandler:handler success:NO];
    }
    else if (self.loadingStatus == YoLoadingStatusComplete && self.configurationDic) {
        [self respondToHandler:handler success:YES];
    }
    else {
        // Yoloading status is virgin, add handler to queue and proceed to fetch config file
        [self.handlersInQueue addObject:handler];
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL_ADDRESS_OF_JSON]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            self.loadingStatus = YoLoadingStatusFailed;
            DDLogError(@"Failed to fetch config at: %@ %@", URL_ADDRESS_OF_JSON, connectionError);
        }
        else {
            if (data) {
                [self processConfigData:data];
                self.loadingStatus = YoLoadingStatusComplete;
            }
            else {
                [self respondToAllHandlersWithSuccess:NO];
                self.loadingStatus = YoLoadingStatusFailed;
                return;
            }
        }
        [self respondToAllHandlersWithSuccess:connectionError?NO:YES];
    }];
    
    self.loadingStatus = YoLoadingStatusInProgress;
}

- (void)processConfigData:(NSData *)data {
    self.configurationDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (void)clear{
    self.configurationDic = nil;
    self.loadingStatus = YoLoadingStatusUnstarted;
}

#pragma mark - Data retrieval

- (id)configValueforKey:(NSString *)key{
    return [self.configurationDic objectForKey:key];
}

#pragma mark - User Friendly Methods

- (NSString *)serverVersionNumber{
    NSString *response = [self configValueforKey:@"ios_version"];
    return response;
}

- (BOOL)isUpdateMandatory{
    BOOL response = [[self configValueforKey:@"is_ios_update_mandatory"] boolValue];
    return response;
}

- (NSString *)releaseNotes{
    NSString *response = [self configValueforKey:@"release_notes"];
    return response;
}

- (NSString *)theme{
    NSString *response = [self configValueforKey:@"theme"];
    return response;
}

- (CGFloat)indexVersion{
    CGFloat response = [[self configValueforKey:@"index_version"] floatValue];
    return response;
}

- (BOOL)shouldEnableFacebook{
    BOOL response = [[self configValueforKey:@"should_enable_facebook"] boolValue];
    return response;
}

- (double)yoDisplayTime {
    NS_DURING
    double timeToDisplay = 0.0;
    id value = [self configValueforKey:@"time_permited_for_yo_to_display_on_screen"];
    if (!value) {
        timeToDisplay = 0.0;
    }
    else {
        timeToDisplay = [value doubleValue];
    }
    return timeToDisplay;
    NS_HANDLER
    return 0.0;
    NS_ENDHANDLER
}

- (BOOL)addContactShouldAlwaysOpenFindFriends {
    BOOL response = [[self configValueforKey:@"add_contact_should_always_open_find_friends"] boolValue];
    return response;
}

- (BOOL)addContactShouldAlwaysPresentKeyboard {
    BOOL response = [[self configValueforKey:@"add_contact_should_always_present_keyboard"] boolValue];
    return response;
}

- (NSInteger)getYoAnalayticsDesiredControllerHistoryCount {
    NS_DURING
    NSInteger controllerHistory = 0;
    id value = [self configValueforKey:@"yo_analaytics_desired_controller_history_count"];
    if (!value) {
        controllerHistory = 2;
    }
    else {
        controllerHistory = [value integerValue];
    }
    return controllerHistory;
    NS_HANDLER
    return 2;
    NS_ENDHANDLER
}


- (NSString *)getWelcomeScreenTitle {
    NSString *response = [self configValueforKey:@"yo_welcome_screen_title"];
    if (![response length]) response = NSLocalizedString(@"Welcome to Yo", nil);
    return response;
}

- (NSString *)getWelcomeScreenDescription {
    NSString *response = [self configValueforKey:@"yo_welcome_screen_description"];
    if (![response length]) response = NSLocalizedString(@"The simplest way to communicate.", nil);
    return response;
}

- (NSArray *)getTitlesForWelcomeScreen {
    NSArray *titles = [self configValueforKey:@"yo_welcome_screen_speech_bubble_texts"];
    if (titles == nil) {
        titles = @[NSLocalizedString(@"JENNY uses Yo to say\n'Hey, thinking of you!'", nil),
                   NSLocalizedString(@"PETER uses Yo to send\nhis location to his girlfriend.", nil),
                   NSLocalizedString(@"MATTHEW Yo's to say 'Coffee?'", nil),
                   NSLocalizedString(@"SHARON uses Yo to remind everyone\nthe meeting starts now.", nil),
                   NSLocalizedString(@"ALEX gets a Yo when\nChelsea scores a goal!", nil)];
    }
    return titles;
}

#pragma mark - On-Boarding
#pragma mark - First Onboarding
- (NSString *)onboardingSharePrompt{
    NSString *response = [self configValueforKey:@"onboarding_share_prompt"];
    if (![response length]) response = NSLocalizedString(@"Share Your Yo, Yo", nil);
    return response;
}

- (NSURL *)onboardingURL{
    NSString *URLString = [self configValueforKey:@"onboarding_URL"];
    if (![URLString length]) URLString = @"http://www.yotext.co/show/?text=Welcome%20to%20Yo!!";
    return [NSURL URLWithString:URLString];
}

- (NSString *)onBoardingIndexPrompt{
    NSString *response = [self configValueforKey:@"onboarding_index_prompt"];
    if (![response length]) response = NSLocalizedString(@"Get Yo'd by Awesome Services!", nil);
    return response;
}

- (NSString *)onBoardingIndexTitle{
    NSString *response = [self configValueforKey:@"onboarding_index_title"];
    if (![response length]) response = NSLocalizedString(@"Yo Index", nil);
    return response;
}

#pragma mark - Second On-Boarding

- (NSString *)onBoardingCloseTheAppPrompt {
    NSString *response = [self configValueforKey:@"onboarding_close_the_app_prompt"];
    if (![response length]) {
        response = NSLocalizedString(@"Close the App to\nSee Something Cool", nil);
    }
    return response;
}

- (NSString *)onBoardingYoNeedsPushPrompt {
    NSString *response = [self configValueforKey:@"onboarding_yo_needs_push_prompt"];
    if (![response length]) {
        response = NSLocalizedString(@"Yo Needs Push Access", nil);
    }
    return response;
}

- (NSString *)onBoardingFirstYoPrompt {
    NSString *response = [self configValueforKey:@"onboarding_first_yo_prompt"];
    if (![response length]) {
        response = NSLocalizedString(@"This is a 📎 Yo\n👐 Tap to Open it!", nil);
    }
    return response;
}

- (BOOL)dontSendYoAfterOnBoarding {
    BOOL response = [[self configValueforKey:@"dont_send_yo_after_onboaring"] boolValue];
    return response;
}

- (double)timeBeforeSendingAfterOnBoardingYo {
    NS_DURING
    double timeToDisplay = 0.0;
    id value = [self configValueforKey:@"after_onboarding_time_before_sending_yo"];
    if (!value) {
        timeToDisplay = 2.0;
    }
    else {
        timeToDisplay = [value doubleValue];
    }
    return timeToDisplay;
    NS_HANDLER
    return 2.0;
    NS_ENDHANDLER
}

- (double)timeForShowingStatus {
    NS_DURING
    double timeToDisplay = 0.0;
    id value = [self configValueforKey:@"after_onboarding_time_before_sending_yo"];
    if (!value) {
        timeToDisplay = 7.0;
    }
    else {
        timeToDisplay = [value doubleValue];
    }
    return timeToDisplay;
    NS_HANDLER
    return 7.0;
    NS_ENDHANDLER
}

- (NSURL *)afterOnBoardingYoURL {
    NSString *URLString = [self configValueforKey:@"after_onboarding_yo_URL"];
    if (![URLString length]) {
        URLString = @"http://p.justyo.co/info/";
    }
    return [NSURL URLWithString:URLString];
}

- (NSString *)afterOnBoardingYoPrompt {
    NSString *response = [self configValueforKey:@"after_onboarding_yo_prompt"];
    if (![response length]) {
        response = NSLocalizedString(@"👉 Tap to open\n📎 Yo From YOTEAM", nil);
    }
    return response;
}

- (NSDictionary *)sampleContextConfiguration
{
    NSDictionary *sampleContextConfiguration = [self configValueforKey:@"sample_context_configuration"];
    return sampleContextConfiguration;
}

@end
