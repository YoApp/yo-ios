//
//  LinkNotificationController.swift
//  Yo
//
//  Created by Peter Reveles on 3/6/15.
//
//

import WatchKit

class LinkNotificationController: PhotoNotificationController {
    // MARK: Subclass Overrides
    override func getYoDescriptionText() -> String {
        return NSLocalizedString("Link from", comment: "")
    }
    
    override func shouldMarkYoAsRead() -> Bool {
        return false
    }
    
    override func getPhotoURL() -> NSURL? {
        return yo?.coverURL
    }
}
