//
//  YoLocationViewInterfaceController.swift
//  Yo
//
//  Created by Peter Reveles on 3/3/15.
//
//

import WatchKit

class YoLocationViewInterfaceController: YoViewInterfaceController {
    // Mark: Properties
    @IBOutlet weak var interfaceMap: WKInterfaceMap!
    
    // Mark: Life
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // setup with context
        setupMap()
    }
    
    private func setupMap() {
        if self.yo?.location != nil {
            let coordinate = yo!.location.coordinate
            self.interfaceMap.addAnnotation(coordinate, withPinColor: YoLocationPinColor)
            let region = MKCoordinateRegionMake(coordinate, YoLocationVisableRegionSpan)
            self.interfaceMap.setRegion(region)
        }
    }
    
    // MARK: Override Methods
    override func getYoDescriptionForYo(yo: Yo) -> String {
        return NSLocalizedString("Location from", comment: "as in Yo Location From {USERNAME}")
    }
    
    override func shouldMarkYoAsReadActivation() -> Bool {
        return true
    }
    
    // MARK - Class Methods
    override class func getIdentifier() -> String {
        return "YoLocationViewInterfaceControllerID"
    }
}
