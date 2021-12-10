//
//  YOLocationManager.m
//  Yo
//
//  Created by Peter Reveles on 10/30/14.
//
//

#import "YoLocationManager.h"
#import "YoLocationRequest.h"

@interface YoLocationManager () <CLLocationManagerDelegate, YoLocationRequestDelegate>

// The instance of CLLocationManager encapsulated by this class.
@property (nonatomic, strong) CLLocationManager *locationManager;
// The most recent current location, or nil if the current location is unknown, invalid, or stale.
// Whether or not the CLLocationManager is currently sending location updates.
@property (nonatomic, assign) BOOL isUpdatingLocation;
// Whether an error occurred during the last location update.
@property (nonatomic, assign) BOOL updateFailed;
// An array of pending location requests in the form:
// @[ YoLocationRequest *locationRequest1, YoLocationRequest *locationRequest2, ... ]
@property (nonatomic, strong) NSMutableArray *locationRequests;

@property (nonatomic, strong) CLLocation *cachedLocation;

@end


@implementation YoLocationManager

#pragma mark - Properties

/**
 Returns the most recent current location, or nil if the current location is unknown, invalid, or stale.
 */
- (CLLocation *)cachedLocation
{
    if (_cachedLocation) {
        // Location isn't nil, so test to see if it is valid
        if (_cachedLocation.coordinate.latitude == 0.0 && _cachedLocation.coordinate.longitude == 0.0) {
            // The current location is invalid; discard it and return nil
            _cachedLocation = nil;
        }
    }
    
    // Location is either nil or valid at this point, return it
    return _cachedLocation;
}

#pragma mark - Life Cycle

