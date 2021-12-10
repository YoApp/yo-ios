//
//  YoWebBrowserController.m
//  Yo
//
//  Created by Peter Reveles on 12/1/14.
//
//

#import "YoImageController.h"
#import "YoWebBrowserController.h"
#import "YoThisViewController.h"
#import "YoThisExtensionController.h"
#import "YOFacebookManager.h"
#import "YoManager.h"
#import <WebKit/WebKit.h>
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>
#import "YoProgressViewManager.h"
#import "YoShareSheet.h"
#import <JBWhatsAppActivity/JBWhatsAppActivity.h>
#import "Yo.h"
#import "YoTwitterHandleManager.h"
#import "TUSafariActivity.h"
#import "YoInbox.h"

typedef NS_ENUM(NSUInteger, YoShareType) {
    YoShareType_Facebook,
    YoShareType_Twitter,
    YoShareType_WhatsApp,
    YoShareType_Apple,
};

@interface YoWebBrowserController () <WKNavigationDelegate, UIWebViewDelegate, WKUIDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *reloadButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;

@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;

@property (weak, nonatomic) IBOutlet UIButton *bigShareButton;


@property (nonatomic, assign) BOOL updateTitleForWebPage;
@property (nonatomic, strong) NSURL *URL;

@property (strong, nonatomic) NSString *lastURLPresentedByShareSheet;

@property (weak, nonatomic) WKWebView *WKWebView;
@property (weak, nonatomic) UIWebView *UIWebView;

@property (strong, nonatomic) WKWebView *WKWebView_tempStrong;
@property (strong, nonatomic) UIWebView *UIWebView_tempStrong;

@property (strong, nonatomic) YoThisViewController *yoThisVC;
@property (strong, nonatomic) YoThisExtensionController *yoShareSheet;
@property (strong, nonatomic) YoAlert *yoPostAlertView;

@property (weak, nonatomic) IBOutlet UIButton *buttonWhichCoversShareOptions;

@property (strong, nonatomic) NSString *dismissButtonTitle;

@property (strong, nonatomic) NSString *fixedTitle;

@property (strong, nonatomic) YoProgressViewManager *progressManager;

@end

@implementation YoWebBrowserController

#pragma mark - Life

- (instancetype)initWithUrl:(NSURL*)url{
    self = [super init];
    if (self) {
        // setup
        _URL = url;
        [self setupWebView];
    }
    return self;
}

- (instancetype)initWithUrl:(NSURL *)url fixedTitle:(NSString *)title{
    self = [self initWithUrl:url];
    if (self) {
        // setup
        _updateTitleForWebPage = NO;
        _fixedTitle = title;
    }
    return self;
}

- (instancetype)initWithUrl:(NSURL *)url forYo:(Yo *)yo {
    self = [self initWithUrl:url forYo:yo];
    if (self) {
        [self setSourceYo:yo];
    }
    return self;
}

- (void)setSourceYo:(Yo *)yo {
    _sourceYo = yo;
    NSURL *url = yo.url;
    if ([[yo senderUsername] length]) {
        NSString *title = nil;
        if (yo.isGroupYo) {
            title = MakeString(@"%@ to %@", [yo.senderObject displayName], [yo groupName]);
        }
        else {
            title = [yo.senderObject displayName];
        }
        _updateTitleForWebPage = NO;
        _fixedTitle = title;
    }
    _URL = url;
    [self setupWebView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.profileImageView setImageWithURL:self.sourceYo.senderObject.photoURL];
    self.usernameLabel.text = [self.sourceYo.creationDate agoString];
    
    self.bigShareButton.hidden = [self.sourceYo isFromService];
    
    [self layoutWebView];
    
    [self addProgressView];
    
    self.yoThisVC = [YoThisViewController new];
    
    if ([self.fixedTitle length])
        [self.titleLabel setText:self.fixedTitle];
    
    [self.topContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topContainerViewTapped)]];
    //self.topContainerView.backgroundColor = [UIColor colorWithHexString:AMETHYST]; // setting this will remove the dark tint from the nav bar
    
    if ([self.dismissButtonTitle length]) {
        [self.buttonWhichCoversShareOptions setTitle:self.dismissButtonTitle forState:UIControlStateNormal];
        self.buttonWhichCoversShareOptions.hidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.sourceYo) {
        [[YoUser me].yoInbox updateOrAddYo:self.sourceYo withStatus:YoStatusRead];
    }
}

