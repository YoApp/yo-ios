//
//  YoAPIClient.h
//  Yo
//
//  Created by Or Arbel on 8/21/14.
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

#ifdef DEBUG
#define YoAnalyticsURL [NSURL URLWithString:@"http://stats.justyo.co"]
#else
#define YoAnalyticsURL [NSURL URLWithString:@"https://stats.justyo.co"]
#endif

@interface YoAPIClient : AFHTTPRequestOperationManager

- (instancetype)initWithAccessToken:(NSString *)accessToken;

@property (strong, nonatomic) NSString *accessToken;

@end
