//
//  PhotoNotificationController.swift
//  Yo
//
//  Created by Peter Reveles on 3/6/15.
//
//

import WatchKit

class PhotoNotificationController: NotificationController {
    // MARK: - Properties
    @IBOutlet weak var imageContainer: WKInterfaceImage!
    
    // MARK: - Setup
    // overriding parent function to customize setup for location yo
    override func setupForYo(yo: Yo) {
        // allow parent to setup
        super.setupForYo(yo)
        // custom setup
        if yo.url != nil {
            var photoURL: NSURL? = getPhotoURL()
            if (photoURL != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    YoNetworkAssistant.pullImageFromURL(photoURL!, withCompletionBlock: { (image) -> Void in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if image != nil {
                                self.setImage(image!)
                            }
                        })
                    })
                })
            }
        }
    }
    
    func setImage(image: UIImage) {
        imageContainer?.setHidden(false)
        imageContainer?.setImage(image)
    }
    
    // MARK: Subclass Overrides
    override func getYoDescriptionText() -> String {
        return NSLocalizedString("Photo from", comment: "")
    }
    
    override func shouldMarkYoAsRead() -> Bool {
        return true
    }
    
    /**
    Subclasses should overwrite to specify which url to user as photo url
    */
    func getPhotoURL() -> NSURL? {
        return yo?.url
    }
}
