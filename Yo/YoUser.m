//
//  YoUser.m
//  Yo
//
//  Created by Peter Reveles on 1/6/15.
//
//

#import "YoUser.h"
#import "YoInbox.h"

@interface YoUser ()
@property (nonatomic, strong) YoManager *yoManager;
@property (nonatomic, strong) YoContactManager *contactsManager;
@property (nonatomic, strong) YoInbox *yoInbox;
@property (nonatomic, weak) YoAPIClient *yoAPIClient;
@end

@implementation YoUser

#pragma mark - Life

+ (YoUser *)me {
    return [[YoApp currentSession] user];
}

- (NSMutableArray *)list {
    return [[self contactsManager] list];
}

+ (BOOL)isValidUsername:(NSString *)username {
    BOOL valid = NO;
    if (![username length])
        valid = NO;
    else {
        NSCharacterSet *alphaNumericSet = [NSCharacterSet characterSetWithCharactersInString:@"+ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.#"];
        valid = [[username stringByTrimmingCharactersInSet:alphaNumericSet] isEqualToString:@""];
    }
    
    return valid;
}

#pragma mark - Properties

- (NSDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super mapping]];
    [mapping addEntriesFromDictionary:@{
                                        @"name": @"fullName",
                                        @"username": @"username",
                                        @"display_name": @"displayName",
                                        @"photo": @"photoURLString",
                                        @"yo_count": @"yoCount",
                                        @"email":@"email",
                                        @"first_name":@"firstName",
                                        @"last_name":@"lastName",
                                        @"is_verified": @"hasVerifiedPhoneNumber",
                                        @"default_context": @"defaultContext",
                                        @"center_plus_action": @"centerPlusAction",
                                        @"empty_list_text": @"emptyListText",
                                        @"is_service": @"isService",
                                        @"isSubscribable": @"isSubscribable",
                                        @"is_api_user": @"isAPIAccount"
                                        }];
    return mapping;
}

- (NSURL *)photoURL {
    return [NSURL URLWithString:_photoURLString];
}

- (BOOL)isPerson {
    return ! self.isAPIAccount && ! self.isService && ! self.isSubscribable;
}

- (void)setPhotoURL:(NSURL *)photoURL {
    _photoURLString = photoURL.absoluteString;
}

@synthesize displayName = _displayName;

- (NSString *)displayName {
    return _displayName ? _displayName : self.username;
}

- (NSString *)yoCountString {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!
    NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:self.yoCount]];
    return MakeString(@"%@ %@", NSLocalizedString(@"yo's:", @"%@ is the count").capitalizedString, formatted);
}

#pragma mark - Lazy Loading

- (YoContactManager *)contactsManager {
    if (!_contactsManager) {
        DDLogWarn(@"Only current Yo App user can have contacts. [[YoUser me] contactsManager]");
    }
    return _contactsManager;
}

- (YoInbox *)yoInbox {
    if (!_yoInbox) {
        _yoInbox = [YoInbox new];
        [[NSNotificationCenter defaultCenter] postNotificationName:YoUserHasBeenGrantedYoInbox object:self userInfo:@{@"inbox":_yoInbox}];
    }
    return _yoInbox;
}

- (YoManager *)yoManager {
    if (!_yoManager) {
        DDLogWarn(@"Only current Yo App user can send Yos. [[YoManager sharedInstance] yo:...]");
    }
    return _yoManager;
}

#pragma mark - API

- (void)grantAPIUsageWithClient:(YoAPIClient *)yoAPIClient {
    // ability to Yo
    _yoAPIClient = yoAPIClient;
    
    if (self.yoManager == nil) {
        self.yoManager = [YoManager new];
    }
    [self.yoManager grantNetworkAccessWithAPIClient:yoAPIClient];
    
    if (self.contactsManager == nil) {
        self.contactsManager = [[YoContactManager alloc] init];
    }
    [self.contactsManager grantAPIAccressWithClient:yoAPIClient];
    
    [self.yoInbox grantNetworkAccessWithAPIClient:yoAPIClient];
}

#pragma mark - External Utility

- (NSString *)description {
    return self.username;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        isEqual = [self isEqualToUser:object];
    }
    return isEqual;
}

- (BOOL)isEqualToUser:(YoUser *)otherUser {
    
    if (![otherUser isKindOfClass:[self class]]) return NO;
    
    BOOL isEqual = NO;
    if (([self.userID length] && [otherUser.userID length]) && [self.userID isEqualToString:otherUser.userID])
        isEqual = YES;
    
    if (self.username.length > 0 && (self.username && otherUser.username) && [self.username isEqualToString:otherUser.username])
        isEqual = YES;
    
    if (self.phoneNumber.length > 0 && (self.phoneNumber && otherUser.phoneNumber) && [self.phoneNumber isEqualToString:otherUser.phoneNumber])
        isEqual = YES;
    
    return isEqual;
}

@end