- (void)setupWebView{
    
    // Load the URL in the webView
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
    if ([self.URL.host isEqualToString:@"index.justyo.co"] && [[YoApp currentSession] isLoggedIn]) {
        [request addValue:MakeString(@"Bearer %@", [YoApp currentSession].accessToken) forHTTPHeaderField:@"Authorization"];
    }
    
    if (IS_OVER_IOS(8.0)) {
        // use WKWebView
        WKWebView *webView = [WKWebView new];
        [webView loadRequest:request];
        webView.navigationDelegate = self;
        webView.UIDelegate = self;
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        
        //webView.configuration.allowsInlineMediaPlayback = YES;
        webView.configuration.mediaPlaybackAllowsAirPlay = YES;
        webView.configuration.mediaPlaybackRequiresUserAction = NO;
        // allows pages to redirect to another host
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
        
        if ([self.URL.host isEqualToString:@"index.justyo.co"]) {
            webView.backgroundColor = [UIColor colorWithHexString:AMETHYST];
            webView.opaque = NO;
        }
        
        self.WKWebView_tempStrong = webView;
    }
    else {
        // user UIWebView
        UIWebView *webView = [UIWebView new];
        [webView loadRequest:request];
        webView.delegate = self;
        
        webView.mediaPlaybackAllowsAirPlay = YES;
        webView.mediaPlaybackRequiresUserAction = NO;
        
        webView.scalesPageToFit = YES;
        if ([self.URL.host isEqualToString:@"index.justyo.co"]) {
            webView.backgroundColor = [UIColor colorWithHexString:AMETHYST];
            webView.opaque = NO;
        }
        
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.UIWebView_tempStrong = webView;
    }
}

- (void)layoutWebView{
    if ([self isKindOfClass:[YoImageController class]]) { // @or: this is an image presenter
        return;
    }
    if (IS_OVER_IOS(8.0)) {
        [self.webContainerView addSubview:self.WKWebView_tempStrong];
        self.WKWebView = self.WKWebView_tempStrong;
        self.WKWebView_tempStrong = nil;
        
        NSDictionary *views = @{@"webView":self.WKWebView};
        
        [self.webContainerView addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[webView]|"
          options:0 metrics:nil views:views]];
        
        [self.webContainerView addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[webView]|"
          options:0 metrics:nil views:views]];
    }
    else {
        [self.webContainerView addSubview:self.UIWebView_tempStrong];
        self.UIWebView = self.UIWebView_tempStrong;
        self.UIWebView_tempStrong = nil;
        
        NSDictionary *views = @{@"webView":self.UIWebView};
        
        [self.webContainerView addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[webView]|"
          options:0 metrics:nil views:views]];
        
        [self.webContainerView addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[webView]|"
          options:0 metrics:nil views:views]];
    }
}

- (void)addProgressView{
    YoProgressViewManager *progressManager = nil;
    if (self.WKWebView)
        progressManager = [[YoProgressViewManager alloc] initForWKWebView:self.WKWebView];
    //else if (self.UIWebView)
    //progressManager = [[YoProgressViewManager alloc] initForUIWebView:self.UIWebView];
    
    self.progressManager = progressManager;
    
    if (!progressManager) return; // safety check
    
    progressManager.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *containerView = self.webContainerView;
    
    [containerView addSubview:progressManager.view];
    
    NSDictionary *views = @{@"progressView":progressManager.view};
    
    [containerView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[progressView]|"
      options:0 metrics:nil views:views]];
    
    [containerView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[progressView(2)]"
      options:0 metrics:nil views:views]];
}

- (void)dealloc{
    [self.progressManager terminate];
}

- (void)shouldDisplayNextButton{
    self.dismissButtonTitle = NSLocalizedString(@"Back", nil);
}

- (void)shouldDisplayDismissButtonWithTitle:(NSString *)dismissButtonTitle {
    self.dismissButtonTitle = dismissButtonTitle;
}

#pragma mark - Actions

- (IBAction)userDidPressNextButton:(id)sender {
    [self dismissWithCompletionBlock:nil];
}

