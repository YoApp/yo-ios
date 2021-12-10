//
//  YoLocationConstants.h
//  Yo
//
//  Created by Peter Reveles on 11/10/14.
//
//

#ifndef Yo_YoLocationConstants_h
#define Yo_YoLocationConstants_h

@class CLLocation;

#define kYoHorizontalAccuracyThresholdCity            6000.0  // in meters
#define kYoHorizontalAccuracyThresholdNeighborhood    1000.0  // in meters
#define kYoHorizontalAccuracyThresholdBlock           125.0   // in meters
#define kYoHorizontalAccuracyThresholdHouse           15.0    // in meters
#define kYoHorizontalAccuracyThresholdRoom            5.0     // in meters

#define kYoUpdateTimeStaleThresholdCity               600.0   // in seconds
#define kYoUpdateTimeStaleThresholdNeighborhood       300.0   // in seconds
#define kYoUpdateTimeStaleThresholdBlock              60.0    // in seconds
#define kYoUpdateTimeStaleThresholdHouse              15.0    // in seconds
#define kYoUpdateTimeStaleThresholdRoom               5.0     // in seconds

// An abstraction of both the horizontal accuracy and recency of location data.
// Room is the highest level of accuracy/recency; City is the lowest level.
typedef NS_ENUM(NSInteger, YoLocationAccuracy) {
    /* Not valid as a desired accuracy. */
    YoLocationAccuracyNone = 0,     // Inaccurate (>5000 meters, received >10 minutes ago)
    
    /* These options are valid desired accuracies. */
    YoLocationAccuracyCity,         // 6000 meters or better, received within the last 10 minutes  -- lowest accuracy
    YoLocationAccuracyNeighborhood, // 1000 meters or better, received within the last 5 minutes
    YoLocationAccuracyBlock,        // 125 meters or better, received within the last 1 minute
    YoLocationAccuracyHouse,        // 15 meters or better, received within the last 15 seconds
    YoLocationAccuracyRoom,         // 5 meters or better, received within the last 5 seconds      -- highest accuracy
};

typedef NS_ENUM(NSInteger, YoLocationStatus) {
    /* These statuses will accompany a valid location. */
    YoLocationStatusSuccess = 0,  // got a location and desired accuracy level was achieved successfully
    YoLocationStatusTimedOut,     // got a location, but desired accuracy level was not reached before timeout
    
    /* These statuses indicate some sort of error, and will accompany a nil location. */
    YoLocationStatusServicesNotDetermined, // user has not responded to the permissions dialog
    YoLocationStatusServicesDenied,        // user has explicitly denied this app permission to access location services
    YoLocationStatusServicesRestricted,    // user does not have ability to enable location services (e.g. parental controls, corporate policy, etc)
    YoLocationStatusServicesDisabled,      // user has turned off device-wide location services from system settings
    YoLocationStatusError                  // an error occurred while using the system location services
};

/**
 A block type for a location request, which is executed when the request succeeds, fails, or times out.
 
 @param currentLocation The most recent & accurate current location available when the block executes, or nil if no valid location is available.
 @param achievedAccuracy The accuracy level that was actually achieved (may be better than, equal to, or worse than the desired accuracy).
 @param status The status of the location request - whether it succeeded, timed out, or failed due to some sort of error. This can be used to
 understand what the outcome of the request was, decide if/how to use the associated currentLocation, and determine whether other
 actions are required (such as displaying an error message to the user, retrying with another request, quietly proceeding, etc).
 */
typedef void(^YoLocationRequestBlock)(CLLocation *currentLocation, YoLocationAccuracy achievedAccuracy, YoLocationStatus status);


#endif
