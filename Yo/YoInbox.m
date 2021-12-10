//
//  YoInbox.m
//  Yo
//
//  Created by Peter Reveles on 3/13/15.
//
//

#import "YoInbox.h"

#ifndef IS_APP_EXTENSION
#import "YoMapController.h"
#import "YoWebBrowserController.h"
#import "YoPopupAlertViewController.h"
#endif

#define kYoInboxStorageKey @"kYoInboxStorageKey"

#define YoUnreadYoArrayKey @"unread_yos"

@interface YoInbox ()
@property (nonatomic, strong) NSMutableDictionary *yoInbox;
@property (nonatomic, weak) YoAPIClient *apiClient;
@end

@implementation YoInbox

#pragma mark - Lazy Loading

- (NSMutableDictionary *)yoInbox {
    if (!_yoInbox) {
        _yoInbox = [NSMutableDictionary new];
    }
    return _yoInbox;
}

- (void)updateOrAddYo:(Yo *)yo withStatus:(YoStatus)status {
    yo.status = status;
    [self updateCopyOfYo:yo];
    [self acknowledgeYo:yo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YoInboxUpdated"
                                                        object:self];
    if ([self.delegate respondsToSelector:@selector(yoInbox:didUpdateStatusForYo:)]) {
        [self.delegate yoInbox:self didUpdateStatusForYo:yo];
    }
}

- (void)updateYos:(NSArray *)yos withStatus:(YoStatus)status
{
    NSMutableArray *yoIDs = [[NSMutableArray alloc] initWithCapacity:yos.count];
    for (Yo *yo in yos) {
        if ([yo.yoID length] &&
            ![yo.yoID hasPrefix:YoLocalYoIDPrefix]) {
            yo.status = status;
            [yoIDs addObject:yo.yoID];
            [self updateCopyOfYo:yo];
        }
    }
    [self acknowledgeYosWithIDs:yoIDs];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YoInboxUpdated" object:nil];
    if ([self.delegate respondsToSelector:@selector(yoInbox:didUpdateStatusesForYos:)]) {
        [self.delegate yoInbox:self didUpdateStatusesForYos:yos];
    }
}

- (void)clearInbox {
    self.yoInbox = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YoInboxUpdated" object:nil];
}

- (NSArray *)getYosWithStatus:(YoStatus)status {
    NSArray *allYos = [self.yoInbox allValues];
    
    // filter for status
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.status == %i" , status];
    NSArray *fliteredYos = [allYos filteredArrayUsingPredicate:predicate];
    
    // sort
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    fliteredYos = [fliteredYos sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    return fliteredYos;
}

- (Yo *)getYoWithID:(NSString *)yoID {
    Yo *yo = nil;
    if (yoID.length) {
        yo = self.yoInbox[yoID];
    }
    return yo;
}

#pragma mark - Internal REST

/**
 Adds the provided Yo to the inbox if it is valid.
 */
- (void)updateCopyOfYo:(Yo *)yo {
    if ([self isValidYo:yo]) {
        // assure the status doesnt get overwritten
        Yo *currentYoCopy = self.yoInbox[yo.yoID];
        YoStatus precidentStatus = MAX(yo.status, currentYoCopy.status);
        yo.status = precidentStatus;
        // set and save
        self.yoInbox[yo.yoID] = yo;
    }
}

- (BOOL)isValidYo:(Yo *)yo {
    BOOL isYoValid = YES;
    if (![yo.yoID length]) {
        isYoValid = NO;
    }
    if (![yo.creationDate occuredToday] && ![yo.creationDate occuredYesterday]) {
        isYoValid = NO;
    }
    return isYoValid;
}

#pragma mark - Inbox Management

- (void)cleanInbox {
    NSArray *allYosCurrentlyInInbox = [self.yoInbox allValues];
    [self.yoInbox removeAllObjects];
    for (Yo *validYo in allYosCurrentlyInInbox) {
        [self updateCopyOfYo:validYo];
    }
}

- (void)refreshWithPayloads:(NSArray *)payloads {
    if (payloads) {
        NSArray *unreadYos = [YoInbox getYosFromPayloads:payloads];
        if ([unreadYos count]) {
            for (Yo *yo in unreadYos) {
                [self updateCopyOfYo:yo];
            }
        }
    }
}

- (void)updateWithCompletionBlock:(void (^)(BOOL sucess))completionBlock {
    void (^relayCompletion)(BOOL sucess) = ^(BOOL sucess) {
        if (completionBlock != nil) {
            completionBlock(sucess);
        }
    };
    [self.apiClient POST:@"rpc/get_unread_yos"
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NS_DURING
                     if (responseObject && [responseObject respondsToSelector:@selector(valueForKey:)]) {
                         NSArray *unreadYosPayloads = [responseObject valueForKey:YoUnreadYoArrayKey];
                         [self refreshWithPayloads:unreadYosPayloads];
                     }
                     relayCompletion(YES);
                     NS_HANDLER
                     relayCompletion(NO);
                     NS_ENDHANDLER
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     DDLogWarn(@"%@ - Network call to update Yos failed", [YoInbox class]);
                     relayCompletion(NO);
                 }];
}

