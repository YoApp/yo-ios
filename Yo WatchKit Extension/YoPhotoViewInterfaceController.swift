//
//  YoLinkViewInterfaceController.swift
//  Yo
//
//  Created by Peter Reveles on 3/4/15.
//
//

import WatchKit

class YoPhotoViewInterfaceController: YoViewInterfaceController {
    // MARK: Properties
    @IBOutlet weak var photoGroup: WKInterfaceGroup!
    
    @IBOutlet weak var imageContainer: WKInterfaceImage!
    
    var photo: UIImage? = nil
    // MARK: Life
    override init() {
        super.init()
        // static setup
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    private func updateUIWithImage(image: UIImage?) {
        if image != nil {
            //self.photoGroup.setBackgroundImage(image!)
            self.imageContainer.setImage(image!)
            self.photoGroup.setHidden(false)
        }
    }
    
    override func willActivate() {
        super.willActivate()
        let photoURL = getPhotoURL()
        if photoURL != nil {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                YoNetworkAssistant.pullImageFromURL(self.yo!.url, withCompletionBlock: { (image) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateUIWithImage(image)
                        self.photo = image
                    })
                })
            })
        }
    }
    
    // MARK: Override Methods
    override func getYoDescriptionForYo(yo: Yo) -> String {
        return NSLocalizedString("Photo from", comment: "as in Yo Photo From {USERNAME}")
    }
    
    override func shouldMarkYoAsReadActivation() -> Bool {
        return true
    }
    
    /**
    Subclasses should overwrite to specify which url to user as photo url
    */
    func getPhotoURL() -> NSURL? {
        return yo?.url
    }
    
    // MARK - Class Methods
    override class func getIdentifier() -> String {
        return "YoPhotoViewInterfaceControllerID"
    }
}