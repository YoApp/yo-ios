//
//  InboxInterfaceController.swift
//  Yo
//
//  Created by Peter Reveles on 4/1/15.
//
//

import WatchKit
import Foundation


class YoInboxInterfaceController: WKInterfaceController {
    // MARK: Life
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if YoApp.currentSession().isLoggedIn {
            // always load every time controller becomes active
            updateInbox()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: Model
    func loadInbox() {
        updateInboxGUI()
    }
    
    func updateInbox() {
        weak var weakSelfOptional: YoInboxInterfaceController? = self
        YoApp.currentSession().user.yoInbox.updateWithCompletionBlock({ (success) -> Void in
            if let weakSelf = weakSelfOptional {
                weakSelf.updateInboxGUI()
            }
        })
    }
    
    // MARK: UI
    private func updateInboxGUI() {
        clearAllMenuItems()
        let yosInQueue: NSArray = YoApp.currentSession().user.yoInbox.getYosWithStatus(YoStatus.Received)
        let title = "\(yosInQueue.count) " + GetYoInboxSufficForYoCount(yosInQueue.count).capitalizedString
        addMenuItemWithImageNamed("InboxIcon",
            title: title,
            action: "presentYoInbox")
    }
    
    // MARK: Internal Naviagtion
    func presentYoInbox() {
        let yosInQueue: NSArray = YoApp.currentSession().user.yoInbox.getYosWithStatus(YoStatus.Received)
        var IDsOfControllersToPresent: [AnyObject] = []
        if yosInQueue.count > 0 {
            for obj in yosInQueue {
                if let yo = obj as? Yo {
                    //let yo: Yo = Yo(pushPayload: yoData)
                    let controllerIDForYo = controllerIDForYoCategory(yo.category)
                    if controllerIDForYo != nil {
                        IDsOfControllersToPresent.append(controllerIDForYo!)
                        IDsOfControllersToPresent.count
                    }
                }
            }
        }
        if IDsOfControllersToPresent.count > 0 {
            presentControllerWithNames(IDsOfControllersToPresent as! [String], contexts: yosInQueue as [AnyObject])
        }
    }
    
    // MARK: Utility
    private func controllerIDForYoCategory(category: String?) -> String? {
        if category == nil {
            // default to just yo controller
            return YoViewInterfaceController.getIdentifier()
        }
        else {
            if category! == kYoCategoryLink || category! == kYoCategoryServiceLink {
                return YoLinkViewInterfaceController.getIdentifier()
            }
            else if category! == kYoCategoryLocation || category! == kYoCategoryServiceLocation {
                return YoLocationViewInterfaceController.getIdentifier()
            }
            else if category! == kYoCategoryPhoto || category! == kYoCategoryServicePhoto {
                return YoPhotoViewInterfaceController.getIdentifier()
            }
            else {
                return YoViewInterfaceController.getIdentifier()
            }
        }
    }
    
    // MARK: Handoff
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        super.handleUserActivity(userInfo)
        
        let activity: String? = userInfo?[YoActivityKey] as? String
        if activity == YoActivityIdentifierViewingGlance {
            // If User was viewing glance they should now be shown their inbox
            loadInbox()
            presentYoInbox()
            YoAnalytics.logEvent(YoEventWatchExtensionLaunchedFromGlance, withParameters: nil)
        }
        
        // return the controller you wish to be opened instead of the main controller.
        // or nil to open main controller
    }

}