#pragma mark - Network Communication

/**
 Updates the server with the Yos current status
 */
- (void)acknowledgeYo:(Yo *)yo {
    if ([yo.yoID length] &&
        ![yo.yoID hasPrefix:YoLocalYoIDPrefix]) {
        NSDictionary *params = @{Yo_ID_KEY:yo.yoID,
                                 Yo_STATUS_KEY:[YoInbox stringForYoStatus:yo.status],
                                 @"from_push":@(yo.openedFromPush)};
        [self.apiClient POST:@"rpc/yo_ack"
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         DDLogDebug(@"Yo Acknowldeged (from %@ to %@).", yo.senderUsername, [[YoUser me] username]);
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         DDLogError(@"Server failed to acknowledge Yo in op:%@\nwith error: %@", operation, error.localizedDescription);
                     }];
    }
}

- (void)acknowledgeYosWithIDs:(NSArray *)yoIDs {
    if (yoIDs.count > 0) {
        NSDictionary *params = @{@"yo_ids": yoIDs,
                                 @"status": @"read"};

        [self.apiClient POST:@"rpc/yo_ack"
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         DDLogWarn(@"Server failed to acknowledge Yo in op:%@\nwith error: %@", operation, error.localizedDescription);
                     }];
    }
}


#pragma mark Setup

- (void)grantNetworkAccessWithAPIClient:(YoAPIClient *)apiClient {
    _apiClient = apiClient;
}

#pragma mark - Internal Utility

+ (NSString *)stringForYoStatus:(YoStatus)status {
    switch (status) {
        case YoStatusReceived:
            return YoStatusReceivedKey;
            break;
            
        case YoStatusRead:
            return YoStatusReadKey;
            break;
            
        case YoStatusDismissed:
            return YoStatusDismissedKey;
            break;
    }
}

+ (NSArray *)getPayloadsFromYos:(NSArray *)yos {
    NSMutableArray *serializedYos = [[NSMutableArray alloc] initWithCapacity:[yos count]];
    if ([yos count] == 0) {
        return serializedYos;
    }
    for (Yo *yo in yos) {
        if (yo.payload != nil) {
            [serializedYos addObject:yo.payload];
        }
    }
    return serializedYos;
}

+ (NSArray *)getYosFromPayloads:(NSArray *)yoPayloads {
    NSMutableArray *yos = [[NSMutableArray alloc] initWithCapacity:[yoPayloads count]];
    if (yoPayloads) {
        for (id yoPayload in yoPayloads) {
            Yo *yo = [[Yo alloc] initWithPushPayload:yoPayload];
            if (yo != nil) {
                [yos addObject:yo];
            }
        }
    }
    return yos;
}

@end
