//
//  RavenClient.m
//  Raven
//
//  Created by Kevin Renskers on 25-05-12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <sys/utsname.h>
#import "RavenClient.h"
#import "RavenClient_Private.h"
#import "RavenConfig.h"
#import "RavenJSONUtilities.h"

NSString *const kRavenLogLevelArray[] = {
    @"debug",
    @"info",
    @"warning",
    @"error",
    @"fatal"
};

NSString *const userDefaultsKey = @"nl.mixedCase.RavenClient.Exceptions";
NSString *const sentryProtocol = @"4";
NSString *const sentryClient = @"raven-objc/0.1.0";

static RavenClient *sharedClient = nil;

@implementation RavenClient

void exceptionHandler(NSException *exception) {
	[[RavenClient sharedClient] captureException:exception sendNow:NO];
}

#pragma mark - Setters and getters

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:timeZone];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    }

    return _dateFormatter;
}

- (void)setTags:(NSDictionary *)tags {
    NSMutableDictionary *mTags = [[NSMutableDictionary alloc] initWithDictionary:tags];

    if (![mTags objectForKey:@"Build version"]) {
        NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        if (buildVersion) {
            [mTags setObject:buildVersion forKey:@"Build version"];
        }
    }

#if TARGET_OS_IPHONE
    if (![mTags objectForKey:@"OS version"]) {
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];
        [mTags setObject:osVersion forKey:@"OS version"];
    }

    if (![mTags objectForKey:@"Device model"]) {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *deviceModel = [NSString stringWithCString:systemInfo.machine
                                                   encoding:NSUTF8StringEncoding];
        [mTags setObject:deviceModel forKey:@"Device model"];
    }
#endif

    _tags = mTags;
}

#pragma mark - Singleton and initializers

+ (RavenClient *)clientWithDSN:(NSString *)DSN {
    return [[self alloc] initWithDSN:DSN];
}

+ (RavenClient *)clientWithDSN:(NSString *)DSN extra:(NSDictionary *)extra {
    return [[self alloc] initWithDSN:DSN extra:extra];
}

+ (RavenClient *)clientWithDSN:(NSString *)DSN extra:(NSDictionary *)extra tags:(NSDictionary *)tags {
    return [[self alloc] initWithDSN:DSN extra:extra tags:tags];
}

+ (RavenClient *)sharedClient {
    return sharedClient;
}

- (id)initWithDSN:(NSString *)DSN {
    return [self initWithDSN:DSN extra:@{}];
}

- (id)initWithDSN:(NSString *)DSN extra:(NSDictionary *)extra {
    return [self initWithDSN:DSN extra:extra tags:@{}];
}

- (id)initWithDSN:(NSString *)DSN extra:(NSDictionary *)extra tags:(NSDictionary *)tags {
    self = [super init];
    if (self) {
        self.config = [[RavenConfig alloc] init];
        self.extra = extra;
        self.tags = tags;

        // Parse DSN
        if (![self.config setDSN:DSN]) {
            DDLogWarn(@"Invalid DSN %@!", DSN);
            return nil;
        }

        // Save singleton
        if (sharedClient == nil) {
            sharedClient = self;
        }
    }

    return self;
}

#pragma mark - Messages

- (void)captureMessage:(NSString *)message {
    [self captureMessage:message level:kRavenLogLevelDebugInfo];
}

- (void)captureMessage:(NSString *)message level:(RavenLogLevel)level {
    [self captureMessage:message level:level method:nil file:nil line:0];
}

- (void)captureMessage:(NSString *)message level:(RavenLogLevel)level method:(const char *)method file:(const char *)file line:(NSInteger)line {
    NSArray *stacktrace;
    if (method && file && line) {
        NSDictionary *frame = [NSDictionary dictionaryWithObjectsAndKeys:
                               [[NSString stringWithUTF8String:file] lastPathComponent], @"filename",
                               [NSString stringWithUTF8String:method], @"function",
                               @(line), @"lineno",
                               nil];

        stacktrace = [NSArray arrayWithObject:frame];
    }

    NSDictionary *data = [self prepareDictionaryForMessage:message
                                                     level:level
                                                   culprit:file ? [NSString stringWithUTF8String:file] : nil
                                                stacktrace:stacktrace
                                                 exception:nil];

    [self sendDictionary:data];
}

