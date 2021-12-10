//
//  YoShareSheet.m
//  Yo
//
//  Created by Peter Reveles on 11/24/14.
//
//

#import "YoShareSheet.h"
#import "YoThisExtensionController.h"
#import "YOFacebookManager.h"
#import <Social/Social.h>
#import "Yo_Extensions.h"
#import <QuartzCore/QuartzCore.h>
#import <JBWhatsAppActivity/JBWhatsAppActivity.h>

@interface YoShareSheet () <YoTableViewSheetDelegate>
@property (nonatomic, strong) YoThisExtensionController *sheet;
@property (nonatomic, strong) YoShareSheet *keepAlive;
@end

@implementation YoShareSheet

#pragma mark - Life

- (instancetype)initForURL:(NSURL *)url message:(NSString *)message image:(UIImage *)image{
    self = [super init];
    if (self) {
        _sheet = nil;
        [self setupForURL:url message:message image:image];
    }
    return self;
}

- (void)show{
    if (!self) return;
    
    UIViewController *topViewController = [APPDELEGATE topVC];
    [self.sheet showOnView:topViewController.view];
    self.keepAlive = self;
}

- (void)dealloc {
    _keepAlive = nil;
}

- (void)setupForURL:(NSURL *)url message:(NSString *)message image:(UIImage *)image{
    YoThisExtensionController *sheet = [YoThisExtensionController new];
    sheet.delegate = self;
    
    __weak UIViewController *topViewController = [APPDELEGATE topVC];
    __weak YoShareSheet *_weakSelf = self;
    
    // all actions call this before proceeding to share
    void (^dissmissSheet)() = ^void(){
        [_weakSelf.sheet dissmiss];
        _weakSelf.keepAlive = nil;
    };
    
    BOOL didAddShareToSinaOrTencent = NO;
    
    // share on SinaWeibo
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]){
        YoTableViewAction *shareOnSinaWeibo = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"SinaWeibo", nil) tapBlock:^{
            dissmissSheet();
            
            SLComposeViewController *sinaWeiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
            
            [sinaWeiboSheet setInitialText:MakeString(@"Yo %@ ", url)];
            [sinaWeiboSheet addImage:image];
            [sinaWeiboSheet addURL:url];
            
            [topViewController presentViewController:sinaWeiboSheet animated:YES completion:nil];
        }];
        
        [sheet addAction:shareOnSinaWeibo];
        didAddShareToSinaOrTencent = YES;
    }
    // share on TencentWeibo
    if (IS_OVER_IOS(7.0) && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]){
        YoTableViewAction *shareOnTencentWeibo = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"TencentWeibo", nil) tapBlock:^{
            dissmissSheet();
            
            SLComposeViewController *tencentWeiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
            
            [tencentWeiboSheet setInitialText:MakeString(@"Yo %@ ", url)];
            [tencentWeiboSheet addImage:image];
            [tencentWeiboSheet addURL:url];
            
            [topViewController presentViewController:tencentWeiboSheet animated:YES completion:nil];
        }];
        
        [sheet addAction:shareOnTencentWeibo];
        didAddShareToSinaOrTencent = YES;
    }
    
    if (!didAddShareToSinaOrTencent) {
        // share on Facebook
        YoTableViewAction *shareOnFacebook = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Facebook", nil) tapBlock:^{
            dissmissSheet();
            [YOFacebookManager shareURL:url image:image];
        }];
        
        [sheet addAction:shareOnFacebook];
    }
    
    // share on the twitter
    YoTableViewAction *shareOnTwitter = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"Twitter", nil) tapBlock:^{
        dissmissSheet();
        
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
            [tweetSheet setInitialText:message];
            [tweetSheet addImage:image];
            [tweetSheet addURL:url];
            
            [topViewController presentViewController:tweetSheet animated:YES completion:nil];
        }
        else {
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                                   desciption:NSLocalizedString(@"Please connect to Twitter in Settings -> Twitter", nil)];
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
            if ([[YoiOSAssistant sharedInstance] canOpenYoAppSettings]) {
                [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"open settings", nil).capitalizedString tapBlock:^{
                    [[YoiOSAssistant sharedInstance] openYoAppSettings];
                }]];
            }
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
        }
    }];
    
    [sheet addAction:shareOnTwitter];
    
    // Share on WhatsApp
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://"]]) {
        YoTableViewAction *shareOnWhatsApp = [[YoTableViewAction alloc] initWithTitle:@"WhatsApp" tapBlock:^{
            dissmissSheet();
            
            NSString *whatsAppMessage = [message stringByAppendingString:MakeString(@" [%@]", url.absoluteString)];
            
            whatsAppMessage = [whatsAppMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSString *whatsAppDeepLink = MakeString(@"whatsapp://send?text=%@", whatsAppMessage);
            
            // Open the URL with Chrome.
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:whatsAppDeepLink]];
        }];
        
        [sheet addAction:shareOnWhatsApp];
    }
    
    // present apple share UI
    YoTableViewAction *openAppleShare = [[YoTableViewAction alloc] initWithTitle:NSLocalizedString(@"More", nil) tapBlock:^{
        // cases
        dissmissSheet();
        
        NSMutableArray *sharingItems = [[NSMutableArray alloc] initWithCapacity:5];
        
        WhatsAppMessage *whatsappMsg = [[WhatsAppMessage alloc] initWithMessage:message forABID:nil];
        
        JBWhatsAppActivity *whatsAppActivity = [[JBWhatsAppActivity alloc] init];
        
        
        if (image) {
            [sharingItems addObject:image];
        }
        if (message) {
            [sharingItems addObject:message];
        }
        if (url) {
            [sharingItems addObject:url.bitlyWraped]; // because facebook blocks us
        }
        if (whatsappMsg) {
            [sharingItems addObject:whatsappMsg];
        }
        
        UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:sharingItems
                                          applicationActivities:@[whatsAppActivity]];
        
        [topViewController presentViewController:activityViewController
                                        animated:YES
                                      completion:nil];
    }];
    
    [sheet addAction:openAppleShare];
    
    self.sheet = sheet;
}

