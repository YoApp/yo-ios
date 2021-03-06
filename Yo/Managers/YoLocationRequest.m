//
//  YoLocatoinRequest.m
//  Yo
//
//  Created by Peter Reveles on 11/10/14.
//
//

#import "YoLocationRequest.h"

@interface YoLocationRequest ()

// Redeclare this property as readwrite for internal use.
@property (nonatomic, assign, readwrite) BOOL hasTimedOut;

// The NSDate representing the time when the request started. Set when the |timeout| property is set.
@property (nonatomic, strong) NSDate *requestStartTime;
// The timer that will fire to notify this request that it has timed out. Started when the |timeout| property is set.
@property (nonatomic, strong) NSTimer *timeoutTimer;

@end

@implementation YoLocationRequest

static NSInteger _nextRequestID = 0;

/**
 Returns a unique request ID (within the lifetime of the application).
 */
+ (NSInteger)getUniqueRequestID
{
    _nextRequestID++;
    return _nextRequestID;
}

/**
 Calls the designated initializer with an autogenerated unique requestID.
 */
- (id)init
{
    return [self initWithRequestID:[YoLocationRequest getUniqueRequestID]];
}

/**
 Designated initializer.
 Use regular init method to autogenerate a unique requestID.
 */
- (id)initWithRequestID:(NSInteger)requestID
{
    self = [super init];
    if (self) {
        _requestID = requestID;
        _hasTimedOut = NO;
    }
    return self;
}

/**
 Returns the associated recency threshold (in seconds) for the location request's desired accuracy level.
 */
- (NSTimeInterval)experationThreshold
{
    switch (self.desiredAccuracy) {
        case YoLocationAccuracyRoom:
            return kYoUpdateTimeStaleThresholdRoom;
            break;
        case YoLocationAccuracyHouse:
            return kYoUpdateTimeStaleThresholdHouse;
            break;
        case YoLocationAccuracyBlock:
            return kYoUpdateTimeStaleThresholdBlock;
            break;
        case YoLocationAccuracyNeighborhood:
            return kYoUpdateTimeStaleThresholdNeighborhood;
            break;
        case YoLocationAccuracyCity:
            return kYoUpdateTimeStaleThresholdCity;
            break;
        default:
            NSAssert(NO, @"Unknown desired accuracy.");
            return 0.0;
            break;
    }
}

/**
 Returns the associated horizontal accuracy threshold (in meters) for the location request's desired accuracy level.
 */
- (CLLocationAccuracy)minHorizontalAccuracyDesired
{
    switch (self.desiredAccuracy) {
        case YoLocationAccuracyRoom:
            return kYoHorizontalAccuracyThresholdRoom;
            break;
        case YoLocationAccuracyHouse:
            return kYoHorizontalAccuracyThresholdHouse;
            break;
        case YoLocationAccuracyBlock:
            return kYoHorizontalAccuracyThresholdBlock;
            break;
        case YoLocationAccuracyNeighborhood:
            return kYoHorizontalAccuracyThresholdNeighborhood;
            break;
        case YoLocationAccuracyCity:
            return kYoHorizontalAccuracyThresholdCity;
            break;
        default:
            NSAssert(NO, @"Unknown desired accuracy.");
            return 0.0;
            break;
    }
}

/**
 Completes the location request.
 */
- (void)completeLocationRequest
{
    self.hasTimedOut = YES;
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.requestStartTime = nil;
}

/**
 Cancels the location request.
 */
- (void)cancelLocationRequest
{
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.requestStartTime = nil;
}

/**
 Starts the location request's timeout timer if a nonzero timeout value is set, and the timer has not already been started.
 */
- (void)startTimeoutTimerIfNeeded
{
    if (self.timeout > 0 && !self.timeoutTimer) {
        self.requestStartTime = [NSDate date];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(timeoutTimerFired:) userInfo:nil repeats:NO];
    }
}

/**
 Dynamic property that returns how long the request has been alive (since the timeout value was set).
 */
- (NSTimeInterval)timeAlive
{
    if (self.requestStartTime == nil) {
        return 0.0;
    }
    return fabs([self.requestStartTime timeIntervalSinceNow]);
}

/**
 Returns whether the location request has timed out or not.
 Once this becomes YES, it will not automatically reset to NO even if a new timeout value is set.
 */
- (BOOL)hasTimedOut
{
    if (self.timeout > 0.0 && self.timeAlive > self.timeout) {
        _hasTimedOut = YES;
    }
    return _hasTimedOut;
}

/**
 Callback when the timeout timer fires. Notifies the delegate that this event has occurred.
 */
- (void)timeoutTimerFired:(NSTimer *)timer
{
    self.hasTimedOut = YES;
    [self.delegate locationRequestDidTimeout:self];
}

/**
 Two location requests are considered equal if their request IDs match.
 */
- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    if (((YoLocationRequest *)object).requestID == self.requestID) {
        return YES;
    }
    return NO;
}

/**
 Return a hash based on the string representation of the request ID.
 */
- (NSUInteger)hash
{
    return [[NSString stringWithFormat:@"%ld", (long) self.requestID] hash];
}

- (void)dealloc
{
    [_timeoutTimer invalidate];
}

@end
