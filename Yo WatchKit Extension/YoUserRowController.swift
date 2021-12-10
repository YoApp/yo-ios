//
//  YoCellController.swift
//  Yo
//
//  Created by Peter Reveles on 2/28/15.
//
//

import UIKit
import WatchKit

class YoUserRowController: NSObject {
    @IBOutlet var displayNameLabel: WKInterfaceLabel!
    @IBOutlet var group: WKInterfaceGroup!
    internal var isFlashingText: Bool = false
    let timeForTextFlash: Double = 2.0
    
    var object: YoModelObject? = nil {
        didSet {
            updateDisplayName()
        }
    }
    
    func updateDisplayName() {
            self.displayNameLabel.setText(object!.displayName)
    }
    
    internal func setTitleLabelText(text: String) {
        displayNameLabel.setText(text)
    }
    
    internal func setColor(color: UIColor) {
        self.group.setBackgroundColor(color)
    }
    
    internal func flashText(duration: NSTimeInterval, text: String, completionBlock: (() -> Void)?) {
        if self.isFlashingText && completionBlock != nil {
            completionBlock!()
        }
        self.isFlashingText = true
        self.displayNameLabel.setText(text)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeForTextFlash * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.updateDisplayName()
            self.isFlashingText = false
            if completionBlock != nil {
                completionBlock!()
            }
        }
    }
    
    class func getIdentifier() -> String {
        return "YoUserRowControllerID"
    }
}
