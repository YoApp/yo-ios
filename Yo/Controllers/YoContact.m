//
//  YoContact.m
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import "YoContact.h"

NSString *const YoUserTypeRegular = @"user";
NSString *const YoUserTypePseudo = @"pseudo_user";

@implementation YoContact

- (NSString *)description {
    return MakeString(@"%@ - %@ - %@ - %@", self.source, self.username, self.fullName, self.phoneNumber);
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        isEqual = [self isEqualToContact:object];
    }
    return isEqual;
}

- (BOOL)isEqualToContact:(YoContact *)otherUser {
    
    if (![otherUser isKindOfClass:[self class]]) return NO;
    
    if (([self.phoneNumber length] && [otherUser.phoneNumber length]) && [self.phoneNumber isEqualToString:otherUser.phoneNumber]) {
        return YES;
    }
    
    if (([self.username length] && [otherUser.username length]) && [self.username isEqualToString:otherUser.username]) {
        return YES;
    }
    
    return NO;
}

- (void)fillWithUser:(YoUser *)user {
    if (user.firstName.length > 0 && user.lastName.length > 0) {
        self.fullName = MakeString(@"%@ %@", user.firstName, user.lastName);
    }
    else if (user.displayName.length > 0) {
        self.fullName = user.displayName;
    }
    else {
        self.fullName = user.username;
    }
    self.username = user.username;
    self.userType = @"user";
    self.yoCount = user.yoCount;
    if (user.lastSeenDate) {
        self.lastSeenDate = user.lastSeenDate;
    }
}

- (void)fillWithDictionary:(NSDictionary *)contactDictionary {
    self.username = contactDictionary[@"username"];
    self.phoneNumber = contactDictionary[@"number"];
    self.userType = @"user";
    self.fullName = contactDictionary[@"name"] ? contactDictionary[@"name"] : contactDictionary[@"username"];
    self.yoCount = [contactDictionary[@"yo_count"] intValue];
    
    if ([contactDictionary objectForKey:@"last_seen"]) {
        self.lastSeenDate = [NSDate dateWithTimeIntervalSince1970:[[contactDictionary objectForKey:@"last_seen"] doubleValue] / pow(10, 6)];
    }
}

@end
