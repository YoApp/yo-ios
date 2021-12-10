//
//  YoGroup.m
//  Yo
//
//  Created by Or Arbel on 5/13/15.
//
//

#import "YoGroup.h"

@implementation YoGroup

- (NSDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super mapping]];
    [mapping addEntriesFromDictionary:@{
                                        @"name": @"name",
                                        @"username": @"username",
                                        @"is_muted":@"isMuted"
                                        }];
    return mapping;
}

- (BOOL)amIAdmin {
    return [self.admins containsObject:[YoUser me]];
}

- (NSString *)displayName {
    return MakeString(@"( %@ )", self.name);
}

- (NSString *)description {
    return self.displayName;
}

@end