- (void)topContainerViewTapped{
    if (IS_OVER_IOS(8.0))
        [self.WKWebView.scrollView setContentOffset:CGPointZero animated:YES];
    else
        [self.UIWebView.scrollView setContentOffset:CGPointZero animated:YES];
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    [self dismissWithCompletionBlock:nil];
}

- (void)dismissWithCompletionBlock:(void (^)())block{
    id <YoWebBroswersDelegate> delegate = self.delegate;
    [self closeWithCompletionBlock:^{
        if (block) {
            block();
        }
        if (delegate) {
            [delegate yoWebBrowserDidClose];
        }
    }];
}

- (IBAction)reloadButtonPressed:(UIButton *)sender {
    if (IS_OVER_IOS(8.0))
        [self.WKWebView reload];
    else
        [self.UIWebView reload];
}

- (IBAction)backButtonTapped:(id)sender {
    if (IS_OVER_IOS(8.0))
        [self.WKWebView goBack];
    else
        [self.UIWebView goBack];
}

- (IBAction)forwardButtonTapped:(id)sender {
    if (IS_OVER_IOS(8.0))
        [self.WKWebView goForward];
    else
        [self.UIWebView goForward];
}

- (IBAction)shareButtonTapped:(UIButton *)sender {
    //[self presentYoShareController];
    [self presentYoPostAlert];
}

- (IBAction)yoThisButtonTapped:(UIButton *)sender {
    [self presentYoThisController];
}

- (IBAction)unsubscribeButtonPressed:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:MakeString(@"Stop receiving Yos from %@?", [self.sourceYo.senderObject displayName])
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Unsubscribe" otherButtonTitles:nil];
    sheet.tag = 4;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 4 && buttonIndex != actionSheet.cancelButtonIndex) {
        [[[YoUser me] contactsManager] unsubscribeFromServiceWithUsername:self.sourceYo.senderUsername
                                                      withCompletionBlock:^(BOOL success) {
                                                          if (success) {
                                                              [[YoAlertManager sharedInstance] showAlertWithTitle:@"Yo" text:@"Unsubscribed"];
                                                          }
                                                          else {
                                                              [[YoAlertManager sharedInstance] showAlertWithTitle:@"Yo" text:@"Failed to unsubscribe 😔"];
                                                          }
                                                      }];
    }
}

#pragma mark - Sharing

- (NSURL *)urlToShare{
    // default share URL is the intially loaded URL
    NSURL *urlToShare = self.URL;
    // Best case, share the currently loaded WebView URL
    if ([[[self.UIWebView.request URL] absoluteString] length])
        urlToShare = [self.UIWebView.request URL];
    return urlToShare;
}

- (void)presentYoThisController {
    NSURL *urlToShare = self.URL;
    if (![urlToShare.absoluteString length])
        DDLogWarn(@"Attempt to present Share sheet w/o url");
    if (self.sourceYo && [[self.sourceYo url] isEqual:urlToShare]) {
        [self.yoThisVC presentShareSheetOnView:self.view toForwardYo:self.sourceYo];
    }
    else {
        [self.yoThisVC presentShareSheetOnView:self.view toShare:urlToShare];
    }
}

- (UIImage *)renderShareImageWithBannerText:(NSString *)text{
    CGFloat width = CGRectGetWidth(APPDELEGATE.window.bounds);
    CGFloat height = width; // 1x1
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    if (IS_OVER_IOS(8.0))
        [self.webContainerView drawViewHierarchyInRect:CGRectMake(0.0f, self.topContainerView.height, width, self.webContainerView.height) afterScreenUpdates:YES];
    else if (IS_OVER_IOS(7.0))
        [self.webContainerView drawViewHierarchyInRect:CGRectMake(0.0f, self.topContainerView.height, width, self.webContainerView.height) afterScreenUpdates:YES];
    else // ios 6
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    if ([text length]) {
        UIView *yoBanner = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, self.topContainerView.height)];
        yoBanner.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, self.topContainerView.height)];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.text = text;
        [yoBanner addSubview:textLabel];
        [yoBanner.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSString *)yoMeURLForUsername:(NSString *)username shareType:(YoShareType)shareType{
    BOOL useBitly = NO;
    switch (shareType) {
        case YoShareType_Facebook:
            useBitly = YES;
            break;
            
        case YoShareType_Twitter:
            useBitly = NO;
            break;
            
        case YoShareType_WhatsApp:
            useBitly = NO;
            break;
            
        default:
            useBitly = NO;
            break;
    }
    
    NSString *yoURL = @"http://www.justyo.co";
    
    if ([username length])
        yoURL = [yoURL stringByAppendingString:MakeString(@"/%@", username)];
    
    if (useBitly) {
        NSURL *yoURLBITLY = [NSURL URLWithString:yoURL shouldBitlyWrap:YES];
        if ([yoURLBITLY.absoluteString length]) {
            yoURL = yoURLBITLY.absoluteString;
        }
    }
    
    return yoURL;
}