static id _sharedInstance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    NSAssert(_sharedInstance == nil, @"Only one instance of YOLocationManager should be created. Use +[YOLocationManager sharedInstance] instead.");
    self = [super init];
    if (self) {
        _cachedLocation = nil;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationRequests = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)didEnterBackGround:(NSNotification *)note{
    _cachedLocation = nil;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

/**
 Asynchronously requests the current location of the device using location services.
 
 @param desiredAccuracy The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout The maximum amount of time (in seconds) to wait for the desired accuracy before completing.
 If this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or cancelled).
 @param block The block to be executed when the request succeeds, fails, or times out. Three parameters are passed into the block:
 - The current location (the most recent one acquired, regardless of accuracy level), or nil if no valid location was acquired
 - The achieved accuracy for the current location (may be less than the desired accuracy if the request failed)
 - The request status (if it succeeded, or if not, why it failed)
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (NSInteger)requestLocationWithDesiredAccuracy:(YoLocationAccuracy)desiredAccuracy
                                        timeout:(NSTimeInterval)timeout
                                completionBlock:(YoLocationRequestBlock)block
{
    return [self requestLocationWithDesiredAccuracy:desiredAccuracy
                                            timeout:timeout
                               delayUntilAuthorized:NO
                                    completionBlock:block];
}

/**
 Asynchronously requests the current location of the device using location services, optionally waiting until the user grants the app permission
 to access location services before starting the timeout countdown.
 
 @param desiredAccuracy The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout The maximum amount of time (in seconds) to wait for the desired accuracy before completing.
 If this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or cancelled).
 @param delayUntilAuthorized A flag specifying whether the timeout should only take effect after the user responds to the system prompt requesting
 permission for this app to access location services. If YES, the timeout countdown will not begin until after the
 app receives location services permissions. If NO, the timeout countdown begins immediately when calling this method.
 @param block The block to be executed when the request succeeds, fails, or times out. Three parameters are passed into the block:
 - The current location (the most recent one acquired, regardless of accuracy level), or nil if no valid location was acquired
 - The achieved accuracy for the current location (may be less than the desired accuracy if the request failed)
 - The request status (if it succeeded, or if not, why it failed)
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (NSInteger)requestLocationWithDesiredAccuracy:(YoLocationAccuracy)desiredAccuracy
                                        timeout:(NSTimeInterval)timeout
                           delayUntilAuthorized:(BOOL)delayUntilAuthorized
                                completionBlock:(YoLocationRequestBlock)block
{
    NSAssert(desiredAccuracy != YoLocationAccuracyNone, @"YoLocationAccuracyNone is not a valid desired accuracy.");
    
    YoLocationRequest *locationRequest = [[YoLocationRequest alloc] init];
    locationRequest.delegate = self;
    locationRequest.desiredAccuracy = desiredAccuracy;
    locationRequest.timeout = timeout;
    locationRequest.block = block;
    
    BOOL deferTimeout = delayUntilAuthorized && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined);
    if (!deferTimeout) {
        [locationRequest startTimeoutTimerIfNeeded];
    }
    
    if (![self processRequestImmediatelyIfPossible:locationRequest])
        [self addLocationRequest:locationRequest];
    
    return locationRequest.requestID;
}

/**
 Returns YES/NO depending on the success of processing the request immediately. (location services unavailable/cahced location is suffcient)
 */
- (BOOL)processRequestImmediatelyIfPossible:(YoLocationRequest *)request{
    if ([self locationServicesAvailable] == NO || [self doesCachedLocationSatisfyRequest:request]) {
        // Don't even bother trying to do anything since location services are off or the user has
        // explcitly denied us permission to use them
        [self completeLocationRequest:request];
        return YES;
    }
    return NO;
}

#pragma mark - Internal Methods

/**
 Adds the given location request to the array of requests, and starts location updates if needed.
 */
- (void)addLocationRequest:(YoLocationRequest *)locationRequest
{
    [self startUpdatingLocationIfNeeded];
    [self.locationRequests addObject:locationRequest];
    DDLogWarn(@"Location Request added with ID: %ld", (long)locationRequest.requestID);
}

/**
 Inform CLLocationManager to start sending us updates to our location.
 */
- (void)startUpdatingLocationIfNeeded
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    // As of iOS 8, apps must explicitly request location services permissions. YoLocationManager supports both levels, "Always" and "When In Use".
    // YoLocationManager determines which level of permissions to request based on which description key is present in your app's Info.plist
    // If you provide values for both description keys, the more permissive "Always" level is requested.
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil;
        BOOL hasWhenInUseKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil;
        if (hasAlwaysKey) {
            [self.locationManager requestAlwaysAuthorization];
        } else if (hasWhenInUseKey) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            // At least one of the keys NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription MUST be present in the Info.plist file to use location services on iOS 8+.
            NSAssert(hasAlwaysKey || hasWhenInUseKey, @"To use location services in iOS 8+, your Info.plist must provide a value for either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription.");
        }
    }
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1 */
    
    // We only enable location updates while there are open location requests, so power usage isn't a concern.
    // As a result, we use the Best accuracy on CLLocationManager so that we can quickly get a fix on the location,
    // clear out the pending location requests, and then power down the location services.
    if ([self.locationRequests count] == 0) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        if (self.isUpdatingLocation == NO) {
            DDLogWarn(@"Location services started.");
        }
        self.isUpdatingLocation = YES;
    }
}

/**
 Checks to see if there are any outstanding locationRequests, and if there are none, informs CLLocationManager to stop sending
 location updates. This is done as soon as location updates are no longer needed in order to conserve the device's battery.
 */
- (void)stopUpdatingLocationIfPossible
{
    if ([self.locationRequests count] == 0) {
        [self.locationManager stopUpdatingLocation];
        if (self.isUpdatingLocation) {
            DDLogWarn(@"Location services stopped.");
        }
        self.isUpdatingLocation = NO;
    }
}

/**
 Iterates over the array of pending location requests to check and see if the most recent current location
 successfully satisfies any of their criteria.
 */
