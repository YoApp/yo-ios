//
//  YoABTestingFrameWork.m
//  Yo
//
//  Created by Peter Reveles on 2/13/15.
//
//

#import "YoABTestingFrameWork.h"

#define Yo_EXPERIMENTS_DATA_FILE_NAME @"yoExperiments"
#define URL_ADDRESS_OF_EXPERIMENTS_JSON @"https://yoapp.s3.amazonaws.com/yo/experiments.json"

#define Yo_EXPERIMENTS_KEY @"experiments"
#define Yo_EXPERIMENT_NAME_KEY @"name"
#define Yo_EXPERIMENT_PROBABILITY_KEY @"chance"

#define Yo_ON_BOARDING_EXPERIMENT_KEY @"on-boarding"
#define Yo_SHOW_DETAILS_BUTTON_EXPERIMENT_KEY @"show_details_button"

@interface YoABTestingFrameWork ()
@property (nonatomic, strong) NSArray *experiments;
@end

@implementation YoABTestingFrameWork

#pragma mark - Life

+ (instancetype)sharedInstance {
    static YoABTestingFrameWork *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - External Utility

- (NSString *)log {
    NSString *log = @"Test = Option Taken\n";
    for (NSDictionary *experiment in self.experiments) {
        NSString *experimentName = [experiment valueForKey:Yo_EXPERIMENT_NAME_KEY];
        NSString *print = experimentName;
        YoABTestOption option = -1;
        id cachedValue = [[NSUserDefaults standardUserDefaults] valueForKey:MakeString(@"YoABTestingStoredOptionForTest%@", experimentName)];
        if (cachedValue && [cachedValue isKindOfClass:[NSString class]]) {
            option = [cachedValue intValue];
            print = [print stringByAppendingString:MakeString(@" = %@", [self stringVersionOfOption:option])];
        }
        else {
            print = [print stringByAppendingString:@" = (Not Yet Taken)"];
        }
        log = MakeString(@"%@%@\n", log, print);
    }
    return log;
}

- (NSString *)stringVersionOfOption:(YoABTestOption)option {
    NSString *string = @"YoABTestOptionNotAValidOption";
    switch (option) {
        case YoABTestOptionA:
            string = @"YoABTestOptionA";
            break;
            
        case YoABTestOptionB:
            string = @"YoABTestOptionB";
            
        default:
            break;
    }
    return string;
}

- (YoABTestOption)optionForTest:(YoABTest)test {
    NSString *testKey = [self keyForTest:test];
    YoABTestOption option = YoABTestOptionA;
    CGFloat probabilty = 0.0f;
    id cachedValue = [[NSUserDefaults standardUserDefaults] valueForKey:MakeString(@"YoABTestingStoredOptionForTest%@", testKey)];
    if (cachedValue && [cachedValue isKindOfClass:[NSString class]]) {
        option = [cachedValue intValue];
    }
    else {
        NSDictionary *experiment = [self experimentWithName:testKey];
        if (experiment) {
            probabilty = [[experiment valueForKey:Yo_EXPERIMENT_PROBABILITY_KEY] floatValue];
        }
        option = [self optionBasedOnProbability:probabilty];
        [[NSUserDefaults standardUserDefaults] setObject:MakeString(@"%lu", (unsigned long)option) forKey:MakeString(@"YoABTestingStoredOptionForTest%@", testKey)];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [YoAnalytics logEvent:YoEventUserPlacedIntoTest withParameters:@{@"test_key":testKey, @"placed_group":option?@"B":@"A"}];
    }
    
    return option;
}

#pragma mark - Internal Utility

- (YoABTestOption)optionBasedOnProbability:(CGFloat)probability{
    int lowerBound = 0;
    int upperBound = 100;
    int randomInt = lowerBound + arc4random() % (upperBound - lowerBound);
    CGFloat randomFloat = randomInt / 100.0f;
    YoABTestOption option = YoABTestOptionA;
    if (probability >= randomFloat) {
        option = YoABTestOptionB;
    }
    return option;
}

- (NSDictionary *)experimentWithName:(NSString *)name {
    NSDictionary *result = nil;
    for (NSDictionary *experiment in self.experiments) {
        NSString *experimentName = [experiment valueForKey:Yo_EXPERIMENT_NAME_KEY];
        if ([experimentName isEqualToString:name]) {
            result = experiment;
            break;
        }
    }
    return result;
}

- (YoABTest)testForKey:(NSString *)key {
    YoABTest test = YoABTestNoTest;
    if ([key isEqualToString:Yo_ON_BOARDING_EXPERIMENT_KEY]) {
        test = YoABTestOBoarding;
    }
    else if ([key isEqualToString:Yo_SHOW_DETAILS_BUTTON_EXPERIMENT_KEY]) {
        test = YoABTestShowDetailsButton;
    }
    return test;
}

- (NSString *)keyForTest:(YoABTest)test {
    NSString *key = nil;
    switch (test) {
        case YoABTestNoTest:
            key = nil;
            break;
            
        case YoABTestOBoarding:
            key = Yo_ON_BOARDING_EXPERIMENT_KEY;
            break;
            
        case YoABTestShowDetailsButton:
            key = Yo_SHOW_DETAILS_BUTTON_EXPERIMENT_KEY;
            break;
            
        default:
            break;
    }
    return key;
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
    NSString *filePath = [[NSBundle mainBundle] pathForResource:Yo_EXPERIMENTS_DATA_FILE_NAME ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!JSONObject || error) {
            DDLogWarn(@"Failed to load twitter handle json with error %@", error.localizedDescription);
        }
        else {
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                self.experiments = [(NSDictionary *)JSONObject valueForKey:Yo_EXPERIMENTS_KEY];
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
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:MakeString(@"%@.json", Yo_EXPERIMENTS_DATA_FILE_NAME)];
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
                self.experiments = [(NSDictionary *)JSONObject valueForKey:Yo_EXPERIMENTS_KEY];
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
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL_ADDRESS_OF_EXPERIMENTS_JSON]];
    __weak YoABTestingFrameWork *weakSelf = self;
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
                        self.experiments = [(NSDictionary *)JSONObject valueForKey:Yo_EXPERIMENTS_KEY];
                        [weakSelf saveExperimentsData:data withCompletionBlock:nil];
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

- (void)saveExperimentsData:(id)JSONData withCompletionBlock:(void (^)(BOOL sucess))block {
    BOOL success = NO;
    if (JSONData) {
        NSString *filePath = [self updatedDataFilePath];
        [JSONData writeToFile:filePath atomically:YES];
        success = YES;
    }
    if (block) {
        block(success);
    }
}

@end
