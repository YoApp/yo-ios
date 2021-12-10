//
//  iOSAcct.m
//  Yo
//
//  Created by Peter Reveles on 1/7/15.
//
//

#import "YoiOSAssistant.h"
#import <Social/Social.h>

#pragma mark YoEmailAttachment

@interface YoEmailAttachement ()
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filename;
@end

@implementation YoEmailAttachement

- (instancetype)initWithData:(NSData *)data mimeType:(NSString *)mimeType fileName:(NSString *)filename {
    self = [super init];
    if (self) {
        _data = data;
        _mimeType = mimeType;
        _filename = filename;
    }
    return self;
}
@end

#pragma mark iOSAcct

@interface YoiOSAssistant () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
@property (nonatomic, copy) void (^afterEmailCompletionBlock)(MFMailComposeResult emailSent);
@property (nonatomic, strong) NSDictionary *lastEmailInfo;

@property (nonatomic, copy) void (^afterSMSTextCompletionBlock)(MessageComposeResult result);
@end

@implementation YoiOSAssistant

+ (instancetype)sharedInstance{
    static YoiOSAssistant *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark -

- (BOOL)canOpenYoAppSettings {
    BOOL canOpenYoAppSettings = NO;
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        canOpenYoAppSettings = YES;
    }
    return canOpenYoAppSettings;
}

- (void)openYoAppSettings {
    if ([self canOpenYoAppSettings]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else {
        DDLogWarn(@"Error: Attempted to open settings when opening settings is unavailble");
    }
}

#pragma mark - 3rd Party Apps

#pragma mark Whats App

- (BOOL)canOpenWhatsApp {
    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=Test"];
    NSURL * whatsappURL = [NSURL URLWithString:[urlWhats stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return [[UIApplication sharedApplication] canOpenURL: whatsappURL];
}

- (void)openWhatsAppToShareText:(NSString *)text {
    NSString * urlWhats = [NSString stringWithFormat:@"whatsapp://send?text=%@",text];
    NSURL * whatsappURL = [NSURL URLWithString:[urlWhats stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
    }
}

#pragma mark - Phone

- (BOOL)canSendSMSText {
    BOOL canSendText = [MFMessageComposeViewController canSendText];
    return canSendText;
}

- (void)presentSMSControllerWithRecipients:(NSArray *)phoneNumbers
                                      text:(NSString *)text
                               resultBlock:(void (^)(MessageComposeResult result))block
{
    if (![self canSendSMSText]) {
        if (block) block(MessageComposeResultFailed);
        return;
    }
    
    if (![NSThread mainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentSMSControllerWithRecipients:phoneNumbers
                                                text:text
                                         resultBlock:block];
        });
        return;
    }
    
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]) {
        if ([text length]) controller.body = text;
        if ([phoneNumbers count]) controller.recipients = phoneNumbers;
        controller.messageComposeDelegate = self;
        self.afterSMSTextCompletionBlock = block;
        [[APPDELEGATE topVC] presentViewController:controller animated:YES completion:nil];
    }
    else {
        if (block) block(MessageComposeResultFailed);
    }
}

#pragma mark MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    __weak YoiOSAssistant *weakself = self;
    [controller dismissViewControllerAnimated:YES completion:^{
        if (result == MessageComposeResultCancelled) {
            [Flurry logEvent:@"SMS Canceled"
              withParameters:@{@"recipients_count":@(controller.recipients.count)}
                       timed:YES];
        }
        else if (result == MessageComposeResultFailed) {
            [Flurry logEvent:@"SMS Failed"
              withParameters:@{@"recipients_count":@(controller.recipients.count)}
                       timed:YES];
        }
        else if (result == MessageComposeResultSent) {
            [Flurry logEvent:@"SMS Sent"
              withParameters:@{@"recipients_count":@(controller.recipients.count)}
                       timed:YES];
        }
        if (weakself.afterSMSTextCompletionBlock) {
            weakself.afterSMSTextCompletionBlock(result);
            weakself.afterSMSTextCompletionBlock = nil;
        }
    }];
}

