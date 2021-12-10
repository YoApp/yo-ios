//
//  YoModelObject.h
//  Yo
//
//  Created by Or Arbel on 5/13/15.
//
//

@interface YoModelObject : NSObject <NSCoding>

@property (readonly, nonatomic) NSDictionary *dictionaryRepresentation;
@property(nonatomic, strong) NSString *objectId;
@property(nonatomic, strong) NSString *objectType;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, assign) BOOL needsLocation;
@property(nonatomic, assign) BOOL isPseudo;
@property(nonatomic, strong) NSString *lastYoStatus;
@property(nonatomic, strong) NSDate *lastYoDate;
@property(nonatomic, strong) NSDate *lastSeenDate;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *fullName;
@property (strong, nonatomic) NSString *displayName;

+ (instancetype)objectFromDictionary:(NSDictionary *)dictionary;
- (void)updateWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)mapping;

- (NSString *)getStatusStringForStatus:(NSString *)status;

- (NSDictionary *)toObject;

@end
