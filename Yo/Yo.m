//
//  Yo.m
//  Yo
//
//  Created by Peter Reveles on 2/9/15.
//
//

#import "Yo.h"
#import <CoreLocation/CoreLocation.h>
#import "Yo_Extensions.h"

@interface Yo ()
@property (nonatomic, strong) NSMutableDictionary *mutabalePayload;

@property (nonatomic, strong) NSString *yoID;

@property (nonatomic, strong) NSString *originYoID;

@property (nonatomic, strong) NSString *displayText;

@property (nonatomic, strong) NSString *inAppDisplayText;

@property (nonatomic, strong) NSDate *creationDate;

@property (nonatomic, strong) NSString *action;

@property (nonatomic, strong) NSString *soundFileName;

@property (nonatomic, strong) NSString *senderUsername;

@property (nonatomic, strong) NSString *originUsername;

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSURL *coverURL;

@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, assign) NSString *category;

@end

@implementation Yo

#pragma mark - Life

- (instancetype)initWithPushPayload:(id)payload {
    self = [super init];
    if (self) {
        [self parseYoPayload:payload];
    }
    return self;
}

- (void)refresh {
    [[[YoApp currentSession] yoAPIClient] POST:@"rpc/get_yo"
                                   parameters:@{@"yo_id": self.yoID}
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          
                                          [self parseYoPayload:responseObject];
                                          
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          DDLogError(@"%@", error);
                                      }];
}

- (void)parseYoPayload:(id)payload {
    if (![payload respondsToSelector:@selector(valueForKey:)]) {
        // preventing crash
        DDLogWarn(@"WARNING - Attempt to create yo from invlid payload %@", payload);
        return;
    }
    
    NSString *action = [payload valueForKey:Yo_ACTION_KEY];
    
    NSString *sound = nil;
    NSString *displayText = nil;
    NSString *category = nil;
    if ([[payload valueForKey:@"aps"] isKindOfClass:[NSDictionary class]]) {
        sound = [payload[@"aps"][Yo_SOUND_KEY] stringByReplacingOccurrencesOfString:@".mp3" withString:@""];
        displayText = payload[@"aps"][Yo_DISPLAY_TEXT_KEY];
        category = payload[@"aps"][Yo_CATEGORY_KEY];
    }
    
    if (![category length]) {
        // when the yo comes in from a server call it does not contain
        category = [payload valueForKey:Yo_CATEGORY_KEY];
    }
    self.category = category;
    
    self.leftDeepLink = payload[@"left_deep_link"];
    self.rightDeepLink = payload[@"right_deep_link"];
    
    self.action = action;
    self.soundFileName = sound;
    self.displayText = displayText;
    
    NSString  *inAppDisplayText = [payload valueForKey:Yo_InAppDisplayText_KEY];
    self.inAppDisplayText = inAppDisplayText;
    
    NSString *sender = [payload valueForKey:Yo_SENDER_KEY];
    sender = [sender uppercaseString];
    sender = [sender stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *origin = [payload valueForKey:Yo_ORIGIN_KEY];
    origin = [origin uppercaseString];
    origin = [origin stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *yo_id = [payload valueForKey:Yo_ID_KEY];
    NSString *origin_yo_id = [payload valueForKey:Yo_ORIGIN_YO_ID_KEY];
    
    self.senderUsername = sender;
    
    self.senderObject = (YoUser *)[[[YoUser me] contactsManager] objectForDictionary:payload[@"sender_object"]];
    
    self.originUsername = origin;
    self.yoID = yo_id;
    self.originYoID = origin_yo_id;
    
    self.groupName = payload[@"group_object"][@"display_name"];
    
    self.isGroupYo = payload[@"group_object"] != nil;
    
    self.body = payload[@"body"];
    self.text = [payload objectForKey:@"text"];
    
    NSString *locationString = payload[Yo_LOCATION_KEY];
    NS_DURING
    CLLocation *location = nil;
    if ([locationString length]) {
        NSArray *arr = [locationString componentsSeparatedByString:@";"];
        CLLocationDegrees latitude = [arr[0] floatValue];
        CLLocationDegrees longitude = [arr[1] floatValue];
        location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        self.location = location;
    }
    
    self.location = location;
    NS_HANDLER
    self.location = nil;
    NS_ENDHANDLER
    
    NSString *link = [payload valueForKey:Yo_LINK_KEY];
    NS_DURING
    if ([link length]) {
        NSURL *url = [self getURLForString:link];
        self.url = url;
#ifndef IS_APP_EXTENSION
        
        if (self.url && ([[self.url absoluteString] hasSuffix:@"png"] || [[self.url absoluteString] hasSuffix:@"jpg"] || [[self.url absoluteString] hasSuffix:@"gif"])) { // @or TODO replace with yo type check            
            if ([self.creationDate occuredToday] || [self.creationDate occuredYesterday]) {
                
                DDLogDebug(@"Prefetching %@", url);
                // @or: prefetch photo Yo to show it faster
                START_BACKGROUND_TASK
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                               ^{
                                   NSData *data = [NSData dataWithContentsOfURL:url];
                                   if ([[self.url absoluteString] hasSuffix:@"gif"]) {
                                       self.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                                   }
                                   else {
                                       self.image = [UIImage imageWithData:data];
                                   }
                                   END_BACKGROUND_TASK
                               });
                
            }
        }
#endif
    }
    NS_HANDLER
    NS_ENDHANDLER
    
    NSString *coverURL = [payload valueForKey:YoLinkCoverKey];
    NS_DURING
    if ([coverURL length]) {
        NSURL *url = [self getURLForString:coverURL];
        self.coverURL = url;
    }
    NS_HANDLER
    NS_ENDHANDLER
    
    NSString *thumbnailURLString = [payload valueForKey:@"thumbnail_url"];
    if (thumbnailURLString.length > 0) {
        NSURL *url = [self getURLForString:thumbnailURLString];
        self.thumbnailURL = url;
    }
    
    self.type = payload[@"type"];
    
    self.creationDate = [NSDate dateWithTimeIntervalSince1970:
                         [[payload objectForKey:@"created_at"] doubleValue] / pow(10, 6)];
    
    NSString *status = [payload valueForKey:Yo_STATUS_KEY];
    NS_DURING
    if ([status length]) {
        if ([status isEqualToString:YoStatusReadKey]) {
            self.status = YoStatusRead;
        }
        else if ([status isEqualToString:YoStatusDismissedKey]) {
            self.status = YoStatusDismissed;
        }
        else {
            self.status = YoStatusReceived;
        }
    }
    NS_HANDLER
    self.status = YoStatusReceived;
    NS_ENDHANDLER
}

#pragma mark - Utility Methods

- (NSURL *)getURLForString:(NSString *)string {
    // clean string
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    // get url
    NSURL *url = [NSURL URLWithString:string];
    // check special case
    if ([url.host isEqualToString:@"i.justyo.co"]) {
        NSDictionary *parameters = [self getParametersForURL:url];
        NSString *imageURLString = parameters[@"link"];
        NSURL *imageURL = [NSURL URLWithString:imageURLString];
        if (imageURL) {
            url = imageURL;
        }
    }
    return url;
}

- (NSDictionary *)getParametersForURL:(NSURL *)url {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    NSArray *components = [url.query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            id key = keyValue[0];
            id value = keyValue[1];
            parameters[key] = value;
        }
    }
    return parameters;
}