- (NSString *)shareMessageForURL:(NSString *)url shareType:(YoShareType)shareType{
    
    if (shareType == YoShareType_Facebook) {
        return nil;
    }
    
    // source is original api sender
    NSString *yoURL = [self yoMeURLForUsername:self.sourceYo.senderUsername shareType:shareType];
    
    // the yo index is special
    if ([[[NSURL URLWithString:url] host] isEqualToString:@"index.justyo.co"]) {
        NSString *indexMessage = NSLocalizedString(@"The Yo Index - subscribe to get Yo'd from awesome services!", nil);
        if (shareType == YoShareType_WhatsApp)
            indexMessage = [indexMessage stringByAppendingString:MakeString(@" %@", url)];
        else {
            indexMessage = [indexMessage stringByAppendingString:MakeString(@"\n%@", url)];
        }
        return indexMessage;
    }
    
    NSURL *bitlyWrappedURL = [NSURL URLWithString:url shouldBitlyWrap:YES];
    NSString *message = MakeString(@"Found this on Yo %@", url); // default
    
    switch (shareType) {
        case YoShareType_Twitter:
        {
            if (self.sourceYo.senderUsername) {
                NSString *twitterHandle = nil;
                message = MakeString(@"%@", bitlyWrappedURL.absoluteString);
                if ([self.sourceYo.originUsername length] && ![self.sourceYo.originUsername isEqualToString:self.sourceYo.senderUsername]) {
                    NSString *yoOriginalSenderURLString = [self yoMeURLForUsername:self.sourceYo.originUsername shareType:shareType];
                    message = [message stringByAppendingString:MakeString(@"\nvia %@ subscribe here %@", self.sourceYo.originUsername, yoOriginalSenderURLString)];
                    //twitterHandle = [[YoTwitterHandleManager sharedInstance] handleForYoUsername:self.sourceYo.originUsername];
                }
                else {
                    message = [message stringByAppendingString:MakeString(@"\nSubscribe here %@", yoURL)];
                   // twitterHandle = [[YoTwitterHandleManager sharedInstance] handleForYoUsername:self.sourceYo.senderUsername];
                }
                if ([twitterHandle length]) {
                    message = MakeString(@"%@ | %@", message, twitterHandle);
                }
            }
            else {
                message = MakeString(@"Found this on Yo %@", bitlyWrappedURL.absoluteString);
                message = [message stringByAppendingString:MakeString(@"\nGet Yo %@", yoURL)];
            }
        }
            break;
            
        case YoShareType_WhatsApp:
            if ([self.sourceYo.senderUsername length]) {
                message = MakeString(@"Yo from %@ [%@] subscribe here %@", self.sourceYo.senderUsername, url, yoURL);
            }
            else {
                message = MakeString(@"Found this on Yo %@  Get Yo %@", url, yoURL);
            }
            break;
            
        case YoShareType_Apple:
        {
            if (self.sourceYo.senderUsername) {
                message = MakeString(@"Yo from %@ %@", self.sourceYo.senderUsername, url);
                if ([self.sourceYo.originUsername length] && ![self.sourceYo.originUsername isEqualToString:self.sourceYo.senderUsername]) {
                    NSString *yoOriginalSenderURLString = [self yoMeURLForUsername:self.sourceYo.originUsername shareType:shareType];
                    message = [message stringByAppendingString:MakeString(@"\nvia %@ subscribe here %@", self.sourceYo.originUsername, yoOriginalSenderURLString)];
                }
                else {
                    message = [message stringByAppendingString:MakeString(@"\nSubscribe here %@", yoURL)];
                }
            }
            else {
                message = MakeString(@"Found this on Yo %@", url);
                message = [message stringByAppendingString:MakeString(@"\nGet Yo %@", yoURL)];
            }
        }
            break;
            
        default:
            break;
    }
    
    return message;
}

