//
//  YoAPIClient.m
//  Yo
//
//  Created by Or Arbel on 8/21/14.
//
//

#import "YoAPIClient.h"
#import "YOUDID.h"

#ifdef DEBUG
//#define YO_BASE_URL_PROD  @"http://yo.ngrok.io"
#define YO_BASE_URL_PROD  @"https://api.justyo.co"
#else
#define YO_BASE_URL_PROD  @"https://api.justyo.co"
#endif

#define YO_BASE_URL_STAGE @"http://api-dev.herokuapp.com"

//#define YO_BASE_URL_DEV @"http://0.0.0.0:5001"
#define YO_BASE_URL_DEV @"http://yo.ngrok.io"

#define YoJavascriptWebToken @"JWT"

@implementation YoAPIClient

typedef void (^YoAPIResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^YoAPIErrorBlock)(AFHTTPRequestOperation *operation, NSError *error);

- (instancetype)initWithAccessToken:(NSString *)accessToken
{
    self = [self initWithBaseURL:[NSURL URLWithString:YO_BASE_URL_PROD]];
    if (self != nil) {
        // setup
        self.accessToken = accessToken;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:YO_BASE_URL_PROD]];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self != nil) {

        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        self.securityPolicy.allowInvalidCertificates = YES;
        self.securityPolicy.validatesDomainName = NO;
        
        AFJSONResponseSerializer *YoAFJSONResponseSerializer= [AFJSONResponseSerializer serializer];
        YoAFJSONResponseSerializer.removesKeysWithNullValues = YES;
        self.responseSerializer = YoAFJSONResponseSerializer;
        
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.requestSerializer setValue:[YOUDID value]
                      forHTTPHeaderField:@"X-RPC-UDID"];
        
        [self.requestSerializer setValue:@"http://jobs.justyo.co"
                      forHTTPHeaderField:@"X-HACKER-JOBS"];
    }
    
    return self;
}

/**
 Must call this before makeing any request against the server.
 */
- (void)updateHeaders
{
    [self.requestSerializer clearAuthorizationHeader];
    
    if (self.accessToken != nil) {
        [self.requestSerializer setValue:MakeString(@"Bearer %@", self.accessToken)
                      forHTTPHeaderField:@"Authorization"];
    }
}

#pragma mark Intercepting

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    YoAPIResponseBlock interceptedSuccessBlock = [self interceptBlockResponseObject:success];
    YoAPIErrorBlock interceptedFailureBlock = [self interceptBlockWithError:failure];
    [self updateHeaders];
    return [super POST:URLString
            parameters:parameters
               success:interceptedSuccessBlock
               failure:interceptedFailureBlock];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
       constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    YoAPIResponseBlock interceptedSuccessBlock = [self interceptBlockResponseObject:success];
    YoAPIErrorBlock interceptedFailureBlock = [self interceptBlockWithError:failure];
    [self updateHeaders];
    return [super POST:URLString
            parameters:parameters
constructingBodyWithBlock:block
               success:interceptedSuccessBlock
               failure:interceptedFailureBlock];
}

#pragma mark - Interception

- (YoAPIResponseBlock)interceptBlockResponseObject:(YoAPIResponseBlock)block {
    __weak YoAPIClient *weakSelf = self;
    YoAPIResponseBlock interceptedBlock = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [weakSelf serverDidSendResponse:responseObject
                         withStatusCode:operation.response.statusCode];
        if (block) {
            block(operation, responseObject);
        }
    };
    return interceptedBlock;
}

- (YoAPIErrorBlock)interceptBlockWithError:(YoAPIErrorBlock)block {
    __weak YoAPIClient *weakSelf = self;
    YoAPIErrorBlock interceptedBlock = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        [weakSelf serverDidSendResponse:operation.responseObject
                         withStatusCode:operation.response.statusCode];
        if (block) {
            block(operation, error);
        }
    };
    return interceptedBlock;
}

- (void)serverDidSendResponse:(id)responseObject withStatusCode:(NSInteger)statusCode {
    [self processResponseObject:responseObject];
    [self processStatusCode:statusCode];
}

- (void)processResponseObject:(id)responseObject {
    if ([responseObject respondsToSelector:@selector(valueForKey:)]) {
        // JWT
        NSString *updatedToken = [responseObject valueForKey:YoJavascriptWebToken];
        if (updatedToken != nil && updatedToken.length > 0) {
            [YoApp currentSession].accessToken = updatedToken;
        }
    }
}

- (void)processStatusCode:(NSInteger)statusCode {
    if (statusCode == 401 && [[YoApp currentSession] isLoggedIn]) {
        [[YoApp currentSession] logout];
#ifndef IS_APP_EXTENSION
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:NSLocalizedString(@"Session Ended", nil)
                                                   desciption:NSLocalizedString(@"Please login again", nil)];
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
            [[YoAlertManager sharedInstance] showAlert:yoAlert];
        });
#endif
    }
}

@end
