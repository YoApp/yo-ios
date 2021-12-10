//
//  iOSAcct.h
//  Yo
//
//  Created by Peter Reveles on 1/7/15.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface YoEmailAttachement : NSObject
/*!
 @method     iniWithData:mimeType:fileName:
 @abstract   This methods creates an attachment that can be added when presenting an email controller.
 @discussion
 @param      data   NSData containing the contents of the attachment.  Must not be <tt>nil</tt>.
 @param      mimeType     NSString specifying the MIME type for the attachment, as specified by the IANA
 (http://www.iana.org/assignments/media-types/). Must not be <tt>nil</tt>.
 @param      filename     NSString specifying the intended filename for the attachment.  This is displayed below
 the attachment's icon if the attachment is not decoded when displayed.  Must not be <tt>nil</tt>.
 */
- (instancetype)initWithData:(NSData *)data mimeType:(NSString *)mimeType fileName:(NSString *)filename;

@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSString *filename;

@end

@interface YoiOSAssistant : NSObject

+ (instancetype)sharedInstance;

#pragma mark - 

- (BOOL)canOpenYoAppSettings;

- (void)openYoAppSettings;

#pragma mark - email

- (BOOL)canSendEmail;

- (void)presentEmailControllerWithRecipients:(NSArray *)emails subject:(NSString *)subject body:(NSString *)body resultBlock:(void (^)(MFMailComposeResult emailSent))block;

- (void)presentEmailControllerWithRecipients:(NSArray *)emails subject:(NSString *)subject body:(NSString *)body attachements:(NSArray *)attachements resultBlock:(void (^)(MFMailComposeResult emailSent))block;

#pragma mark - SMS

- (BOOL)canSendSMSText;

/*!
 @method     iniWithData:mimeType:fileName:
 @abstract   This methods presents device default controller for sending SMS
 @discussion If you would like to display Yo custom UI to for user to select contacts user userLiaison -(void)presentYoSMS...
 */
- (void)presentSMSControllerWithRecipients:(NSArray *)phoneNumbers text:(NSString *)text resultBlock:(void (^)(MessageComposeResult result))block;

#pragma mark - 3rd Party Apps

#pragma mark Whats App
- (BOOL)canOpenWhatsApp;

- (void)openWhatsAppToShareText:(NSString *)text;

#pragma mark - Social

- (BOOL)canTweet;

- (void)presentTweetSheetWithText:(NSString *)text image:(UIImage *)image url:(NSURL *)url;

@end