#pragma mark - Class Methods

+ (UIImage *)yoBrandGraphicFormessage:(NSString *)message purpleTop:(BOOL)purpleTop{
    if (![message length]) return nil;
    
    NSArray *words = [message componentsSeparatedByString:@" "];
    
    if (!words) return nil;
    
    CGSize sizeOfGraphic = CGSizeMake(320.0f, [words count]*89.0f); // cell height
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(sizeOfGraphic, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(sizeOfGraphic);
    
    NSUInteger y_coordinate = 0.0;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, sizeOfGraphic.width, sizeOfGraphic.height)];
    for (NSString *word in words) {
        UIView *yoCell = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y_coordinate, 320.0f, 89.0f)];
        int row = (y_coordinate % 88);
        if (purpleTop) row -=1;
        yoCell.backgroundColor = [YoShareSheet colorForRow:row];
        y_coordinate += yoCell.height;
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 89.0f)];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:30];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.text = word;
        [yoCell addSubview:textLabel];
        [container addSubview:yoCell];
    }
    
    [container.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //NSData * data = UIImagePNGRepresentation(image);
    
    return image;
}

+ (UIImage *)yoBrandGraphicFormessage:(NSString *)message{
    return [self yoBrandGraphicFormessage:message purpleTop:YES];
}

+ (UIColor *)colorForRow:(NSUInteger)row {
    switch (row % 8) {
        case 0:
            return [UIColor colorWithHexString:TURQUOISE];
        case 1:
            return [UIColor colorWithHexString:EMERALD];
        case 2:
            return [UIColor colorWithHexString:PETER];
        case 3:
            return [UIColor colorWithHexString:ASPHALT];
        case 4:
            return [UIColor colorWithHexString:GREEN];
        case 5:
            return [UIColor colorWithHexString:SUNFLOWER];
        case 6:
            return [UIColor colorWithHexString:BELIZE];
        case 7:
            return [UIColor colorWithHexString:WISTERIA];
        default:
            return [UIColor colorWithHexString:WISTERIA];
    }
}

#pragma mark - YoSheetControllerDelegate

- (void)yoTableViewSheetDidDissmiss {
    _keepAlive = nil;
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
