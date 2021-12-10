//
//  YoWebContext.m
//  Yo
//
//  Created by Or Arbel on 7/6/15.
//
//

#import "YoWebContext.h"

@interface YoWebContext () <UIWebViewDelegate>

@property(nonatomic, strong) NSString *titleText;
@property(nonatomic, strong) NSString *statusBarText;
@property(nonatomic, strong) NSString *sentText;
@property(nonatomic, strong) NSString *urlString;

@property(nonatomic, strong) UIWebView *webView;

@end

@implementation YoWebContext

- (id)init {
    if (self = [super init]) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"R" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(fetch) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0, 0, 50, 50);
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        button.layer.cornerRadius = button.width / 2.0;
        button.layer.masksToBounds = YES;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowRadius = 3.0f;
        button.layer.shadowOpacity = 0.5f;
        self.button = button;
        
    }
    return self;
}

- (void)fetch {
    [[YoApp currentSession] fetchWebContextWithPath:@"meme" completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
        
        NSDictionary *easterEgg = responseObject[@"payload"];
        self.titleText = easterEgg[@"title"];
        self.statusBarText = easterEgg[@"status_bar_text"];
        self.sentText = easterEgg[@"sent_text"];
        self.urlString = easterEgg[@"url"];
        NSURL *url = [NSURL URLWithString:self.urlString];
        if (self.urlString && url) {
            self.isLoaded = YES;
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
            [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationFetchedWebContext object:nil];
        }
        else {
            self.isLoaded = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationWebContextFailed object:nil];
        }
    }];
}

- (NSString *)textForTitleBar {
    return self.titleText;
}

- (NSString *)textForStatusBar {
    return self.statusBarText;
}

- (NSString *)textForSentYo {
    return self.sentText;
}

- (UIView *)backgroundView {
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.webView.opaque = NO;
    return self.webView;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    block(@{@"link": self.urlString}, NO);
}

- (void)contextDidAppear {
    NSURL *url = [NSURL URLWithString:self.urlString];
    if ( ! [url isEqual:self.webView.request.URL]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

#pragma mark - WebView

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogError(@"%@", error);
    self.isLoaded = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationWebContextFailed object:nil];
}

+ (NSString *)contextID
{
    return @"web";
}

- (NSString *)getFirstTimeYoText {
    return @"🔗 Yo Link";
}


@end
