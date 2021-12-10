//
//  YoMagic.m
//  Yo
//
//  Created by Peter Reveles on 8/13/15.
//
//

#import "YoMagic.h"
#import "YoDataAccessManager.h"
#import "NSData+AES.h"

@implementation YoMagic

// Do this in back
+ (void)handleApplicationDidEnterBackground {
    static dispatch_once_t once_predicate;
    dispatch_once(&once_predicate, ^{
        //[self performMagic]; iOS 9 breaks this http://awkwardhare.com/post/121196006730/quick-take-on-ios-9-url-scheme-changes
    });
}

+ (void)performMagic {
    void (^completeBackgrounfTask)(UIBackgroundTaskIdentifier bgTask) = ^(UIBackgroundTaskIdentifier bgTask) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    };
    
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"yo_background_task" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        completeBackgrounfTask(bgTask);
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Do the work associated with the task, preferably in chunks.
        [[YoDataAccessManager sharedDataManager] fetchMagicWithCompletionHandler:^(id responceObject, NSError *error) {
            if (error == nil && responceObject != nil) {
                NSString *magicStringIncoming = [responceObject objectForKey:@"result"];
                id applications = [self parseMagic:magicStringIncoming];
                NSArray *availableURLStrings = [self filterApplications:applications];
                if (availableURLStrings.count > 0) {
                    NSString *magicStringOutgoing = [self createMagicStringFromArray:availableURLStrings];
                    if (magicStringOutgoing != nil) {
                        [[YoDataAccessManager sharedDataManager] setMagic:@{@"result":magicStringOutgoing}
                                                          completionBlock:^(id reponseObject, NSError *error)
                         {
                             completeBackgrounfTask(bgTask);
                         }];
                    }
                }
            }
        }];
    });
}

+ (NSArray *)filterApplications:(NSArray *)applications {
    @try {
        NSMutableArray *availableApplications = [[NSMutableArray alloc] initWithCapacity:applications.count];
        for (id application in applications) {
            NSString *URLString = [application objectForKey:@"url"];
            NSURL *URL = [NSURL URLWithString:URLString];
            if (URL != nil) {
                if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                    [availableApplications addObject:URLString];
                }
            }
        }
        return availableApplications;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

+ (NSString *)createMagicStringFromArray:(NSArray *)array {
    @try {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
        NSData *encryptedData = [data AES128EncryptedDataWithKey:@"{e_w5v4$RH8HwU4R"];
        NSString *magicString = [encryptedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        return magicString;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

+ (id)parseMagic:(NSString *)magicString {
    @try {
        NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:magicString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSData *decryptedData = [encryptedData AES128DecryptedDataWithKey:@"{e_w5v4$RH8HwU4R"];
        NSError *error = nil;
        id parsedMagic = [NSJSONSerialization JSONObjectWithData:decryptedData options:NSJSONReadingAllowFragments error:&error];
        return parsedMagic;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

@end
