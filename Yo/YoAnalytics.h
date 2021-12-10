//
//  YoAnalytics.h
//  Yo
//
//  Created by Peter Reveles on 2/18/15.
//
//

#import <Foundation/Foundation.h>
#import "YoAnalyticsEvents.h"

#define YoParam_SHARE_OPTION @"share_option"
#define YoParam_SERVICE_SUBSCRIBED_TO @"service_subscribed_to"
#define YoParam_DID_SEARCH @"searched"
#define YoParam_USER_IDS @"user_ids"
#define YoParam_IS_SERVICE @"is_service"
#define YoParam_IS_CONTACT @"is_contact"
#define YoParam_ROW_NUMBER @"row_number"
#define YoParam_CATEGORY @"category"
#define YoParam_REFERRER @"referrer"
#define YoParam_CONTACTS @"contacts"
#define YoParam_CURRENT_VIEW @"current_view"
#define YoParam_POPUP_ID @"popup_id"
#define YoParam_USER_ALIEN_PHONE_NUMBERS @"user_alien_phone_numbers"
#define YoParam_LINK @"link"
#define YoParam_SENDER_LOCATION @"sender_location"
#define YoParam_IS_ACTIVE @"is_active"
#define YoParam_BOOL_RESULT @"boolean_result"
#define YoParam_COUNT @"count"
#define YoParam_BANNER_MESSAGE @"banner_message"
#define YoParam_BANNER_ACTION @"banner_action"
#define YoParam_Yo_PAYLOAD @"yo_payload"
#define YoParam_USERNAME @"username"
#define YoParam_INCLUDES_LOCATION @"includes_location"

@interface YoAnalytics : NSObject

//** Only a set list of events can be logged */
+ (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters;

@end
