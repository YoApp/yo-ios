//
//  YoContextPromotionBanner.m
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import "YoContextBanner.h"

@implementation YoContextBanner

+ (NSDictionary *)serverToClientKeyMapping
{
    static NSDictionary *serverToClientKeyMapping = nil;
    if (serverToClientKeyMapping == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableDictionary *serverToClientKeyMappingMutable = [[NSMutableDictionary alloc] initWithCapacity:[super serverToClientKeyMapping].count];
            [serverToClientKeyMappingMutable addEntriesFromDictionary:[super serverToClientKeyMapping]];
            serverToClientKeyMappingMutable[@"context"] = NSStringFromSelector(@selector(contextID));
            serverToClientKeyMapping = [serverToClientKeyMappingMutable copy];
        });
    }
    return serverToClientKeyMapping;
}

@end
