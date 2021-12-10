//
//  YoProgressView.h
//  Yo
//
//  Created by Peter Reveles on 12/23/14.
//
//

#import <UIKit/UIKit.h>
@class NJKWebViewProgress;
@class WKWebView;

@interface YoProgressViewManager : UIViewController

- (instancetype)initForWKWebView:(WKWebView *)webview;

- (instancetype)initForUIWebView:(UIWebView *)webview;

- (instancetype)initForNSURLConnection:(NSURLConnection *)connection;

// must call in DEALLOC
- (void)terminate;

@end