- (void)presentYoPostAlert{
    // Share Objective: Share the content the user is currently viewing
    // Associate the content (vicually) with Yo
    // make it possible for user to get to the yo app in 1-2 clicks
    
    NSURL *contentURL = self.URL;
    if (![[contentURL absoluteString] length])
        return; // worse case senario, prevent crash
    
    NSString *contentURLString = contentURL.absoluteString;
    
    if (!self.yoPostAlertView || ![self.lastURLPresentedByShareSheet isEqualToString:contentURLString]) {
        
        NSString *defaultText = self.titleLabel.text;
        
        UIImage *shareImage = [self renderShareImageWithBannerText:[self.sourceYo.senderUsername length]?MakeString(NSLocalizedString(@"Yo from %@", @"Yo from {USERNAME}"), self.sourceYo.senderUsername):defaultText];
        
        // create share sheet once per web session
        YoAlert *yoPostAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Share", nil) image:shareImage desciption:@""];
        
        __weak YoWebBrowserController *weakSelf = self;
        
        [yoPostAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Share", nil) tapBlock:^{
            NSString *appleShareMessage = [self shareMessageForURL:contentURLString shareType:YoShareType_Apple];
            
            TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
            
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[appleShareMessage,contentURL, shareImage]
                                              applicationActivities:@[safariActivity]];
            [weakSelf presentViewController:activityViewController
                                   animated:YES
                                 completion:nil];
        }]];
        
        
        YoAlertAction *shareOnYo = [[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Yo This", nil) tapBlock:^{
            [self presentYoThisController];
        }];
        
        [yoPostAlert addAction:shareOnYo];
        
        self.yoPostAlertView = yoPostAlert;
    }
    
    [[YoAlertManager sharedInstance] showAlert:self.yoPostAlertView];
}

