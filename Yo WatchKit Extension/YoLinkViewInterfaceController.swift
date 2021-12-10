//
//  YoLinkViewInterfaceController.swift
//  Yo
//
//  Created by Peter Reveles on 3/5/15.
//
//

import WatchKit

class YoLinkViewInterfaceController: YoPhotoViewInterfaceController {
    // MARK: Life
    override init() {
        super.init()
        // setup
        // tell parent app to load image, once parent replies display image
    }
    
    override func getPhotoURL() -> NSURL? {
        return self.yo?.coverURL
    }
    
    // MARK: Override Methods
    override func getYoDescriptionForYo(yo: Yo) -> String {
        return NSLocalizedString("Link from", comment: "as in Yo Link From {USERNAME}")
    }
    
    override func shouldMarkYoAsReadActivation() -> Bool {
        return false
    }
    
    // MARK - Class Methods
    override class func getIdentifier() -> String {
        return "YoLinkViewInterfaceControllerID"
    }
}
