//
//  YOConstants.h
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//
#import "YOAppDelegate.h"
#import "Flurry.h"
#import "YoAPIClient.h"
#import "YoAlertManager.h"
#import "YoBaseViewController.h"
#import <DDLog.h>
#import "YoTransitioningConstants.h"

#define IS_OVER_IOS(x) [[UIDevice currentDevice].systemVersion floatValue] >= (x)
#define IS_UNDER_IOS(x) [[UIDevice currentDevice].systemVersion floatValue] < (x)

#define IS_IOS_S(x) [[UIDevice currentDevice].systemVersion caseInsensitiveCompare:(x)] == NSOrderedSame
#define IS_OVER_IOS_S(x) [[UIDevice currentDevice].systemVersion caseInsensitiveCompare:(x)] == NSOrderedDescending || IS_IOS_S(x)
#define IS_UNDER_IOS_S(x) [[UIDevice currentDevice].systemVersion caseInsensitiveCompare:(x)] == NSOrderedAscending

#define MakeString(s, ...) [NSString stringWithFormat:(s), ##__VA_ARGS__]

#define Monsterrat(x) [UIFont fontWithName:@"Montserrat" size:(x)]
#define MonsterratBold(x) [UIFont fontWithName:@"Montserrat-Bold" size:(x)]
#define MonsterratBlack(x) [UIFont fontWithName:@"Montserrat-Black" size:(x)]

#define YoUserYoBackFromYoCardStarted @"YoUserYoBackFromYoCardStarted"
#define YoUserYoBackFromYoCardFinished @"YoUserYoBackFromYoCardFinished"

#define YoNotificaitonAVMediaTypeVideoServicesDenied @"YoNotificaitonLocationServicesDenied"
     
#define DOWNLOAD_URL @"http://justyo.co"

#define APPDELEGATE ((YOAppDelegate *)[[UIApplication sharedApplication] delegate])

#define LOAD_NIB(x) [[[UINib nibWithNibName:(x) bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];

#ifdef  DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

#define TURQUOISE  @"1ABC9C" //blueish green
#define EMERALD    @"2ECC71" //light green
#define PETER      @"3498DB" //light blue
#define ASPHALT    @"34495E" //dark blue
#define GREEN      @"16A085" //green
#define SUNFLOWER  @"F1C40F" //orange yellow
#define BELIZE     @"2980B9" //blue
#define WISTERIA   @"8E44AD" //dark purple
#define ALIZARIN   @"e74c3c" //red

#define AMETHYST   @"934AB0" // the purple

#define BGCOLOR    AMETHYST

#define FacebookBlue @"3B5998"
#define NavigationItemColor @"502464"
#define DarkPurple @"8842A8"

#define ButtonTapped(x) NSNotification *notification = [[NSNotification alloc] initWithName:@"ButtonTappedNotification" object:nil userInfo:@{@"key": (x)}]; [[NSNotificationCenter defaultCenter]postNotification:notification];


typedef void (^YoAPIResultBlock)(BOOL succeeded, NSError *error, NSString *displayMessage);

#define YoNote_UsernameDoesNotExist @"YoNote_UsernameDoesNotExist"
#define YoNote_UsernameHasCurrentUserBlocked @"YoNote_UsernameHasCurrentUserBlocked"

#define YoNotificationUserDidUnsubscribeFromService @"YoNotificationUserDidUnsubscribeFromService"
#define YoNotificationUserDidSubscribeFromService @"YoNotificationUserDidSubscribeFromService"

typedef NS_ENUM(NSUInteger, YoType) {
    YoTypeJustYo,
    YoTypeYoLink,
    YoTypeYoPhoto,
    YoTypeYoLocation,
    YoTypeYoForward
};

#define YoAssistantRequestKey @"YoAssistantRequest"
#define YoAssistantSendYo @"YoSendYo"
#define YoAssistantYoUsernameKey @"username"
#define YoAssistantWithLocationBoolKey @"withLocation"
#define YoAssistantLatKey @"Lat"
#define YoAssistantLongKey @"Long"

#define YoAssistantLoadParentApp @"loadParentApp"

/**
 In Seconds.
 */
typedef NS_ENUM(NSUInteger, YoTimeSpan) {
    YoTimeSpanSecond = 1,
    YoTimeSpanMinute = 60,
    YoTimeSpanHour = 3600,
    YoTimeSpanDay = 86400,
    YoTimeSpanWeek = 604800,
    YoTimeSpanMonth = 2592000,
    YoTimeSpanYear = 31536000
};

#define YoLocalYoIDPrefix @"iOSLocalYo"