- (void)presentYoShareController {
    // Share Objective: Share the content the user is currently viewing
    // Associate the content (visually) with Yo
    // make it possible for user to get to the yo app in 1-2 clicks
    
    NSURL *contentURL = self.URL;
    if (![[contentURL absoluteString] length])
        return; // worse case senario, prevent crash
    
    NSString *contentURLString = contentURL.absoluteString;
    
    if (!self.yoShareSheet || ![self.lastURLPresentedByShareSheet isEqualToString:contentURLString]) {
        
        NSString *defaultText = self.titleLabel.text;
        
        UIImage *shareImage = [self renderShareImageWithBannerText:[self.sourceYo.senderUsername length]?MakeString(NSLocalizedString(@"Yo from %@", @"Yo from {USERNAME}"), self.sourceYo.senderUsername):defaultText];
        
        // create share sheet once per web session
        YoThisExtensionController *shareSheet = [YoThisExtensionController new];
        
        __weak YoWebBrowserController *_weakSelf = self;
        
        // Share on WhatsApp
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://"]]) {
            YoTableViewAction *shareOnWhatsApp = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"WhatsApp", nil) tapBlock:^{
                [_weakSelf.yoShareSheet dissmiss];
                
                NSString *whatsAppMessage = [self shareMessageForURL:contentURLString shareType:YoShareType_WhatsApp];
                
                whatsAppMessage = [whatsAppMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                NSString *whatsAppDeepLink = MakeString(@"whatsapp://send?text=%@", whatsAppMessage);
                
                // Open the URL with Chrome.
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:whatsAppDeepLink]];
                if (self.sourceYo.payload) {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"whatsapp",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
                }
                else {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"whatsapp",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
                }
            }];
            
            [shareSheet addAction:shareOnWhatsApp];
        }
        // share on SinaWeibo
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]){
            YoTableViewAction *shareOnSinaWeibo = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"SinaWeibo", nil) tapBlock:^{
                [_weakSelf.yoShareSheet dissmiss];
                
                SLComposeViewController *sinaWeiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
                
                [sinaWeiboSheet setInitialText:MakeString(@"Yo %@ ", contentURLString)];
                [sinaWeiboSheet addImage:shareImage];
                [sinaWeiboSheet addURL:[[NSURL URLWithString:@"http://www.justyo.co"] bitlyWraped]];
                
                [_weakSelf presentViewController:sinaWeiboSheet animated:YES completion:nil];
                if (self.sourceYo.payload) {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"sina_weibo",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
                }
                else {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"sina_weibo",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
                }
            }];
            
            [shareSheet addAction:shareOnSinaWeibo];
        }
        // share on TencentWeibo
        if (IS_OVER_IOS(7.0) && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]){
            YoTableViewAction *shareOnTencentWeibo = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"TencentWeibo", nil) tapBlock:^{
                [_weakSelf.yoShareSheet dissmiss];
                
                SLComposeViewController *tencentWeiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
                
                [tencentWeiboSheet setInitialText:MakeString(@"Yo %@ ", contentURLString)];
                [tencentWeiboSheet addImage:shareImage];
                [tencentWeiboSheet addURL:[[NSURL URLWithString:@"http://www.justyo.co"] bitlyWraped]];
                
                [_weakSelf presentViewController:tencentWeiboSheet animated:YES completion:nil];
                if (self.sourceYo.payload) {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"tencent_weibo",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
                }
                else {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"tencent_weibo",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
                }
            }];
            
            [shareSheet addAction:shareOnTencentWeibo];
        }
        
        // open in safari
        YoTableViewAction *openInSafari = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Open in Safari", nil) tapBlock:^{
            [_weakSelf.yoShareSheet dissmiss];
            [[UIApplication sharedApplication] openURL:contentURL];
            if (self.sourceYo.payload) {
                [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"safari",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
            }
            else {
                [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"safari",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
            }
        }];
        
        [shareSheet addAction:openInSafari];
        
        // open in chrome (if chrome installed)
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
            // Chrome is installed, add the option to open in chrome.
            YoTableViewAction *openInChrome = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Open in Chrome", nil) tapBlock:^{
                
                [_weakSelf.yoShareSheet dissmiss];
                
                NSString *scheme = contentURL.scheme;
                
                // Replace the URL Scheme with the Chrome equivalent.
                NSString *chromeScheme = nil;
                if ([scheme isEqualToString:@"http"]) {
                    chromeScheme = @"googlechrome";
                } else if ([scheme isEqualToString:@"https"]) {
                    chromeScheme = @"googlechromes";
                }
                
                // Proceed only if a valid Google Chrome URI Scheme is available.
                if (chromeScheme) {
                    NSString *absoluteString = [contentURL absoluteString];
                    NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
                    NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
                    NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
                    NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
                    
                    // Open the URL with Chrome.
                    [[UIApplication sharedApplication] openURL:chromeURL];
                }
                if (self.sourceYo.payload) {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"google_chrome",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
                }
                else {
                    [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"google_chrome",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
                }
            }];
            
            [shareSheet addAction:openInChrome];
        }
        
        // present apple share UI
        YoTableViewAction *openAppleShare = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Even More", nil) tapBlock:^{
            // cases
            [_weakSelf.yoShareSheet dissmiss];
            
            NSString *appleShareMessage = [self shareMessageForURL:contentURLString shareType:YoShareType_Apple];
            
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[appleShareMessage, shareImage]
                                              applicationActivities:nil];
            [_weakSelf presentViewController:activityViewController
                                    animated:YES
                                  completion:nil];
            if (self.sourceYo.payload) {
                [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"even_more",YoParam_Yo_PAYLOAD:self.sourceYo.payload?:@{}}];
            }
            else {
                [YoAnalytics logEvent:YoEventShared withParameters:@{YoParam_SHARE_OPTION:@"even_more",YoParam_LINK:contentURL.absoluteString?:@"no_url"}];
            }
        }];
        
        [shareSheet addAction:openAppleShare];
        
        self.yoShareSheet = shareSheet;
    }
    
    [self.yoShareSheet showOnView:self.view];
}

#pragma mark - Page Navigation

- (void)togglePageNavigationButtons{
    if (IS_OVER_IOS(8.0)) {
        self.backButton.enabled = self.WKWebView.canGoBack;
        self.forwardButton.enabled = self.WKWebView.canGoForward;
    }
    else {
        self.backButton.enabled = self.UIWebView.canGoBack;
        self.forwardButton.enabled = self.UIWebView.canGoForward;
    }
}

- (void)startLoadingIndicators{
    if (self.progressManager) return; // progress manager is taking care of loading indication
    // stop activity indicator
    if ([self.activityIndicator isAnimating]) return;
    [UIView animateWithDuration:0.2 animations:^{
        self.reloadButton.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.activityIndicator startAnimating];
    }];
}

