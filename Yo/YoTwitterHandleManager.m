//
//  YoTwitterManager.m
//  Yo
//
//  Created by Peter Reveles on 2/11/15.
//
//

#import "YoTwitterHandleManager.h"

#define TWITTER_HANDLE_DATA_FILE_NAME @"twitterHandles"
#define URL_ADDRESS_OF_TWITTER_HANDLE_JSON @"https://yoapp.s3.amazonaws.com/yo/twitter.json"

@interface YoTwitterHandleManager ()
@property (nonatomic, strong) NSDictionary *yoUsernameToTwitterHandleDic;
@end

@implementation YoTwitterHandleManager

+ (instancetype)sharedInstance {
    static YoTwitterHandleManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)loadWithCompletionBlock:(void (^)(BOOL success))block {
    [self loadUpdatedDataWithCompletionBlock:^(BOOL success) {
        if (success) {
            if (block) {
                block(success);
            }
        }
        else {
            [self loadOriginalDataWithCompletionBlock:block];
        }
    }];
}

- (void)loadOriginalDataWithCompletionBlock:(void (^)(BOOL success))block {
    BOOL success = NO;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:TWITTER_HANDLE_DATA_FILE_NAME ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!JSONObject || error) {
            DDLogWarn(@"Failed to load twitter handle json with error %@", error.localizedDescription);
        }
        else {
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                self.yoUsernameToTwitterHandleDic = (NSDictionary *)JSONObject;
                success = YES;
            }
            else {
                DDLogWarn(@"Failed to load twitter handle json with error");
            }
        }
    }
    
    if (block) {
        block(success);
    }
}

- (NSString *)updatedDataFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:MakeString(@"%@.json", TWITTER_HANDLE_DATA_FILE_NAME)];
    return filePath;
}

- (void)loadUpdatedDataWithCompletionBlock:(void (^)(BOOL success))block {
    BOOL success = NO;
    NSString *filePath = [self updatedDataFilePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!JSONObject || error) {
            DDLogWarn(@"There does not exist updated Twitter Handle Info %@", error.localizedDescription);
        }
        else {
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                self.yoUsernameToTwitterHandleDic = (NSDictionary *)JSONObject;;
                success = YES;
            }
            else {
                DDLogWarn(@"Failed to load updated Twitter Handle Info");
            }
        }
    }
    
    if (block) {
        block(success);
    }
}

- (void)updateWithCompletionBlock:(void (^)(BOOL success))block {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL_ADDRESS_OF_TWITTER_HANDLE_JSON]];
    __weak YoTwitterHandleManager *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        BOOL success = NO;
        if (connectionError) {
            DDLogWarn(@"Failed to update Twitter Handle JSON with connection error %@", connectionError);
        }
        else {
            if (data) {
                NSError *error = nil;
                id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                if (!JSONObject || error) {
                    DDLogWarn(@"Failed to parse JSON | %@", NSStringFromSelector(@selector(updateWithCompletionBlock:)));
                }
                else {
                    if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                        weakSelf.yoUsernameToTwitterHandleDic = (NSDictionary *)JSONObject;
                        [weakSelf saveWithCompletionBlock:nil];
                        success = YES;
                    }
                    else {
                        DDLogWarn(@"Failed to parse JSON | %@", NSStringFromSelector(@selector(updateWithCompletionBlock:)));
                    }
                }
            }
            else {
                DDLogWarn(@"No data found for Twitter Handles | %@", NSStringFromSelector(@selector(updateWithCompletionBlock:)));
            }
        }
        if (block) {
            block(success);
        }
    }];
}

- (void)saveWithCompletionBlock:(void (^)(BOOL sucess))block {
    BOOL success = NO;
    if ([self.yoUsernameToTwitterHandleDic count]) {
        NSData *JSON= [NSJSONSerialization dataWithJSONObject:self.yoUsernameToTwitterHandleDic options:NSJSONWritingPrettyPrinted error:nil];
        if (JSON) {
            NSString *filePath = [self updatedDataFilePath];
            [JSON writeToFile:filePath atomically:YES];
            success = YES;
        }
        else {
            success = YES;
        }
    }
    
    if (block) {
        block(success);
    }
}

- (NSString *)handleForYoUsername:(NSString *)username {
    NSString *handle = [self.yoUsernameToTwitterHandleDic valueForKey:username];
    if ([handle length] && [handle rangeOfString:@"@"].location == NSNotFound) {
        handle = MakeString(@"@%@", handle);
    }
    return handle;
}

@end