+ (NSString *)getStringRepresentationOfYoStatus:(YoStatus)status {
    NSString *string = nil;
    switch (status) {
        case YoStatusDismissed:
            string = YoStatusDismissedKey;
            break;
            
        case YoStatusRead:
            string = YoStatusReadKey;
            break;
            
        case YoStatusReceived:
            string = YoStatusReceivedKey;
            break;
            
        default:
            break;
    }
    return string;
}

#pragma mark Setters

- (void)setYoID:(NSString *)yoID {
    _yoID = yoID;
    if ([yoID length]) {
        self.mutabalePayload[Yo_ID_KEY] = yoID;
    }
}

- (void)setOriginYoID:(NSString *)originYoID {
    _originYoID = originYoID;
    if ([originYoID length]) {
        self.mutabalePayload[Yo_ORIGIN_YO_ID_KEY] = originYoID;
    }
}

- (void)setDisplayText:(NSString *)displayText {
    _displayText = displayText;
    if ([displayText length]) {
        self.mutabalePayload[Yo_DISPLAY_TEXT_KEY] = displayText;
    }
}

- (void)setStatus:(YoStatus)status {
    if (status >= self.status) {
        _status = status;
        NSString *stringStatus = [Yo getStringRepresentationOfYoStatus:status];
        if ([stringStatus length]) {
            self.mutabalePayload[Yo_STATUS_KEY] = stringStatus;
        }
    }
}

- (void)setInAppDisplayText:(NSString *)inAppDisplayText {
    _inAppDisplayText = inAppDisplayText;
    if ([inAppDisplayText length]) {
        self.mutabalePayload[Yo_InAppDisplayText_KEY] = inAppDisplayText;
    }
}

