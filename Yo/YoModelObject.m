//
//  YoModelObject.m
//  Yo
//
//  Created by Or Arbel on 5/13/15.
//
//

#import "YoModelObject.h"

@interface YoModelObject ()
@property (strong, nonatomic) NSDictionary *dictionaryRepresentation;
@end

@implementation YoModelObject

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSDictionary *mapping = [self mapping];
    for (NSString *serverKey in mapping) {
        NSString *clientKey = mapping[serverKey];
        if ([self valueForKey:clientKey]) {
            [encoder encodeObject:[self valueForKey:clientKey] forKey:clientKey];
        }
    }
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        NSDictionary *mapping = [self mapping];
        for (NSString *serverKey in mapping) {
            NSString *clientKey = mapping[serverKey];
            id object = [decoder decodeObjectForKey:clientKey];
            if (object) {
                [self setValue:object forKey:clientKey];
            }
        }
    }
    return self;
}

- (NSDictionary *)mapping {
    return @{
             @"id": @"objectId",
             @"type": @"objectType",
             @"phone_number": @"phoneNumber",
             @"username": @"username",
             @"is_pseudo": @"isPseudo",
             @"last_seen_time": @"lastSeenDate"
             };
}

+ (instancetype)objectFromDictionary:(NSDictionary *)dictionary {
    NSString *type = dictionary[@"type"];
    if ( ! type) {
        type = dictionary[@"user_type"];
    }
    YoModelObject *object = nil;
    if ([type isEqualToString:@"user"] || [type isEqualToString:@"pseudo_user"]) {
        object = [NSClassFromString(@"YoUser") new];
    }
    else if ([type isEqualToString:@"group"]) {
        object = [NSClassFromString(@"YoGroup") new];
    }
    else {
        DDLogError(@"Unknown Yo Object Type: %@", type);
    }
    [object updateWithDictionary:dictionary];
    return object;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    for (NSString *serverKey in [dictionary allKeys]) {
        NS_DURING
        NSString *clientKey = [self mapping][serverKey];
        if (clientKey) {
            if (dictionary[serverKey]) {
                [self setValue:dictionary[serverKey] forKey:clientKey];
            }
            else {
                DDLogError(@"Object %@ does not have %@", self, serverKey);
            }
        }
        else {
            //DDLogWarn(@"%@ doesn't map server field: %@", [self class], serverKey);
        }
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    
    if ([dictionary objectForKey:@"last_seen_time"]) {
        self.lastSeenDate = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"last_seen_time"] doubleValue] / pow(10, 6)];
    }
    
    self.dictionaryRepresentation = dictionary;
}

- (NSDictionary *)toObject {
    NSArray *fields = @[@"username", @"phone_number", @"name", @"display_name", @"last_seen_time"];
    NSDictionary *mapping = [self mapping];
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    for (NSString *serverKey in [mapping allKeys]) {
        NSString *clientKey = mapping[serverKey];
        if ([fields containsObject:serverKey]) {
            NSString *value = [self valueForKey:clientKey];
            if (value) {
                [object setObject:value forKey:serverKey];
            }
        }
    }
    return object;
}

- (NSString *)displayName {
    DDLogError(@"%@ does not implement displayName", [self class]);
    return @"";
}

- (NSString *)getStatusStringForStatus:(NSString *)status {
    return status;
}

- (BOOL)isEqual:(YoModelObject *)object {
    if (![object isKindOfClass:[self class]]) return NO;
    
    BOOL isEqual = NO;
    if (([self.objectId length] && [object.objectId length]) && [self.objectId isEqualToString:object.objectId]) {
        isEqual = YES;
    }
    else if (([self.username length] && [object.username length]) && [self.username isEqualToString:object.username]) {
        isEqual = YES;
    }
    return isEqual;
}

@end
