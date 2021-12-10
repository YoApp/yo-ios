//
//  YoViewInterfaceController.swift
//  Yo
//
//  Created by Peter Reveles on 3/2/15.
//
//

import WatchKit

//
class YoViewInterfaceController: WKInterfaceController {
    // Mark: Properties
    @IBOutlet weak var yoDescriptionLabel: WKInterfaceLabel!
    @IBOutlet weak var usernameLabel: WKInterfaceLabel!
    
    @IBOutlet weak var yoBackButtonsGroup: WKInterfaceGroup!
    
    @IBOutlet weak var yoBackButton: WKInterfaceButton!
    
    @IBOutlet weak var yoBackLocationButtonLabel: WKInterfaceLabel!
    
    var isYoing: Bool = false
    var isYoingLocation: Bool = false
    
    var yo: Yo? = nil
    var hasClearedYoFromQueue: Bool = false
    
    // Mark: Life
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
        
        let closeText = NSLocalizedString("close", comment: "").capitalizedString
        self.setTitle(closeText)
        
        self.yoBackButton.setTitle(YoBackText.capitalizedString)
        self.yoBackLocationButtonLabel.setText(YoBackLocationText.capitalizedString)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Setup
        NSLog("%@ init", self)
        if context != nil {
            if let yoOptional = context as? Yo {
                yo = yoOptional
                setupForYo(yo)
            }
        }
    }
    
    private func setupForYo(yo: Yo?) {
        if yo != nil {
            // oh yeah. ;)
            let username: String? = yo!.senderUsername as String
            if username != nil && username!.characters.count > 0 {
                self.usernameLabel.setText(username)
            }
            if yoBackButtonsGroup != nil && yo!.isFromService {
                // @peter: decision was made to not show response actions
                // for services no matter the content
                yoBackButtonsGroup!.setHidden(true)
            }
            self.yoDescriptionLabel.setText(getYoDescriptionForYo(yo!))
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
        clearYoFromQueueIfNeeded()
        if yo != nil {
            makeYoVisibleToHandoffDevices(yo!)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
        hideYoFromHandoffDevices()
    }
    
    private func clearYoFromQueueIfNeeded() {
        if shouldMarkYoAsReadActivation() {
            if self.yo != nil && !self.hasClearedYoFromQueue {
                self.hasClearedYoFromQueue = true
                self.yo?.openedFromPush = true
                YoApp.currentSession().user.yoInbox.updateOrAddYo(yo!, withStatus: YoStatus.Read)
            }
        }
    }
    
    // MARK: Subclassing methods
    
    /**
    Subclasses should override to specifiy wether their Yo should be marked
    as read on activiation. Defaults to true
    */
    func shouldMarkYoAsReadActivation() -> Bool {
        return true
    }
    
    /**
    Overide this method to provide your own Yo Description text. (ex. Location from)
    */
    func getYoDescriptionForYo(yo: Yo) -> String {
        return NSLocalizedString("from", comment: "as in Yo from {USERNAME}")
    }
    
    // MARK: Handoff
    
    func makeYoVisibleToHandoffDevices(yo: Yo) {
        updateUserActivity(YoActivityIdentifierViewingYo, userInfo: ["yo":yo.payload], webpageURL: nil)
    }
    
    func hideYoFromHandoffDevices() {
        invalidateUserActivity()
    }
    
    // MARK: Actions
    @IBAction private func didPressYoBackButton() {
        sendYoAndIncludeLocation(false)
    }
    
    @IBAction private func didPressYoBackLocationButton() {
        sendYoAndIncludeLocation(true)
    }
    
    private func sendYoAndIncludeLocation(includeLocation: Bool) {
        let username: String? = yo!.senderUsername as String
        if username != nil && username!.characters.count > 0 {
            if includeLocation && !self.isYoingLocation {
                YoParentApp.sendYoToUsername(username!, includeCurrentLocation: true, completionBlock: nil)
                self.isYoingLocation = true
                self.yoBackLocationButtonLabel.setText(YoSentYoLocationText)
            }
            else if !self.isYoing {
                YoParentApp.sendYoToUsername(username!, includeCurrentLocation: false, completionBlock: nil)
                self.isYoing = true
                self.yoBackButton.setTitle(YoSentYoText)
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(YoTimeForTextFlash * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            if includeLocation {
                self.yoBackLocationButtonLabel.setText(YoBackLocationText.capitalizedString)
                self.isYoingLocation = false
                
            }
            else {
                self.yoBackButton.setTitle(YoBackText.capitalizedString)
                self.isYoing = false
            }
        }
    }
    
    // MARK - Class Methods
    class func getIdentifier() -> String {
        return "YoViewInterfaceControllerID"
    }
}
