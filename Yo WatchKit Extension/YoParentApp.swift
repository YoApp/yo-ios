//
//  YoParentApp.swift
//  Yo
//
//  Created by Peter Reveles on 3/9/15.
//
//

import WatchKit

/**
    The purpose of this class is to communicate with the parent Application
    from a Watchkit application. Utility methods are provided to make requests
    for the parent app to complete on and respond to. All proccesses are run on
    a background thread in the parent application.
*/
class YoParentApp {
    // MARK: Public
    class func sendYoToUsername(username: String, includeCurrentLocation includeLocation:Bool, completionBlock: (([NSObject : AnyObject]!, NSError!) -> Void)?) {
        var userInfo: [NSString: NSObject] = [YoAssistantRequestKey:YoAssistantSendYo,
                                            YoAssistantYoUsernameKey: username,
                                            YoAssistantWithLocationBoolKey: NSNumber(bool: includeLocation)];
        performCallWithUserInfo(userInfo, completionBlock: completionBlock)
        if includeLocation == true {
            YoAnalytics.logEvent(YoEventSentYoLocation, withParameters: nil)
        }
        else {
            YoAnalytics.logEvent(YoEventSentYo, withParameters: nil)
        }
    }
    
    class func loadWithCompletionBlock(completionBlock: (([NSObject : AnyObject]!, NSError!) -> Void)?) {
        var userInfo: [NSString: NSObject] = [YoAssistantRequestKey:YoAssistantLoadParentApp]
        performCallWithUserInfo(userInfo, completionBlock: completionBlock)
    }
    
    //MARK: Private
    private class func performCallWithUserInfo(userInfo: [NSObject: AnyObject], completionBlock: (([NSObject : AnyObject]!, NSError!) -> Void)?) {
        WKInterfaceController.openParentApplication(userInfo) { (responseObject, error) -> Void in
            if completionBlock != nil {
                completionBlock!(responseObject, error)
            }
        }
    }
    
    private class func getUsersLocation(completionBlock: (CLLocation?) -> Void) {
        YoLocationManager.sharedInstance().requestLocationWithDesiredAccuracy(YoLocationAccuracy.Block, timeout: 4.0) { (usersPossibleLocation, achievedAccuracy, status) -> Void in
            var usersCurrentLocation: CLLocation? = nil
            if usersPossibleLocation != nil {
                if (achievedAccuracy.rawValue > YoLocationAccuracy.None.rawValue) {
                    if (status.rawValue == YoLocationStatus.Success.rawValue ||
                        status.rawValue == YoLocationStatus.TimedOut.rawValue ||
                        status.rawValue == YoLocationStatus.Error.rawValue) {
                            usersCurrentLocation = usersPossibleLocation;
                    }
                }
            }
            completionBlock(usersCurrentLocation)
        }
    }
}
