//
//  YoLocationManager.h
//  Yo
//
//  Created by Peter Reveles on 10/30/14.
//
//

#import <Foundation/Foundation.h>
#import "YoLocationConstants.h"

@interface YoLocationManager : NSObject


/** Returns the singleton instance of this class. */
+ (instancetype)sharedInstance;

/** returns NO if location services are restricted or Denied (unusable/unrequestable) */
- (BOOL)locationServicesDenied;

/**
 Returns YES if location services have been authorized to this application. Returns NO otherwise.
 */
- (BOOL)locationServicesAuthorized;

/**
 Asynchronously requests the current location of the device using location services.
 
 @param desiredAccuracy The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout The maximum amount of time (in seconds) to wait for the desired accuracy before completing.
 If this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or cancelled).
 @param block The block to execute upon success, failure, or timeout.
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (NSInteger)requestLocationWithDesiredAccuracy:(YoLocationAccuracy)desiredAccuracy
                                        timeout:(NSTimeInterval)timeout
                                completionBlock:(YoLocationRequestBlock)block;

/**
 Asynchronously requests the current location of the device using location services, optionally delaying the timeout countdown until the user has
 responded to the dialog requesting permission for this app to access location services.
 
 @param desiredAccuracy The accuracy level desired (refers to the accuracy and recency of the location).
 @param timeout The maximum amount of time (in seconds) to wait for the desired accuracy before completing.
 If this value is 0.0, no timeout will be set (will wait indefinitely for success, unless request is force completed or cancelled).
 @param delayUntilAuthorized A flag specifying whether the timeout should only take effect after the user responds to the system prompt requesting
 permission for this app to access location services. If YES, the timeout countdown will not begin until after the
 app receives location services permissions. If NO, the timeout countdown begins immediately when calling this method.
 @param block The block to execute upon success, failure, or timeout.
 
 @return The location request ID, which can be used to force early completion or cancel the request while it is in progress.
 */
- (NSInteger)requestLocationWithDesiredAccuracy:(YoLocationAccuracy)desiredAccuracy
                                        timeout:(NSTimeInterval)timeout
                           delayUntilAuthorized:(BOOL)delayUntilAuthorized
                                completionBlock:(YoLocationRequestBlock)block;


@end