- (void)processLocationRequests{
    
    // Keep a separate array of location requests to complete to avoid modifying the locationRequests property
    // while iterating over it at the same time
    NSMutableArray *locationRequestsToComplete = [NSMutableArray array];
    
    for (YoLocationRequest *locationRequest in self.locationRequests) {
        if (locationRequest.hasTimedOut) {
            // Request has timed out, complete it
            [locationRequestsToComplete addObject:locationRequest];
            continue;
        }
        
        if ([self doesCachedLocationSatisfyRequest:locationRequest]) {
            // The request's desired accuracy has been reached, complete it
            [locationRequestsToComplete addObject:locationRequest];
            continue;
        }
    }
    
    for (YoLocationRequest *locationRequest in locationRequestsToComplete) {
        [self completeLocationRequest:locationRequest];
    }
}

- (BOOL)doesCachedLocationSatisfyRequest:(YoLocationRequest *)request{
    
    if (!self.cachedLocation) return NO;
    
    CLLocation *mostRecentLocation = self.cachedLocation;
    
    NSTimeInterval cachedLocationTimeSinceUpdate = fabs([mostRecentLocation.timestamp timeIntervalSinceNow]);
    CLLocationAccuracy cachedLocationHorizontalAccuracy = mostRecentLocation.horizontalAccuracy;
    NSTimeInterval experationThreshold = [request experationThreshold];
    CLLocationAccuracy minHorizontalAccuracyDesired =  [request minHorizontalAccuracyDesired];
    
    if (cachedLocationTimeSinceUpdate <= experationThreshold &&
        cachedLocationHorizontalAccuracy <= minHorizontalAccuracyDesired) {
        return YES;
    }
    
    return NO;
}

/**
 Immediately completes all pending location requests.
 Used in cases such as when the location services authorization status changes to Denied or Restricted.
 */
- (void)completeAllLocationRequests
{
    // Iterate through a copy of the locationRequests array to avoid modifying the same array we are removing elements from
    NSArray *locationRequests = [self.locationRequests copy];
    for (YoLocationRequest *locationRequest in locationRequests) {
        [self completeLocationRequest:locationRequest];
    }
    DDLogWarn(@"Finished completing all location requests.");
}

/**
 Completes the given location request by removing it from the array of locationRequests and executing its completion block.
 If this was the last pending location request, this method also turns off location updating.
 */
- (void)completeLocationRequest:(YoLocationRequest *)locationRequest
{
    if (locationRequest == nil)
        return;
    
    YoLocationStatus status = [self statusForLocationRequest:locationRequest];
    CLLocation *cachedLocation = self.cachedLocation;
    YoLocationAccuracy achievedAccuracy = [self achievedAccuracyForLocation:cachedLocation];
    
    [self.locationRequests removeObject:locationRequest];
    [locationRequest completeLocationRequest];
    [self stopUpdatingLocationIfPossible];
    
    // YoLocationManager is not thread safe and should only be called from the main thread, so we should already be executing on the main thread now.
    // dispatch_async is used to ensure that the completion block for a request is not executed before the request ID is returned, for example in the
    // case where the user has denied permission to access location services and the request is immediately completed with the appropriate error.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (locationRequest.block) {
            locationRequest.block(cachedLocation, achievedAccuracy, status);
        }
    });
    
    DDLogWarn(@"Location Request completed with ID: %ld, cachedLocation: %@, achievedAccuracy: %lu, status: %lu", (long)locationRequest.requestID, cachedLocation, (unsigned long) achievedAccuracy, (unsigned long)status);
}

#pragma mark - Internal Utility Methods

/**
 Returns YES if location services are enabled in the system settings, and the app has NOT been denied/restricted access. Returns NO otherwise.
 Note that this method will return YES even if the authorization status has not yet been determined.
 */
- (BOOL)locationServicesAvailable
{
    if ([CLLocationManager locationServicesEnabled] == NO) {
        return NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    return YES;
}

- (BOOL)locationServicesDenied{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return YES;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return YES;
    }
    return NO;
}

