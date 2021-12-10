//
//  MobliConfigManager.m
//  Mobli
//
//  Created by Or Arbel on 9/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MobliConfigManager.h"
#import "SMXMLDocument.h"

#if DEBUG
#define USE_BUNDLE_CONFIG 1
#define kConfigXMLURL   @"http://cdntest.mobli.com/clients_data/ios/yo/1.0.9/config.xml"
#elif ADHOC | UTEST | BETACONFIG
#define USE_BUNDLE_CONFIG 0
#define kConfigXMLURL   @"http://cdntest.mobli.com/clients_data/ios/yo/1.0.9/config.xml"
#else
#define USE_BUNDLE_CONFIG 0 //  @or: using cdn instead of stat beacuse stat takes 24 hours to update
#define kConfigXMLURL   @"http://cdn.mobli.com/clients_data/ios/yo/1.0.9/config.xml"
#endif


#define kConfigFilename @"config.xml"
#define kRootObjectName @"Configuration"

@interface MobliConfigManager ()
@property(atomic, strong) SMXMLDocument *xmlDocument;
@end

@implementation MobliConfigManager

@synthesize xmlDocument;

+ (MobliConfigManager *)sharedInstance {
    static MobliConfigManager *sharedInstance = nil;
    if (sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[MobliConfigManager alloc] init];
            [sharedInstance setup];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
            [NSThread detachNewThreadSelector:@selector(updateXML) toTarget:sharedInstance withObject:nil];
        });
    }
    return sharedInstance;
}

+ (void)cleanupOnVersionUpdate {
    //@avishay: We don't want to use older version file
    NSString *downloadedXmlPath = [[self applicationDocumentsDirectory:kConfigFilename] path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadedXmlPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadedXmlPath error:nil];
    }
}

- (void)setup {
    NSError *error = nil;
    NSData *xmlData = [NSData dataWithContentsOfFile:[[MobliConfigManager applicationDocumentsDirectory:kConfigFilename] path]];
    if (USE_BUNDLE_CONFIG || !xmlData || xmlData.length == 0) {
        xmlData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"config" ofType:@"xml"]];
    }
    //MobliLogIfError1(error);
    if (xmlData) {
        self.xmlDocument = [SMXMLDocument documentWithData:xmlData error:&error];
        if (error || ![self.xmlDocument.root.name isEqualToString:kRootObjectName]) {
            //MBLogError(@"Failed loading config.xml, using bundle: %@", error);
            xmlData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"config" ofType:@"xml"]];
            self.xmlDocument = [SMXMLDocument documentWithData:xmlData error:&error];
        }
        //MobliLogIfError1(error);
    }
    [self cleanCachedFields];
}

- (void)applicationWillEnterForeground {
    [NSThread detachNewThreadSelector:@selector(updateXML) toTarget:self withObject:nil];
}

// Never on main thread
- (void)updateXML {
    
#if USE_BUNDLE_CONFIG
    return;
#endif
    //MobliLogIfMainThreadAndReturn
    
    NSData *xmlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:kConfigXMLURL]];
    if (xmlData) {
        NSError *error = nil;
        NSString *xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
        [xml writeToURL:[MobliConfigManager applicationDocumentsDirectory:kConfigFilename] atomically:YES encoding:NSUTF8StringEncoding error:&error];
        //MobliLogIfError1(error);
        // @someone: We don't want to replace self.xmlDocument every time we come back from background, only download it and save to documents directory
        // @or: we do want, next line uncommented
        self.xmlDocument = [SMXMLDocument documentWithData:xmlData error:&error];
        DDLogInfo(@"Config file succesfully updated from Server");
        //MobliLogIfError1(error);
        [self cleanCachedFields];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationConfigDidUpdate object:nil userInfo:nil];
        });
    }
}

- (void)cleanCachedFields {

}

- (id)keyValue:(NSString *)key forNode:(NSString *)aNode {
    SMXMLElement *node = [self.xmlDocument.root childNamed:aNode];
    return [node valueWithPath:key];
}

- (id)keySection:(NSString *)key forNode:(NSString *)aNode {
    SMXMLElement *node = [self.xmlDocument.root childNamed:aNode];
    return [node childNamed:key];
}

- (id)miscValueOfKey:(NSString *)key {
    return [self keyValue:key forNode:@"Misc"];
}

- (id)yoLinkValueofKey:(NSString *)key {
    return [self keyValue:key forNode:@"YoLink"];
}

#pragma mark - Yo Link

- (NSTimeInterval)yoLinkLongTapDuration {
    return [[self yoLinkValueofKey:@"YoLinkLongTapDuration"] doubleValue];
}

- (NSTimeInterval)yoLinkInAppPushViewDuration {
    return MAX([[self yoLinkValueofKey:@"YoLinkInAppPushViewDuration"] doubleValue], 4.0);
}

// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL *)applicationDocumentsDirectory:(NSString *)addComponent {
    NSString *str = [NSString stringWithFormat:@"%@%@", [self applicationDocumentsDirectory], addComponent];
    return [NSURL URLWithString:str];
}

@end