- (void)setCreationDate:(NSDate *)creationDate {
    _creationDate = creationDate;
    if (creationDate != nil) {
        NSTimeInterval epoc = [creationDate timeIntervalSince1970];
        NSTimeInterval usec = epoc * pow(10, 6);
        self.mutabalePayload[Yo_CREATION_DATE_KEY] = MakeString(@"%f", usec);
    }
}

- (void)setAction:(NSString *)action {
    _action = action;
    if ([action length]) {
        self.mutabalePayload[Yo_ACTION_KEY] = action;
    }
}

- (void)setSoundFileName:(NSString *)soundFileName {
    _soundFileName = soundFileName;
    if ([soundFileName length]) {
        self.mutabalePayload[Yo_SOUND_KEY] = soundFileName;
    }
}

- (void)setSenderUsername:(NSString *)senderUsername {
    _senderUsername = senderUsername;
    if ([senderUsername length]) {
        self.mutabalePayload[Yo_SENDER_KEY] = senderUsername;
    }
}

- (void)setOriginUsername:(NSString *)originUsername {
    _originUsername = originUsername;
    if ([originUsername length]) {
        self.mutabalePayload[Yo_ORIGIN_KEY] = originUsername;
    }
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    if ([url.absoluteString length]) {
        self.mutabalePayload[Yo_LINK_KEY] = url.absoluteString;
    }
}

- (void)setCoverURL:(NSURL *)coverURL {
    _coverURL = coverURL;
    if ([coverURL.absoluteString length]) {
        self.mutabalePayload[YoLinkCoverKey] = coverURL.absoluteString;
    }
}

- (void)setLocation:(CLLocation *)location {
    _location = location;
    if (location != nil) {
        NSString *locationString = MakeString(@"%f;%f", location.coordinate.latitude, location.coordinate.longitude);
        if ([locationString length]) {
            self.mutabalePayload[Yo_LOCATION_KEY] = locationString;
        }
    }
}

- (void)setCategory:(NSString *)category {
    _category = category;
    if ([category length]) {
        self.mutabalePayload[Yo_CATEGORY_KEY] = category;
    }
}

- (void)setLeftDeepLink:(NSString *)leftDeepLink {
    _leftDeepLink = leftDeepLink;
    if (leftDeepLink != nil) {
        self.mutabalePayload[@"left_deep_link"] = leftDeepLink;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"left_deep_link"];
    }
}

- (void)setRightDeepLink:(NSString *)rightDeepLink {
    _rightDeepLink = rightDeepLink;
    if (rightDeepLink != nil) {
        self.mutabalePayload[@"right_deep_link"] = rightDeepLink;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"right_deep_link"];
    }
}

- (void)setBody:(NSString *)body {
    _body = body;
    if (body != nil) {
        self.mutabalePayload[@"body"] = body;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"body"];
    }
}

- (void)setText:(NSString *)text {
    _text = text;
    if (text != nil) {
        self.mutabalePayload[@"text"] = text;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"text"];
    }
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL {
    _thumbnailURL = thumbnailURL;
    if (thumbnailURL != nil) {
        self.mutabalePayload[@"thumbnail_url"] = thumbnailURL.absoluteString;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"thumbnail_url"];
    }
}

- (void)setType:(NSString *)type {
    _type = type;
    if (type != nil) {
        self.mutabalePayload[@"type"] = type;
    }
    else {
        [self.mutabalePayload removeObjectForKey:@"type"];
    }
}

#pragma mark - Getters

- (NSDictionary *)payload {
    return [self.mutabalePayload copy];
}

- (BOOL)isFromService {
    BOOL isFromService = NO;
    if (!self.category ||
        [self.category isEqualToString:kYoCategoryServiceYo] ||
        [self.category isEqualToString:kYoCategoryServiceLocation] ||
        [self.category isEqualToString:kYoCategoryServiceLink] ||
        [self.category isEqualToString:kYoCategoryServicePhoto]) {
        isFromService = YES;
    }
    return isFromService;
}

- (NSMutableDictionary *)mutabalePayload {
    if (!_mutabalePayload) {
        _mutabalePayload = [NSMutableDictionary new];
    }
    return _mutabalePayload;
}

#pragma mark - YoNotificationObjectProtocal

- (NSString *)presentationSound {
    return self.soundFileName;
}

- (NSString *)dismissalSound {
    return nil;
}

- (BOOL)isEqualToYo:(Yo *)otherYo {
    if (otherYo != nil) {
        return [self isEqual:otherYo];
    }
    else {
        return NO;
    }
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        Yo *otherYo = (Yo *)object;
        if ([self.yoID isEqualToString:otherYo.yoID] ||
            [self.payload isEqualToDictionary:otherYo.payload]) {
            isEqual = YES;
        }
    }
    return isEqual;
}

@end