- (BOOL)locationServicesAuthorized{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
         [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
#else
    if ([[CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
#endif
        return YES;
    }
    return NO;
}

/**
 Returns the location manager status for the given location request.
 */
- (YoLocationStatus)statusForLocationRequest:(YoLocationRequest *)locationRequest
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        return YoLocationStatusServicesNotDetermined;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return YoLocationStatusServicesDenied;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return YoLocationStatusServicesRestricted;
    }
    else if ([CLLocationManager locationServicesEnabled] == NO) {
        return YoLocationStatusServicesDisabled;
    }
    else if (self.updateFailed) {
        return YoLocationStatusError;
    }
    else if (locationRequest.hasTimedOut) {
        return YoLocationStatusTimedOut;
    }
    
    return YoLocationStatusSuccess;
}

/**
 Returns the associated YoLocationAccuracy level that has been achieved for a given location,
 based on that location's horizontal accuracy and recency.
 */
- (YoLocationAccuracy)achievedAccuracyForLocation:(CLLocation *)location
{
    if (!location) return YoLocationAccuracyNone;
    
    NSTimeInterval timeSinceUpdate = fabs([location.timestamp timeIntervalSinceNow]);
    CLLocationAccuracy horizontalAccuracy = location.horizontalAccuracy;
    
    if (horizontalAccuracy <= kYoHorizontalAccuracyThresholdRoom &&
        timeSinceUpdate <= kYoUpdateTimeStaleThresholdRoom) {
        return YoLocationAccuracyRoom;
    }
    else if (horizontalAccuracy <= kYoHorizontalAccuracyThresholdHouse &&
             timeSinceUpdate <= kYoUpdateTimeStaleThresholdHouse) {
        return YoLocationAccuracyHouse;
    }
    else if (horizontalAccuracy <= kYoHorizontalAccuracyThresholdBlock &&
             timeSinceUpdate <= kYoUpdateTimeStaleThresholdBlock) {
        return YoLocationAccuracyBlock;
    }
    else if (horizontalAccuracy <= kYoHorizontalAccuracyThresholdNeighborhood &&
             timeSinceUpdate <= kYoUpdateTimeStaleThresholdNeighborhood) {
        return YoLocationAccuracyNeighborhood;
    }
    else if (horizontalAccuracy <= kYoHorizontalAccuracyThresholdCity &&
             timeSinceUpdate <= kYoUpdateTimeStaleThresholdCity) {
        return YoLocationAccuracyCity;
    }
    else {
        return YoLocationAccuracyNone;
    }
}

#pragma mark - YoLocationRequest Delegate

- (void)locationRequestDidTimeout:(YoLocationRequest *)locationRequest
{
    BOOL isRequestStillPending = NO;
    for (YoLocationRequest *pendingLocationRequest in self.locationRequests) {
        if (pendingLocationRequest.requestID == locationRequest.requestID) {
            isRequestStillPending = YES;
            break;
        }
    }
    if (isRequestStillPending) {
        [self completeLocationRequest:locationRequest];
    }
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // Received update successfully, so clear any previous errors
    self.updateFailed = NO;
    
    CLLocation *mostRecentLocation = [locations lastObject];
    self.cachedLocation = mostRecentLocation;
    
    // The updated location may have just satisfied one of the pending location requests, so process them now to check
    [self processLocationRequests];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // kCLErrorLocationUnknown - locationManger will keep trying to find location
    
    DDLogWarn(@"Location update error: %@", [error localizedDescription]);
    if (error.code != kCLErrorLocationUnknown) { // if unkown dont end request until timeout
        self.updateFailed = YES;
        
        [self completeAllLocationRequests];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self completeAllLocationRequests];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
#else
        else if (status == kCLAuthorizationStatusAuthorized) {
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1 */
            // Start the timeout timer for location requests that were waiting for authorization
            for (YoLocationRequest *locationRequest in self.locationRequests) {
                [locationRequest startTimeoutTimerIfNeeded];
            }
        }
    }

@end