#pragma mark - Exceptions

- (void)captureException:(NSException *)exception {
    [self captureException:exception sendNow:YES];
}

- (void)captureException:(NSException *)exception sendNow:(BOOL)sendNow {
    NSString *message = [NSString stringWithFormat:@"%@: %@", exception.name, exception.reason];

    NSDictionary *exceptionDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   exception.name, @"type",
                                   exception.reason, @"value",
                                   nil];

    NSArray *callStack = [exception callStackSymbols];
    NSMutableArray *stacktrace = [[NSMutableArray alloc] initWithCapacity:[callStack count]];
    for (NSString *call in callStack) {
        [stacktrace addObject:[NSDictionary dictionaryWithObjectsAndKeys:call, @"function", nil]];
    }

    NSDictionary *data = [self prepareDictionaryForMessage:message
                                                     level:kRavenLogLevelDebugFatal
                                                   culprit:nil
                                                stacktrace:stacktrace
                                                 exception:exceptionDict];

    if (!sendNow) {
        // We can't send this exception to Sentry now, e.g. because the app is killed before the
        // connection can be made. So, save it into NSUserDefaults.
        NSArray *reports = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
        if (reports != nil) {
            NSMutableArray *reportsCopy = [reports mutableCopy];
            [reportsCopy addObject:data];
            [[NSUserDefaults standardUserDefaults] setObject:reportsCopy forKey:userDefaultsKey];
        } else {
            reports = [NSArray arrayWithObject:data];
            [[NSUserDefaults standardUserDefaults] setObject:reports forKey:userDefaultsKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [self sendDictionary:data];
    }
}

- (void)setupExceptionHandler {
    NSSetUncaughtExceptionHandler(&exceptionHandler);

    // Process saved crash reports
    NSArray *reports = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
    if (reports != nil && [reports count]) {
        for (NSDictionary *data in reports) {
            [self sendDictionary:data];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:userDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Private methods

- (NSString *)generateUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *res = [(__bridge NSString *)string stringByReplacingOccurrencesOfString:@"-" withString:@""];
    CFRelease(string);
    return res;
}

- (NSDictionary *)prepareDictionaryForMessage:(NSString *)message
                                        level:(RavenLogLevel)level
                                      culprit:(NSString *)culprit
                                   stacktrace:(NSArray *)stacktrace
                                    exception:(NSDictionary *)exceptionDict {
    NSDictionary *stacktraceDict = [NSDictionary dictionaryWithObjectsAndKeys:stacktrace, @"frames", nil];

    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self generateUUID], @"event_id",
            self.config.projectId, @"project",
            [self.dateFormatter stringFromDate:[NSDate date]], @"timestamp",
            kRavenLogLevelArray[level], @"level",
            @"objc", @"platform",

            self.extra, @"extra",
            self.tags, @"tags",

            message, @"message",
            culprit ?: @"", @"culprit",
            stacktraceDict, @"stacktrace",
            exceptionDict, @"exception",
            nil];
}

- (void)sendDictionary:(NSDictionary *)dict {
    NSError *error = nil;
    
    NSData *JSON = JSONEncode(dict, &error);
    [self sendJSON:JSON];
}

- (void)sendJSON:(NSData *)JSON {
    NSString *header = [NSString stringWithFormat:@"Sentry sentry_version=%@, sentry_client=%@, sentry_timestamp=%ld, sentry_key=%@, sentry_secret=%@",
                        sentryProtocol,
                        sentryClient,
                        (long)[NSDate timeIntervalSinceReferenceDate],
                        self.config.publicKey,
                        self.config.secretKey];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.config.serverURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[JSON length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:JSON];
    [request setValue:header forHTTPHeaderField:@"X-Sentry-Auth"];

    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    if (connection) {
        self.receivedData = [NSMutableData data];
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //DDLogError(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //DDLogVerbose(@"JSON sent to Sentry");
}

@end
