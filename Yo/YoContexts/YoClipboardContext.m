//
//  YoClipboardContext.m
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoClipboardContext.h"
#import "YoImgUploadClient.h"

@interface YoClipboardContext ()
@property (strong, nonatomic) id item;
@end

@implementation YoClipboardContext

- (instancetype)init
{
    return [self initWithClipboardItem:nil];
}

- (instancetype)initWithClipboardItem:(id)item
{
    self = [super init];
    if (self != nil) {
        _item = item;
    }
    return self;
}

- (NSString *)textForStatusBar {
    return @"Tap name to Yo your clipboard";
}

- (NSString *)textForSentYo {
    return @"Sent Yo Clipboard";
    
}
- (UIView *)backgroundView {
    UIView *backgroundView = nil;
    
    if ([self.item isKindOfClass:[UIImage class]]) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.item];
        imageView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        backgroundView = imageView;
    }
    
    if ([self.item isKindOfClass:[NSURL class]]) {
        UIWebView *webView = [[UIWebView alloc] init];
        [webView loadRequest:[NSURLRequest requestWithURL:self.item]];
        backgroundView = webView;
    }
    
    if ([self.item isKindOfClass:[NSString class]]) {
        NSURL *url = [NSURL URLWithString:self.item];
        if (url &&
            ([url.scheme hasPrefix:@"http"] || [url.scheme hasPrefix:@"https"]) &&
            url.host) {
            UIWebView *webView = [[UIWebView alloc] init];
            [webView loadRequest:[NSURLRequest requestWithURL:url]];
            backgroundView = webView;
        }
//        else { // @or: not a url
//            
//            UILabel *label = [self createLabel];
//            label.text = self.item;
//            return label;
//            
//        }
    }
    
    if (backgroundView == nil) {
        UILabel *label = [self createLabel];
        if (self.item == nil) {
            // no content
            label.text = @"Your clipboard is empty..\nGo copy something 😜";
        }
        else {
            // error
            label.text = @"I couln't load your clipboard context.. maybe ecopy something else?";
        }
    }
    
    backgroundView.frame = CGRectMake(0,
                                      0,
                                      [UIScreen mainScreen].bounds.size.width,
                                      [UIScreen mainScreen].bounds.size.height);
    
    return backgroundView;
}

- (UILabel *)createLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    label.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];;
    label.textAlignment = NSTextAlignmentCenter;
    label.minimumScaleFactor = 0.1;
    label.numberOfLines = 0;
    label.textColor = [UIColor whiteColor];
    return label;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    if ([self.item isKindOfClass:[UIImage class]]) {
        [[YoImgUploadClient sharedClient] uploadOptimizedToS3WithImage:self.item
                                                       completionBlock:^(NSString *imageURL, NSError *error)
        {
            NSDictionary *extraParameters = @{@"link": imageURL};
            block(extraParameters, NO);
        }];
    }
    else if ([self.item isKindOfClass:[NSString class]]) {
        NSURL *url = [NSURL URLWithString:self.item];
        if (url &&
            ([url.scheme hasPrefix:@"http"] || [url.scheme hasPrefix:@"https"]) &&
            url.host) {
            NSDictionary *extraParameters = @{@"link": self.item};
            block(extraParameters, NO);
        }
        else {
            block(nil, NO);
        }
    }
    else if ([self.item isKindOfClass:[NSURL class]]) {
        NSDictionary *extraParameters = @{@"link": [(NSURL *)self.item absoluteString]};
        block(extraParameters, NO);
    }
    else {
        block(nil, NO);
    }
}

#pragma mark - Class Methods

+ (BOOL)canPresentItem:(id)item
{
    BOOL canPresent = NO;
    if ([item isKindOfClass:[UIImage class]]) {
        canPresent = YES;
    }
    else if ([item isKindOfClass:[NSURL class]]) {
        canPresent = YES;
    }
    else if ([item isKindOfClass:[NSString class]]) {
        NSURL *url = [NSURL URLWithString:item];
        if (url &&
            ([url.scheme hasPrefix:@"http"] || [url.scheme hasPrefix:@"https"]) &&
            url.host) {
            canPresent = YES;
        }
    }
    return canPresent;
}

+ (NSString *)contextID
{
    return @"clipboard";
}

- (NSString *)getFirstTimeYoText {
    return @"Yo"; // not sure what to put for this one.
}

@end
