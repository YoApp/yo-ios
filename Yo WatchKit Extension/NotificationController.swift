//
//  NotificationController.swift
//  Yo WatchKit Extension
//
//  Created by Peter Reveles on 2/28/15.
//
//

import WatchKit
import Foundation

/**
    A notification controller for Dynamic Yo UI
*/
class NotificationController: WKUserNotificationInterfaceController {
    // MARK: - Properties    
    @IBOutlet weak var yoDescriptionLabel: WKInterfaceLabel!
    @IBOutlet weak var usernameLabel: WKInterfaceLabel!
    
    var yo: Yo? = nil
    
    // MARK: - Life
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
        if shouldMarkYoAsRead() {
            markAsRead()
        }
        var yoID = yo?.yoID
        if yoID == nil {
            yoID = "Yo ID not found."
        }
        YoAnalytics.logEvent(YoEventWatchExtensionUserOpenedDynamicYo, withParameters: nil)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
        hideYoFromHandoffDevices()
    }
    
    // MARK: Yo Inbox
    private func markAsRead() {
        if self.yo != nil {
            YoApp.currentSession().load()
            if YoApp.currentSession().user != nil {
                self.yo?.openedFromPush = true
                YoApp.currentSession().user.yoInbox.updateOrAddYo(yo!, withStatus: YoStatus.Read)
            }
        }
    }
    
    // MAKR: Handoff
    
    func makeYoVisibleToHandoffDevices(yo: Yo) {
        updateUserActivity(YoActivityIdentifierViewingYo, userInfo: ["yo":yo.payload], webpageURL: nil)
    }
    
    func hideYoFromHandoffDevices() {
        invalidateUserActivity()
    }
    
    // MARK: Setup
    /**
        Sets up basic display for Yo. Override to implent custom UI. Call super.
    */
    internal func setupForYo(yo: Yo) {
        if yo.senderUsername != nil {
            self.usernameLabel?.setText(yo.senderUsername!)
            self.yoDescriptionLabel?.setText(self.getYoDescriptionText())
        }
        else {
            // If no sender username setup to display whatever the message is
            // in the future this should have its own Yo category and have custom UI
            setupToDisplayMessage(yo.displayText!)
        }
        makeYoVisibleToHandoffDevices(yo)
    }
    
    private func setupToDisplayMessage(message: String) {
        self.yoDescriptionLabel?.setText(message)
        self.usernameLabel.setHidden(true)
    }
    
    // MARK: Subclassing methods
    
    /**
    Subclasses should override to specifiy wether their Yo should be marked
    as read on activiation. Defaults to true
    */
    func shouldMarkYoAsRead() -> Bool {
        return true
    }
    
    /**
    Override to set your own yo description text (ex. "from")
    */
    func getYoDescriptionText() -> String {
        return NSLocalizedString("from", comment: "")
    }
    
    // MARK: - WKUserNotificationInterfaceController
    override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        // This method is called when a local notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification inteface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        
        var interfaceTypeToTake = WKUserNotificationInterfaceType.Custom
        
        if localNotification.userInfo != nil {
            let yo: Yo? = Yo(pushPayload: localNotification.userInfo)
            if yo != nil {
                self.yo = yo!
                setupForYo(yo!)
            }
            else {
                interfaceTypeToTake = WKUserNotificationInterfaceType.Default
            }
        }
        else {
            interfaceTypeToTake = WKUserNotificationInterfaceType.Default
        }
        
        completionHandler(interfaceTypeToTake)
    }

    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
        // This method is called when a remote notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification inteface as quickly as possible.
        //
        // After populating your dynamic notification interface call the completion block.
        
        var interfaceTypeToTake = WKUserNotificationInterfaceType.Custom
        
        let yo: Yo? = Yo(pushPayload: remoteNotification)
        if yo != nil {
            self.yo = yo!
            setupForYo(yo!)
        }
        else {
            interfaceTypeToTake = WKUserNotificationInterfaceType.Default
        }
        
        completionHandler(interfaceTypeToTake)
    }
}
