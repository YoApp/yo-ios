#import <AVFoundation/AVFoundation.h>
#import "YoMainController.h"

@class YoMainNavigationController;

@interface YOAppDelegate : NSObject <UIApplicationDelegate> {

}

@property(nonatomic, strong) NSURL *oauthURL;
@property (nonatomic, strong) NSString *pushToken;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) YoMainNavigationController *navigationController;
@property (nonatomic, strong) YoMainController *mainController;

- (void)playSound:(NSString *)filenameWithOutMp3Ext;

- (UIViewController *)topVC;

- (void)registerForPushNotifications;
- (BOOL)isRegisteredForPushNotifications;
- (BOOL)hasInternet;
- (void)checkInternet;
- (void)presentAuthorizationController:(NSURL *)url;

@end
