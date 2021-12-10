//
//  GlanceController.swift
//  Yo WatchKit Extension
//
//  Created by Peter Reveles on 2/28/15.
//
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {
    // MARK: Properties
    @IBOutlet weak var newYoCountLabel: WKInterfaceLabel!
    @IBOutlet weak var newYoCountDescriptionLabel: WKInterfaceLabel!
    
    @IBOutlet weak var activityIndicaterImage: WKInterfaceImage!
    
    @IBOutlet weak var yoCountGroup: WKInterfaceGroup!
    
    @IBOutlet weak var staticAlertUIGroup: WKInterfaceGroup!
    @IBOutlet weak var staticAlertMessageLabel: WKInterfaceLabel!
    
    @IBOutlet weak var locationYoGroup: WKInterfaceGroup!
    
    @IBOutlet weak var locationYoCount: WKInterfaceLabel!
    
    @IBOutlet weak var locationYoCountDescription: WKInterfaceLabel!
    
    @IBOutlet weak var photoGroup: WKInterfaceGroup!
    
    @IBOutlet weak var photoYoCount: WKInterfaceLabel!
    
    @IBOutlet weak var photoYoCountDescription: WKInterfaceLabel!
    
    @IBOutlet weak var linkYoGroup: WKInterfaceGroup!
    
    @IBOutlet weak var linkYoCount: WKInterfaceLabel!
    
    @IBOutlet weak var linkYoDesciption: WKInterfaceLabel!
    
    var loadingStatus: YoLoadingStatus
    
    // MARK: Life
    override init() {
        // Initialize variables here.
        loadingStatus = .Unstarted
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
        
        YoApp.currentSession().load()
        updateUI()
        if YoApp.currentSession().isLoggedIn {
            refreshYoStatsOnDisplay()
            weak var weakSelfOptional = self
            loadingStatus = YoLoadingStatus.InProgress
            YoApp.currentSession().user?.yoInbox.updateWithCompletionBlock { (success) -> Void in
                if let weakSelf = weakSelfOptional {
                    weakSelf.loadingStatus = YoLoadingStatus.Complete
                    if success {
                        weakSelf.refreshYoStatsOnDisplay()
                    }
                }
            }
        }
    }
    
    internal func refreshYoStatsOnDisplay() {
        let (locationYoCount, photoYoCount, linkYoCount, totalYoCount) = getAllYoCountData()
        // setup new yo labels
        self.newYoCountDescriptionLabel.setText(GetYoInboxSufficForYoCount(totalYoCount).capitalizedString)
        self.newYoCountLabel.setText(String(totalYoCount))
        // locations
        self.locationYoCountDescription.setText(GetYoLocationSufficForYoCount(locationYoCount).capitalizedString)
        self.locationYoCount.setText(String(locationYoCount))
        // photos
        self.photoYoCountDescription.setText(GetYoPhotoSufficForYoCount(photoYoCount).capitalizedString)
        self.photoYoCount.setText(String(photoYoCount))
        // links
        self.linkYoDesciption.setText(GetYoLinkSufficForYoCount(linkYoCount).capitalizedString)
        self.linkYoCount.setText(String(linkYoCount))
    }
    
    private func updateUI() {
        if YoApp.currentSession().isLoggedIn {
            showYoStats()
        }
        else {
            showStaticAlertWithMessage(YoLoggedOutPrompt)
        }
    }
    
    private func showStaticAlertWithMessage(messgae: String) {
        self.staticAlertMessageLabel.setText(messgae)
        self.staticAlertUIGroup.setHidden(false)
        self.yoCountGroup.setHidden(true)
    }
    
    private func showYoStats() {
        self.staticAlertUIGroup.setHidden(true)
        self.yoCountGroup.setHidden(false)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
        
        YoApp.currentSession().load()
        updateUI()
        
        if YoApp.currentSession().isLoggedIn {
            if loadingStatus != YoLoadingStatus.InProgress {
                refreshYoStatsOnDisplay()
                weak var weakSelfOptional = self
                loadingStatus = YoLoadingStatus.InProgress
                YoApp.currentSession().user?.yoInbox.updateWithCompletionBlock { (success) -> Void in
                    if let weakSelf = weakSelfOptional {
                        weakSelf.loadingStatus = YoLoadingStatus.Complete
                        weakSelf.refreshYoStatsOnDisplay()
                    }
                }
            }
        }
        
        updateUserActivity(YoActivityIdentifierViewingGlance, userInfo: [YoActivityKey:YoActivityIdentifierViewingGlance], webpageURL: nil)
        YoAnalytics.logEvent(YoEventWatchExtensionGlanceBecameActive, withParameters: nil)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
        YoAnalytics.logEvent(YoEventWatchExtensionGlanceBecameActive, withParameters: nil)
    }
    
    //  MARK: Interal
    func getAllYoCountData() -> (locationYoCount: NSInteger, photoYoCount: NSInteger, linkYoCount: NSInteger, totalYoCount: NSInteger) {
        var locationYoCount = 0
        var photoYoCount = 0
        var linkYoCount = 0
        var totalYoCount = 0
        let yos = YoApp.currentSession().user.yoInbox.getYosWithStatus(YoStatus.Received)
        if yos != nil {
            for (_, obj) in yos.enumerate() {
                if let yo = obj as? Yo {
                    if yo.category! == kYoCategoryLink || yo.category! == kYoCategoryServiceLink {
                        linkYoCount++
                    }
                    else if yo.category! == kYoCategoryLocation || yo.category! == kYoCategoryServiceLocation {
                        locationYoCount++
                    }
                    else if yo.category! == kYoCategoryPhoto || yo.category! == kYoCategoryServicePhoto {
                        photoYoCount++
                    }
                    totalYoCount++
                }
            }
        }
        return (locationYoCount, photoYoCount, linkYoCount, totalYoCount)
    }
}