- (void)stopLoadingIndicators{
    if (self.progressManager) return; // progress manager is taking care of loading indication
    // stop activity indicator
    if (![self.activityIndicator isAnimating]) return;
    [UIView animateWithDuration:0.2 animations:^{
        self.reloadButton.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

- (BOOL)shouldAllowNavigationToURL:(NSURL *)urlToLoad{
    if ([[urlToLoad absoluteString] hasPrefix:@"sms:"]) {
        [[UIApplication sharedApplication] openURL:urlToLoad];
        return NO;
    }
    
    if ([[urlToLoad absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
        [[urlToLoad absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
        [[urlToLoad absoluteString] hasPrefix:@"http://phobos.apple.com/"] ||
        [[urlToLoad absoluteString] hasSuffix:@".vcf"]) {
        [[UIApplication sharedApplication] openURL:urlToLoad];
        return NO;
    }
    
    NSString *urlString = [urlToLoad absoluteString];
    if ([urlString hasPrefix:@"http://www.justyo.co/"] || [urlString hasPrefix:@"http://justyo.co/"]) {
        
        if (![[YoApp currentSession] isLoggedIn]) {
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo" desciption:NSLocalizedString(@"Please signup or login", nil)];
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil) tapBlock:nil]];
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
            return NO;
        }
        
        if ([urlString hasPrefix:@"http://www.justyo.co/h"]) {
            NSString *hashtag = [[urlToLoad absoluteString] stringByReplacingOccurrencesOfString:@"http://justyo.co/h/" withString:@""];
            hashtag = [hashtag stringByReplacingOccurrencesOfString:@"http://www.justyo.co/h/" withString:@""];
            hashtag = [hashtag stringByReplacingOccurrencesOfString:@"/" withString:@""];
            hashtag = [hashtag uppercaseString];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:MakeString(@"Yo://%@", hashtag)]];
            
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:MakeString(@"Yo'd hashtag: %@!", hashtag) desciption:nil];
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil) tapBlock:nil]];
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
            return NO;
        }
        
        if ([urlString hasPrefix:@"http://www.justyo.co/share/"] || [urlString hasPrefix:@"http://justyo.co/share/"]) {
            //NSRange rangeOfUsername = [url.lowercaseString rangeOfString:username.lowercaseString];
            
            NSString *shareContent = [urlString stringByReplacingOccurrencesOfString:@"http://justyo.co/share/" withString:@""];
            shareContent = [shareContent stringByReplacingOccurrencesOfString:@"http://www.justyo.co/share/" withString:@""];
            NSString *serviceName = [shareContent substringToIndex:[shareContent rangeOfString:@"/"].location];
            serviceName = [serviceName stringByReplacingOccurrencesOfString:@" " withString:@""];
            serviceName = [serviceName stringByReplacingOccurrencesOfString:@"/" withString:@""];
            
            NSString *serviceDescripton = [shareContent stringByReplacingOccurrencesOfString:serviceName withString:@""];
            serviceDescripton = [serviceDescripton stringByReplacingOccurrencesOfString:@" " withString:@""];
            serviceDescripton = [serviceDescripton stringByReplacingOccurrencesOfString:@"/" withString:@""];
            serviceDescripton = [serviceDescripton stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
            
            if (!serviceName.length) return NO; // safety check
            
            NSString *shareText = MakeString(NSLocalizedString(@"Check out this Yo service: %@", nil), serviceName);
            if (serviceDescripton.length) shareText = [shareText stringByAppendingString:MakeString(@" - %@", serviceDescripton)];
            
            NSArray *sharingItems = @[shareText, [NSURL URLWithString:MakeString(@"http://justyo.co/%@", serviceName)]];
            
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
            [self presentViewController:activityController animated:YES completion:nil];
            return NO;
        }
        
        NSString *username = [[urlToLoad absoluteString] stringByReplacingOccurrencesOfString:@"http://justyo.co/" withString:@""];
        username = [username stringByReplacingOccurrencesOfString:@"http://www.justyo.co/" withString:@""];
        username = [username stringByReplacingOccurrencesOfString:@"l/" withString:@""];
        username = [username stringByReplacingOccurrencesOfString:@"/" withString:@""];
        username = [username uppercaseString];
        
        [[YoManager sharedInstance] yo:username completionHandler:nil];
        
        //NSString *html = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        
        UIImage *shareImage = [YoShareSheet yoBrandGraphicFormessage:MakeString(@"%@ Yo", username) purpleTop:YES];
        
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Subscribed!", nil)
                                                    image:shareImage
                                               desciption:NSLocalizedString(@"Share this awesome service with others! Swipe left in main screen to unsubscribe.", nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Done", nil) tapBlock:nil]];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Share", nil) tapBlock:^{
            NSArray *sharingItems = nil;
            
            WhatsAppMessage *whatsappMsg = [[WhatsAppMessage alloc] initWithMessage:MakeString(NSLocalizedString(@"Just subscribed to get Yo'd from %@! Yo them at %@", nil), username, urlString) forABID:nil];
            
            JBWhatsAppActivity *whatsAppActivity = [[JBWhatsAppActivity alloc] init];
            
            if (shareImage) {
                sharingItems = @[MakeString(NSLocalizedString(@"Just subscribed to get Yo'd from %@! Yo them at", nil), username), urlString, shareImage, whatsappMsg];
            }
            else {
                sharingItems = @[MakeString(NSLocalizedString(@"Just subscribed to get Yo'd from %@! Yo them at", nil), username), urlString, whatsappMsg];
            }
            
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:@[whatsAppActivity]];
            [self presentViewController:activityController animated:YES completion:nil];
            
            [YoAnalytics logEvent:YoEventSharedService withParameters:@{YoParam_USERNAME:username?:@"no_username"}];
        }]];
        
        [YoAnalytics logEvent:YoEventSubscribedToService withParameters:@{YoParam_USERNAME:username?:@"no_username"}];
        
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
        
        return NO;
    }
    else if (![[urlToLoad scheme] hasPrefix:@"http"]) {
        [[UIApplication sharedApplication] openURL:urlToLoad];
    }
    
    return YES;
}

