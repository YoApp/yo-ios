//
//  YoWebBrowserController.h
//  Yo
//
//  Created by Peter Reveles on 12/1/14.
//
//

#import <UIKit/UIKit.h>
#import "YoBaseViewController.h"
@class Yo;

@protocol YoWebBroswersDelegate <NSObject>

- (void)yoWebBrowserDidClose;

@end

@interface YoWebBrowserController : YoBaseViewController

@property (strong, nonatomic) Yo* sourceYo;

@property (weak, nonatomic) IBOutlet UIView *webContainerView;

- (instancetype)initWithUrl:(NSURL*)url;

- (instancetype)initWithUrl:(NSURL *)url fixedTitle:(NSString *)title;

//** Yo - the yo from which this URL is sourced */
- (instancetype)initWithUrl:(NSURL *)url forYo:(Yo *)yo;

@property (nonatomic, readonly) NSURL *URL;

- (void)shouldDisplayDismissButtonWithTitle:(NSString *)dismissButtonTitle;
- (void)shouldDisplayNextButton;

@property (nonatomic, weak) id <YoWebBroswersDelegate> delegate;

@end
