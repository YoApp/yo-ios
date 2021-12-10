//
//  YoLocationRequest.h
//  Yo
//
//  Created by Peter Reveles on 11/10/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "YoLocationConstants.h"

@class CLLocation;
@class YoLocationRequest;

/**
 Protocol for the INTULocationRequest to notify the its delegate that a request has timed out.
 */
@protocol YoLocationRequestDelegate

/**
 Notification that a location request has timed out.
 
 @param locationRequest The location request that timed out.
 */
- (void)locationRequestDidTimeout:(YoLocationRequest *)locationRequest;

@end


/**
 Represents a geolocation request that is created and managed by INTULocationManager.
 */
@interface YoLocationRequest : NSObject

// The delegate for this location request.
@property (nonatomic, weak) id <YoLocationRequestDelegate> delegate;

// The request ID for this location request (set during initialization).
@property (nonatomic, readonly) NSInteger requestID;

// The desired accuracy for this location request.
@property (nonatomic, assign) YoLocationAccuracy desiredAccuracy;

// The maximum amount of time the location request should be allowed to live before completing.
// If this value is exactly 0.0, it will be ignored (the request will never timeout by itself).
@property (nonatomic, assign) NSTimeInterval timeout;

// How long the location request has been alive since the timeout value was last set.
@property (nonatomic, readonly) NSTimeInterval timeAlive;

// Whether this location request has timed out (will also be YES if it has been completed).
@property (nonatomic, readonly) BOOL hasTimedOut;

// The block to execute when the location request completes.
@property (nonatomic, copy) YoLocationRequestBlock block;

/** Completes the location request. */
- (void)completeLocationRequest;

/** Cancels the location request. */
- (void)cancelLocationRequest;

/** Starts the location request's timeout timer if a nonzero timeout value is set, and the timer has not already been started. */
- (void)startTimeoutTimerIfNeeded;

/** Returns the associated recency threshold (in seconds) for the location request's desired accuracy level. */
- (NSTimeInterval)experationThreshold;

/** Returns the associated horizontal accuracy threshold (in meters) for the location request's desired accuracy level. */
- (CLLocationAccuracy)minHorizontalAccuracyDesired;

@end