- (void)updateTitleWithText:(NSString *)text{
    if (![text length]) return;
    
    if (![self.fixedTitle length])
        [self.titleLabel setText:text];
}

#pragma mark - WKUIDelegate

// called when javascript is attempting to open new window
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    // load URL in webview instead of creating new webview
    [webView loadRequest:navigationAction.request];
    return nil;
}

// methods for presenting native UI on behalf of a webpage.

//- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)())completionHandler{
//
//}
//
//- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
//
//}
//
//- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *result))completionHandler{
//
//}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    // this is where we say Allow or Cancel to the navigation request
    NSURL *URLToLoad = [[navigationAction request] URL];
    
    BOOL shouldAllowNavigationRequest = [self shouldAllowNavigationToURL:URLToLoad];
    
    decisionHandler(shouldAllowNavigationRequest?WKNavigationActionPolicyAllow:WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    // this is the response object from querying to URL
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    [self startLoadingIndicators];
    [self togglePageNavigationButtons];
}

//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
//
//}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [self dismissWithCompletionBlock:^{
        [[UIApplication sharedApplication] openURL:self.URL];
    }];
}

//- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
//    // content downloading begun (no action required)
//}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    // content fulling downloaded
    [self stopLoadingIndicators];
    [self updateTitleWithText:webView.title];
    self.URL = webView.URL;
    [self togglePageNavigationButtons];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [self stopLoadingIndicators];
    
    // To avoid getting an error alert when you click on a link
    // before a request has finished loading.
    if ([error code] == NSURLErrorCancelled) {
        [self togglePageNavigationButtons];
        return;
    }
    
    [self dismissWithCompletionBlock:^{
        [[UIApplication sharedApplication] openURL:self.URL];
    }];
}

//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler{
//
//}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    return [self shouldAllowNavigationToURL:request.URL];
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self startLoadingIndicators];
    
    [self togglePageNavigationButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self stopLoadingIndicators];
    
    [self updateTitleWithText:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
    
    self.URL = webView.request.URL;
    
    [self togglePageNavigationButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    // stop activity indicator
    [self stopLoadingIndicators];
    
    // To avoid getting an error alert when you click on a link
    // before a request has finished loading.
    if ([error code] == NSURLErrorCancelled) {
        [self togglePageNavigationButtons];
        return;
    }
    
    [self dismissWithCompletionBlock:^{
        [[UIApplication sharedApplication] openURL:self.URL];
    }];
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
