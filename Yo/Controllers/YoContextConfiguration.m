//
//  YoConfigurationManager.m
//  Yo
//
//  Created by Peter Reveles on 7/9/15.
//
//

#import "YoContextConfiguration.h"
#import "YoDataAccessManager.h"

@interface YoContextConfiguration ()
@property (nonatomic, strong) NSDictionary *cachedConfiguration;
@end

@implementation YoContextConfiguration

+ (instancetype)sharedInstance {
    static YoContextConfiguration *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)load {
    NSData *data = [self getUpdatedConfigurationData];
    if (data != nil) {
        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data
                                                        options:kNilOptions
                                                          error:&error];
        if (JSONObject != nil &&
            error == nil) {
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *configurationDictionary = (NSDictionary *)JSONObject;
                [self configureWithDictionary:configurationDictionary];
                return;
            }
        }
    }
    
    data = [self getDefaultConfigurationData];
    if (data != nil) {
        NSError *error = nil;
        id JSONObject = [NSJSONSerialization JSONObjectWithData:data
                                                        options:kNilOptions
                                                          error:&error];
        if ([JSONObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *configurationDictionary = (NSDictionary *)JSONObject;
            [self configureWithDictionary:configurationDictionary];
        }
    }
}

- (void)configureWithDictionary:(NSDictionary *)configurationDictionary
{
    for (NSString *configurationKey in [configurationDictionary allKeys]) {
        NS_DURING
        NSString *clientKey = [[self class] mapping][configurationKey];
        if (clientKey) {
            id configurationObject = configurationDictionary[configurationKey];
            if (configurationObject != nil) {
                [self setValue:configurationObject
                        forKey:clientKey];
            }
            else {
                DDLogError(@"Object %@ does not have %@", self, configurationKey);
            }
        }
        else {
            //DDLogWarn(@"%@ doesn't map server field: %@", [self class], serverKey);
        }
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    self.cachedConfiguration = configurationDictionary;
}

- (NSData *)getDefaultConfigurationData
{
    NSString *configurationFilePath = [[NSBundle mainBundle] pathForResource:@"YoConfiguration" ofType:@"json"];
    return [NSData dataWithContentsOfFile:configurationFilePath];
}

- (NSData *)getUpdatedConfigurationData
{
    return [self getDefaultConfigurationData];
//    NSString *updatedConfigurationFilePath = [self updatedConfigurationFilePath];
  //  return [NSData dataWithContentsOfFile:updatedConfigurationFilePath];
}

- (NSString *)updatedConfigurationFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"YoUpdatedConfiguration.json"];
    return filePath;
}

- (void)save {
    if (self.cachedConfiguration != nil) {
        NSData *JSON= [NSJSONSerialization dataWithJSONObject:self.cachedConfiguration
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
        if (JSON != nil) {
            NSString *filePath = [self updatedConfigurationFilePath];
            [JSON writeToFile:filePath atomically:YES];
        }
    }
}

- (void)updateWithCompletionHandler:(void (^)(BOOL didUpdate))handler
{
    [[YoDataAccessManager sharedDataManager] fetchContextConfigurationWithCompletionHandler:^(NSDictionary *configuration, NSError *error) {
        BOOL didUpdate = NO;
        if (configuration != nil) {
            if ([self.cachedConfiguration isEqualToDictionary:configuration] == NO) {
                [self configureWithDictionary:configuration];
                [self save];
                didUpdate = YES;
            }
        }
        
        if (handler) {
            handler(didUpdate);
        }
    }];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSDictionary *mapping = [[self class] mapping];
    for (NSString *configurationKey in mapping) {
        NSString *clientKey = mapping[configurationKey];
        if ([self valueForKey:clientKey]) {
            [encoder encodeObject:[self valueForKey:clientKey]
                           forKey:clientKey];
        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self != nil) {
        NSDictionary *mapping = [[self class] mapping];
        for (NSString *configurationKey in mapping) {
            NSString *clientKey = mapping[configurationKey];
            id object = [decoder decodeObjectForKey:clientKey];
            if (object) {
                [self setValue:object forKey:clientKey];
            }
        }
    }
    return self;
}

+ (NSDictionary *)mapping {
    static NSDictionary *configurationKeyToClientKey = nil;
    if (configurationKeyToClientKey == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            configurationKeyToClientKey = @{
                                            @"default_context": NSStringFromSelector(@selector(defaultContextID)),
                                            @"contexts": NSStringFromSelector(@selector(contextIDs))
                                            };
        });
    }
    return configurationKeyToClientKey;
}

@end
