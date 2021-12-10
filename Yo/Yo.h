//
//  Yo.h
//  Yo
//
//  Created by Peter Reveles on 2/9/15.
//
//

#import <Foundation/Foundation.h>
#import "YOConstants.h"
#import "FLAnimatedImage.h"
@class CLLocation;
#import "YoNotificationObjectProtocol.h"

#define Yo_SENDER_KEY @"sender"
#define Yo_ID_KEY @"yo_id"
#define Yo_ORIGIN_YO_ID_KEY @"origin_yo_id"
#define Yo_SOUND_KEY @"sound"
#define Yo_ACTION_KEY @"action"
#define Yo_ORIGIN_KEY @"origin"
#define Yo_DISPLAY_TEXT_KEY @"alert"
#define Yo_LOCATION_KEY @"location"
#define Yo_LINK_KEY @"link"
#define YoLinkCoverKey @"cover"

#define Yo_CATEGORY_KEY @"category"
#define Yo_InAppDisplayText_KEY @"header"
#define Yo_CREATION_DATE_KEY @"created_at"

#define Yo_STATUS_KEY @"status"

#define kYoCategoryJustYo @"default_yo" // To support old Yo versions
#define kYoCategoryLocation @"location_yo"
#define kYoCategoryLink @"link_yo"
#define kYoCategoryPhoto @"photo_yo"

#define kYoCategoryServiceYo @"default_yo_service"
#define kYoCategoryServiceLocation @"location_yo_service"
#define kYoCategoryServiceLink @"link_yo_service"
#define kYoCategoryServicePhoto @"photo_yo_service"

#define YoStatusReceivedKey @"received"
#define YoStatusReadKey @"read"
#define YoStatusDismissedKey @"dismissed"

/* // sample payload
 {
 aps =     {
 alert = "From PETERREVEL";
 category = "Response_Category";
 "content-available" = 1;
 sound = "yo.mp3";
 };
 header = "From PETERREVEL";
 sender = PETERREVEL;
 sound = "yo.mp3";
 "yo_id" = 54d91f5a094fe2000d7349a4;
 }
*/

typedef NS_ENUM(NSUInteger, YoStatus) {
    YoStatusReceived,
    YoStatusRead,
    YoStatusDismissed,
};

@interface Yo : NSObject <YoNotificationObjectProtocal>

- (instancetype)initWithPushPayload:(id)payload;

/**
 Returns a dictionary representation of this Yo which can be used to reconstruct
 a Yo object.
 */
@property (nonatomic, readonly) NSDictionary *payload;
@property (nonatomic, readonly) NSString *yoID;
@property (nonatomic, readonly) NSString *originYoID;
@property (nonatomic, readonly) NSString *displayText;
@property (nonatomic, assign) YoStatus status;
@property (nonatomic, readonly) NSString *inAppDisplayText;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSString *action;
@property (nonatomic, readonly) NSString *soundFileName;
@property (nonatomic, readonly) NSString *senderUsername;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) UIImage *image; // @or: prefetched image to show it faster
@property (nonatomic, strong) FLAnimatedImage *animatedImage; // @or: prefetched image to show it faster
@property (nonatomic, readonly) NSString *originUsername;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSURL *coverURL;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSString *category;
@property (nonatomic, readonly) BOOL isFromService;
@property (nonatomic, assign) BOOL isGroupYo;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) YoUser *senderObject;

@property (nonatomic, strong) NSString *leftDeepLink;
@property (nonatomic, strong) NSString *rightDeepLink;

@property (nonatomic, strong) NSURL *thumbnailURL;

@property (nonatomic, assign) BOOL openedFromPush;

/**
 For a Yo with a location this will read the place name.
 */
@property (nonatomic, strong) NSString *text;
#pragma Mark - Utility

- (BOOL)isEqualToYo:(Yo *)otherYo;

- (void)refresh;

@end
