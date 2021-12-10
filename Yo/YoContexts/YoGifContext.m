//
//  YoGifContext.m
//  Yo
//
//  Created by Or Arbel on 7/6/15.
//
//

#import "YoGifContext.h"
#import "FLAnimatedImage.h"
#import <FXBlurView/FXBlurView.h>
#import "YoPlaceholderView.h"
#import "YGCGif.h"

typedef NS_ENUM(NSUInteger, YoGCLoadingState) {
    YoGCLoadingStateInitial,
    YoGCLoadingStateLoading,
    YoGCLoadingStateLoaded,
    YoGCLoadingStateError
};

@interface YoGifContext ()

@property(nonatomic, strong) NSString *titleText;
@property(nonatomic, strong) NSString *statusBarText;
@property(nonatomic, strong) NSString *sentText;
@property(nonatomic, strong) NSString *urlString;

@property(nonatomic, strong) UIImageView *bgImageView;
@property(nonatomic, strong) FLAnimatedImageView *imageView;
@property(nonatomic, strong) UIImageView *attributionImageView;

@property(nonatomic, strong) NSArray *gifURLs;
@property(nonatomic, strong) NSMutableArray *gifs; // of type YGCGif

@property(nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong, readwrite) YoPlaceholderView *placeholder;
@property (nonatomic, assign) YoGCLoadingState loadingState;
@end

@implementation YoGifContext

- (id)init {
    if (self = [super init]) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.showsTouchWhenHighlighted = YES;
        [button setImage:[UIImage imageNamed:@"yo_giphy_refresh_icon"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0, 0, 50, 50);
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        button.layer.cornerRadius = button.width / 2.0;
        button.layer.masksToBounds = YES;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowRadius = 3.0f;
        button.layer.shadowOpacity = 0.5f;
        self.button = button;
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            // already active - fetch immediately
            [self fetch];
        }
        else {
            __weak YoGifContext *weakSelf = self;
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note)
             {
                 __strong YoGifContext *strongSelf = weakSelf;
                 [strongSelf fetch];
             }];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isLabelGlowing {
    return YES;
}

- (void)fetchDataIfNeeded {
    [self fetch];
}

- (void)fetch {
    if (self.loadingState == YoGCLoadingStateLoading) {
        // already fetching
        return;
    }
    
    self.loadingState = YoGCLoadingStateLoading;
    
    [[YoApp currentSession] fetchWebContextWithPath:@"giphy"
                                  completionHandler:^(YoResult result, NSInteger statusCode, id responseObject)
    {
        
        if (result == YoResultFailed) {
            self.loadingState = YoGCLoadingStateError;
            return;
        }
        
        NSDictionary *payload = responseObject[@"payload"];
        
        NSString *titleText = payload[@"title"];
        NSString *statusBarText = payload[@"status_bar_text"];
        NSString *sentText = payload[@"sent_text"];
        NSArray *gifURLs = payload[@"urls"];
        
        NSString *phrase = payload[@"phrase"];
        if (phrase != nil) {
            statusBarText = MakeString(@"Tap to name to send %@", phrase);
        }
        
        NSMutableArray *gifs = [[NSMutableArray alloc] initWithCapacity:gifURLs.count];
        
        void (^configureForCurrentGifBatch)() = ^() {
            self.titleText = titleText;
            self.statusBarText = statusBarText;
            self.sentText = sentText;
            self.gifURLs = gifURLs;
        };
        
        for (NSString *gifURLString in gifURLs) {
            NSURL *gifURL = [NSURL URLWithString:gifURLString];
            NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:gifURL
                                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        YGCGif *gif = [[YGCGif alloc] init];
                        gif.image = image;
                        gif.URL = gifURL;
                        [gifs addObject:gif];
                        
                        if (gifs.count == 1) {
                            // our first image was loaded
                            configureForCurrentGifBatch();
                            self.currentIndex = 0; // reset index
                            self.gifs = gifs;
                            
                            self.placeholder.hidden = YES;
                            [self displayGif:gif];
                            
                            self.loadingState = YoGCLoadingStateLoaded;
                            // this is werid place for this.
                            // My thinking is: as long as you've let the first
                            // gif load it'll be OK if you decide to refetch.
                            // this block is the only place something could go wrong
                            // if we reconfigure for a new batch of gifs.
                        }
                    }
                    else {
                        DDLogError(@"Failed to fetch gif: %@", gifURL);
                    }
                });
            }];
            [dataTask resume];
        }
    }];
}

- (void)next {
    if (self.gifs.count == 0) {
        return;
    }
    
    self.currentIndex = (self.currentIndex + 1) % self.gifs.count;
    YGCGif *currentGif = [self.gifs objectAtIndex:self.currentIndex];
    DDLogDebug(@"Showing gif: %@", currentGif.URL.absoluteString);
    [self displayGif:currentGif];
}

- (void)displayGif:(YGCGif *)gif {
    FLAnimatedImage *animatedImage = gif.image;
    if (animatedImage == nil) {
        self.bgImageView.image = nil;
    }
    else {
        self.bgImageView.image = [animatedImage.posterImage blurredImageWithRadius:40 iterations:3 tintColor:[UIColor blackColor]];
    }
    self.imageView.animatedImage = animatedImage;
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

- (void)contextDidAppear {
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (UIView *)backgroundView {
    if (self.view == nil) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                             0,
                                                             [UIScreen mainScreen].bounds.size.width,
                                                             [UIScreen mainScreen].bounds.size.height)];
        
        self.bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:self.bgImageView];
        
        self.imageView = [[FLAnimatedImageView alloc] initWithFrame:self.view.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.imageView];
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource: @"thinking_gif" ofType: @"gif"];
        NSData *gifData = [NSData dataWithContentsOfFile:filePath];
        FLAnimatedImage *loadingGif = [FLAnimatedImage animatedImageWithGIFData:gifData];
        YoPlaceholderView *placeholderView = [[YoPlaceholderView alloc] initWithFrame:self.view.frame
                                                                                title:@"Thinking of a Good Gif"
                                                                              message:nil
                                                                        animatedImage:loadingGif
                                                                          buttonTitle:nil
                                                                         buttonAction:nil];
        placeholderView.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:placeholderView];
        _placeholder = placeholderView;
        
        UIImage *image = [UIImage imageNamed:@"PoweredBy_200px-Black_HorizText"];
        self.attributionImageView = [[UIImageView alloc] initWithImage:image];
        self.attributionImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.attributionImageView.size = CGSizeMake(100, 20);
        self.attributionImageView.bottom = self.imageView.bottom;
        self.attributionImageView.left = self.view.left;
        [self.view addSubview:self.attributionImageView];
    }
    return self.view;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    if (self.gifs.count == 0) {
        block(nil, NO);
        return;
    }
    
    YGCGif *currentGif = [self.gifs objectAtIndex:self.currentIndex];
    block(@{@"link": currentGif.URL.absoluteString}, NO);
}

+ (NSString *)contextID
{
    return @"gif";
}

- (NSString *)getFirstTimeYoText {
    return @"📷 Yo Gif";
}


@end
