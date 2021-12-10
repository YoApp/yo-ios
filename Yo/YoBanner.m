//
//  YoBanner.m
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import "YoBanner.h"

@interface YoBanner ()
@property (strong, nonatomic) NSDictionary *dictionaryRepresentation;
@end

@implementation YoBanner

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self != nil) {
        [self updateWithDictionary:dictionary];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        NSDictionary *mapping = [[self class] serverToClientKeyMapping];
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

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSDictionary *mapping = [[self class] serverToClientKeyMapping];
    for (NSString *serverKey in mapping) {
        NSString *clientKey = mapping[serverKey];
        if ([self valueForKey:clientKey]) {
            [encoder encodeObject:[self valueForKey:clientKey] forKey:clientKey];
        }
    }
}

+ (NSDictionary *)serverToClientKeyMapping
{
    static NSDictionary *serverToClientKeyMapping = nil;
    if (serverToClientKeyMapping == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            serverToClientKeyMapping = @{
                                         @"id": NSStringFromSelector(@selector(ID)),
                                         @"message": NSStringFromSelector(@selector(message)),
                                         @"link": NSStringFromSelector(@selector(link))
                                         };
        });
    }
    return serverToClientKeyMapping;
}

+ (NSDictionary *)clientToServerKeyMapping
{
    static NSDictionary *clientToServerKeyMapping = nil;
    if (clientToServerKeyMapping == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSDictionary *serverToClientKeyMapping = [self serverToClientKeyMapping];
            if (serverToClientKeyMapping != nil) {
                NSMutableDictionary *clientToServerKeyMappingMutable = [[NSMutableDictionary alloc] initWithCapacity:serverToClientKeyMapping.count];
                [serverToClientKeyMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    clientToServerKeyMappingMutable[obj] = key;
                }];
                clientToServerKeyMapping = [clientToServerKeyMappingMutable copy];
            }
        });
    }
    return clientToServerKeyMapping;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    for (NSString *serverKey in [dictionary allKeys]) {
        NS_DURING
        NSString *clientKey = [[self class] serverToClientKeyMapping][serverKey];
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
    self.dictionaryRepresentation = dictionary;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToBanner:object];
    }
    return NO;
}

- (BOOL)isEqualToBanner:(YoBanner *)banner
{
    return [banner.ID isEqualToString:self.ID];
}

@end
