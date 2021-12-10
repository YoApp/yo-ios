//
//  YoManager.h
//  Yo
//
//  Created by Peter Reveles on 1/5/15.
//
//

#import <Foundation/Foundation.h>
#import "YoAPIClient.h"
@class CLLocation;
@class YoUser;
@class YoModelObject;

typedef NS_ENUM(NSUInteger, YoResult) {
    YoResultFailed,
    YoResultSuccess,
    YoResultBadLink,
    YoResultBadLocation,
};

@interface YoManager : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithYoAPIClient:(YoAPIClient *)yoAPIClient;

#pragma mark Network

- (void)grantNetworkAccessWithAPIClient:(YoAPIClient *)apiClient;

typedef void (^YoResponseBlock)(YoResult result, NSInteger statusCode, id responseObject);

#pragma mark - Yo

- (void)yo:(NSString *)username completionHandler:(YoResponseBlock)block;

- (void)yo:(NSString *)username withCurrentLocation:(BOOL)withCurrentLocation completionHandler:(YoResponseBlock)block;

- (void)yo:(NSString *)username withLocation:(CLLocation *)location completionHandler:(YoResponseBlock)block;

- (void)yo:(NSString *)username contextParameters:(NSDictionary *)contextParameters completionHandler:(YoResponseBlock)block;

- (void)yo:(YoModelObject *)object withContextParameters:(NSDictionary *)parameters completionHandler:(YoResponseBlock)block;

- (void)sendYoWithParams:(NSDictionary *)params completionHandler:(YoResponseBlock)block;

@end
