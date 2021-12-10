//
//  LocationNotificationController.swift
//  Yo
//
//  Created by Peter Reveles on 3/6/15.
//
//

import WatchKit

class LocationNotificationController: NotificationController {
    //MARK: - Properties
    @IBOutlet weak var map: WKInterfaceMap!
    
    // MARK: Setup
    // overriding parent function to customize setup for location yo
    override func setupForYo(yo: Yo) {
        // allow parent to setup
        super.setupForYo(yo)
        // custom setup
        if yo.location != nil {
            self.map.addAnnotation(yo.location!.coordinate, withPinColor: YoLocationPinColor)
            let region = MKCoordinateRegionMake(yo.location!.coordinate, YoLocationVisableRegionSpan)
            self.map.setRegion(region)
            self.map.setHidden(false)
        }
    }
    
    // MARK: Subclass Overrides
    override func shouldMarkYoAsRead() -> Bool {
        return true
    }
    
    override func getYoDescriptionText() -> String {
        return NSLocalizedString("Location from", comment: "")
    }
}