#pragma mark - Email

- (BOOL)canSendEmail {
    return [MFMailComposeViewController canSendMail];
}

- (void)presentEmailControllerWithRecipients:(NSArray *)emails subject:(NSString *)subject body:(NSString *)body resultBlock:(void (^)(MFMailComposeResult emailSent))block {
    [self presentEmailControllerWithRecipients:emails subject:subject body:body attachements:nil resultBlock:block];
}

- (void)presentEmailControllerWithRecipients:(NSArray *)emails subject:(NSString *)subject body:(NSString *)body attachements:(NSArray *)attachements resultBlock:(void (^)(MFMailComposeResult emailSent))block {
    if (![self canSendEmail]) {
        if (block) block(MFMailComposeResultFailed);
        //        [UIAlertView showWithTitle:NSLocalizedString(@"NO EMAIL ACCOUNTS", nil)
        //                           message:nil
        //                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
        //                 otherButtonTitles:nil
        //                          tapBlock:nil];
        return;
    }
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    NSString *systemVersion = [currentDevice systemVersion];
    
    NSArray *languageArray = [NSLocale preferredLanguages];
    NSString *language = [languageArray objectAtIndex:0];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *country = [locale localeIdentifier];
    NSString *username = [[YoUser me] username];
    username = username.length > 0 ? username : @"N/A";
    
    NSString *appVersion = [[NSBundle mainBundle]
                            objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    NSString *deviceSpecs =
    [NSString stringWithFormat:@"------------\niOS - %@ - %@ - %@ - %@ - %@ - U: %@ - %@",
     model, systemVersion, language, country, appVersion, username, [YOUDID value]];
    
    NSString *bodyWithSpecs = [NSString stringWithFormat:@"%@\n\n\n--\n\n%@", body, deviceSpecs];
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    if ([emails count]) [controller setToRecipients:emails];
    if ([subject length])[controller setSubject:subject];
    if ([bodyWithSpecs length]) [controller setMessageBody:bodyWithSpecs isHTML:NO];
    
    BOOL hasAttachement = NO;
    for (YoEmailAttachement *attachment in attachements) {
        [controller addAttachmentData:attachment.data mimeType:attachment.mimeType fileName:attachment.filename];
        hasAttachement = YES;
    }
    
    self.lastEmailInfo = @{@"subject":subject, @"recipients":emails, @"body":bodyWithSpecs};
    self.afterEmailCompletionBlock = block;
    
    [[APPDELEGATE topVC] presentViewController:controller animated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    
    self.lastEmailInfo = nil;
    
    __weak YoiOSAssistant *weakSelf = self;
    [controller dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.afterEmailCompletionBlock) {
            weakSelf.afterEmailCompletionBlock(result);
            weakSelf.afterEmailCompletionBlock = nil;
        }
    }];
}

#pragma mark - Social

- (BOOL)canTweet {
    BOOL canTweet = [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
    return canTweet;
}

- (void)presentTweetSheetWithText:(NSString *)text image:(UIImage *)image url:(NSURL *)url {
    
    if ([self canTweet]) {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        if ([text length]) [tweetSheet setInitialText:text];
        if (image) [tweetSheet addImage:image];
        if (url) [tweetSheet addURL:url];
        
        [APPDELEGATE.topVC presentViewController:tweetSheet animated:YES completion:nil];
    }
    else {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo" desciption:NSLocalizedString(@"Please connect to Twitter in Settings -> Twitter", nil)];
        
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Dismiss", nil) tapBlock:nil]];
        if ([self canOpenYoAppSettings]) {
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"open settings", nil).capitalizedString tapBlock:^{
                // redisplay alert?
                [self openYoAppSettings];
            }]];
        }
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}

@end
