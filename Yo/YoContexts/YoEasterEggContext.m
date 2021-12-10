//
//  YoEasterEggContext.m
//  Yo
//
//  Created by Or Arbel on 6/17/15.
//
//

#import "YoEasterEggContext.h"
#import "FLAnimatedImage.h"
#import <FXBlurView/FXBlurView.h>

@interface YoEasterEggContext () <UIWebViewDelegate>

@property(nonatomic, strong) NSString *titleText;
@property(nonatomic, strong) NSString *statusBarText;
@property(nonatomic, strong) NSString *sentText;
@property(nonatomic, strong) NSString *urlString;

@property(nonatomic, strong) UIImageView *bgImageView;
@property(nonatomic, strong) FLAnimatedImageView *imageView;
@property(nonatomic, strong) UIWebView *webView;

@end

@implementation YoEasterEggContext

- (void)fetchEasterEgg {
    [[YoApp currentSession] fetchEasterEggWithCompletionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
        NSDictionary *easterEgg = responseObject[@"easter_egg"];
        self.titleText = easterEgg[@"title"];
        self.statusBarText = easterEgg[@"status_bar_text"];
        self.sentText = easterEgg[@"sent_text"];
        self.urlString = easterEgg[@"url"];
        if (self.urlString && [NSURL URLWithString:self.urlString]) {
            self.isLoaded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationFetchedEasterEgg object:nil];
        }
        else {
            self.isLoaded = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationEasterEggFailed object:nil];
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

- (BOOL)alwaysShowBanner {
    return YES;
}

- (BOOL)isLabelGlowing {
    return YES;
}

- (UIView *)backgroundView {
    if ([@[@"jpg", @"png", @"gif"] containsObject:[[self.urlString pathExtension] lowercaseString]]) {
        
        
        if ( ! self.view) {
            
            self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            
            self.bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
            self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
            [self.view addSubview:self.bgImageView];
            
            self.imageView = [[FLAnimatedImageView alloc] initWithFrame:self.view.bounds];
            self.imageView.contentMode = UIViewContentModeScaleAspectFit;
            self.imageView.backgroundColor = [UIColor clearColor];
            [self.view addSubview:self.imageView];
            
            if ([[[self.urlString pathExtension] lowercaseString] isEqualToString:@"gif"]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.urlString]];
                    if (data) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                            self.bgImageView.image = [image.posterImage blurredImageWithRadius:40 iterations:3 tintColor:[UIColor blackColor]];
                            self.imageView.animatedImage = image;
                        });
                    }
                    else {
                        self.isLoaded = NO;
                        [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationEasterEggFailed object:nil];
                    }
                });

            }
            else {
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
                __weak YoEasterEggContext *weakSelf = self;
                [self.imageView setImageWithURLRequest:request
                                      placeholderImage:nil
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                   weakSelf.bgImageView.image = [image blurredImageWithRadius:40 iterations:3 tintColor:[UIColor blackColor]];
                                                   weakSelf.imageView.image = image;
                                               }
                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                   [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationEasterEggFailed object:nil];
                                               }];
            }
        }
        return self.view;
    }
    else {
        if ( ! self.webView) {
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            self.webView.delegate = self;
            self.webView.scalesPageToFit = YES;
            self.webView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
            self.webView.opaque = NO;
        }
        return self.webView;
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationEasterEggFailed object:nil];
}

+ (NSString *)contextID
{
    return @"easter_egg";
}

- (NSString *)getFirstTimeYoText {
    return @"📷 Yo Photo";
}

@end
