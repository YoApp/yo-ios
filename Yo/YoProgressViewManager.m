//
//  YoProgressView.m
//  Yo
//
//  Created by Peter Reveles on 12/23/14.
//
//

#import "YoProgressViewManager.h"
#import <WebKit/WebKit.h>
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>

@interface YoProgressViewManager () <NJKWebViewProgressDelegate>
@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) NJKWebViewProgressView *NJKProgressView;
@property (nonatomic, weak) WKWebView *WKWebview;
@property (nonatomic, weak) UIWebView *UIWebView;
@property (nonatomic, strong) NJKWebViewProgress *NJKProgressManager;
@end

@implementation YoProgressViewManager

- (instancetype)initForWKWebView:(WKWebView *)webview{
    self = [super init];
    if (self) {
        // setup
        _WKWebview = webview;
        [self setup];
        [webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (instancetype)initForUIWebView:(UIWebView *)webview{
    self = [super init];
    if (self) {
        // setup
        _UIWebView = webview;
        [self setup];
        NJKWebViewProgress *NJKProgressManager = [NJKWebViewProgress new];
        webview.delegate = NJKProgressManager;
        NJKProgressManager.progressDelegate = self;
        _NJKProgressManager = NJKProgressManager;
    }
    return self;
}

- (instancetype)initForNSURLConnection:(NSURLConnection *)connection{
    self = [super init];
    if (self) {
        // setup
        [self setup];
    }
    return self;
}

- (void)setup{
    UIView *progressViewID = nil;
    
    if (self.WKWebview) {
        UIProgressView *progressView = [UIProgressView new];
        progressView.progress = 0.0f;
        progressView.progressTintColor = [UIColor colorWithHexString:TURQUOISE];
        progressView.trackTintColor = [UIColor clearColor];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        progressViewID = progressView;
        self.progressView = progressView;
    }
    else if (self.UIWebView) {
        NJKWebViewProgressView *progressView = [NJKWebViewProgressView new];
        progressView.progressBarView.backgroundColor = [UIColor colorWithHexString:TURQUOISE];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        progressView.barAnimationDuration = 0.2;
        progressViewID = progressView;
        self.NJKProgressView = progressView;
    }
    
    if (!progressViewID) return;
    
    progressViewID.alpha = 0.0f;
    
    [self.view addSubview:progressViewID];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(progressViewID);
    
    [self.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[progressViewID]|"
      options:0 metrics:nil views:views]];
    
    [self.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[progressViewID]|"
      options:0 metrics:nil views:views]];
}

- (void)dealloc{
    
}

// must call in DEALLOC
- (void)terminate{
    [self.WKWebview removeObserver:self forKeyPath:@"estimatedProgress"];
}

#pragma mark - UIWebvView

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress{
    [self progressUpdatedTo:progress];
}

- (void)progressUpdatedTo:(CGFloat)progress{
    id progressView = self.progressView?:self.NJKProgressView;
    
    [progressView setAlpha:1.0f];
    [progressView setProgress:progress animated:NO];
    
    if(progress >= 1.0f) {
        [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [progressView setProgress:0.0f animated:NO];
        }];
    }
}

#pragma mark - WKWebView

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.WKWebview) {
        [self progressUpdatedTo:self.WKWebview.estimatedProgress];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
