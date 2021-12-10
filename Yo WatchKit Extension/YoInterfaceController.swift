//
//  InterfaceController.swift
//  Yo WatchKit Extension
//
//  Created by Peter Reveles on 2/28/15.
//
//

import WatchKit
import Foundation

class YoInterfaceController: YoInboxInterfaceController {
    // MARK: Properties
    @IBOutlet weak var tableView: WKInterfaceTable!
    var contacts: [AnyObject]? = nil
    private var usernamesToYo: NSMutableArray = []
    
    @IBOutlet weak var alertMessageUIGroup: WKInterfaceGroup!
    // appears in alertMessageUIGroup
    @IBOutlet weak var alertLabel: WKInterfaceLabel!
    
    // MARK: - Life
    
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        NSLog("%@ init", self)
        YoApp.currentSession().load()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        NSLog("%@ will activate", self)
        YoApp.currentSession().load() // update on evrey activation to stay up-to-date
        updateUI()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
    }
    
    // MARK: Data Management
    
    private func loadContactsWithCompletionBlock(completionBlock: (() -> Void)?) {
        contacts = YoUser.me().list()
        weak var weakSelf: YoInterfaceController? = self
        YoUser.me().contactsManager.updateContactsWithCompletionBlock({ (didUpdateContacts) -> Void in
            if weakSelf != nil {
                weakSelf!.contacts = YoUser.me().list()
                if (completionBlock != nil) {
                    completionBlock!();
                }
            }
        })
    }
    
    // MARK: UI
    
    private func updateUI() {
        if YoApp.currentSession().isLoggedIn {
            weak var weakSelf: YoInterfaceController? = self
            loadContactsWithCompletionBlock { () -> Void in
                if weakSelf != nil {
                    if weakSelf!.contacts != nil &&
                        weakSelf!.contacts?.count > 0 {
                            weakSelf!.reloadTableView()
                    }
                    else {
                        weakSelf!.showAlertForCurrentState()
                    }
                }
            }
        }
        else {
            showAlertForCurrentState()
        }
    }
    
    private func showStaticAlertWithMessage(messgae: String) {
        self.alertLabel.setText(messgae)
        self.alertMessageUIGroup.setHidden(false)
        self.tableView.setHidden(true)
    }
    
    private func showAlertForCurrentState() {
        if YoApp.currentSession().isLoggedIn {
            if contacts == nil || contacts!.count == 0 {
                showStaticAlertWithMessage(YoNoContactsPrompt)
            }
            else {
                tableView.setHidden(false)
            }
        }
        else {
            showStaticAlertWithMessage(YoLoggedOutPrompt)
        }
    }
    
    // MARK: - handle tableview
    
    private func reloadTableView() {
        tableView.setNumberOfRows(contacts!.count, withRowType: YoUserRowController.getIdentifier())
        loadTableView(contacts!)
    }
    
    private func loadTableView(contacts :NSArray) {
        // Iterate over the rows and set the label for each one.
        for var i = 0; i < contacts.count; i++ {
            // Get the to-do item data.
            let object: YoModelObject? = contacts[i] as? YoModelObject;
            
            // Assign the text to the row's label.
            let row: YoUserRowController? = tableView.rowControllerAtIndex(i) as? YoUserRowController
            row!.object = object
            
            // set backgroundcolor
            let backgroundColor = UIColor().colorForIndex(i)
            row?.group.setBackgroundColor(backgroundColor)
        }
        self.alertMessageUIGroup.setHidden(true)
        self.tableView.setHidden(false)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if (table.isEqual(self.tableView)) {
            let rowController: YoUserRowController? = self.tableView.rowControllerAtIndex(rowIndex) as? YoUserRowController
            if rowController == nil || rowController!.isFlashingText {
                return
            }
            let object: YoModelObject = contacts![rowIndex] as! YoModelObject
            let username: String = object.username
            if self.usernamesToYo.containsObject(username) {
                // double tap sends Yo Location
                self.usernamesToYo.removeObject(username)
                YoParentApp.sendYoToUsername(username, includeCurrentLocation: true, completionBlock: nil)
                self.flashTextInRowController(YoSentYoLocationText, rowController: rowController!, completionBlock: nil)
            }
            else {
                self.usernamesToYo.addObject(username)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(YoTimeForDoubleTap * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    if self.usernamesToYo.containsObject(username) {
                        self.usernamesToYo.removeObject(username)
                        // single tap send standard yo
                        YoParentApp.sendYoToUsername(username, includeCurrentLocation: false, completionBlock: nil)
                        self.flashTextInRowController(YoSentYoText, rowController: rowController!, completionBlock: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Internal
    private func flashTextInRowController(text: String, rowController: YoUserRowController, completionBlock: (() -> Void)?) {
        weak var weakSelf:YoInterfaceController? = self
        rowController.flashText(YoTimeForTextFlash, text: text, completionBlock: { () -> Void in
            if completionBlock != nil {
                completionBlock!()
            }
        })
    }
    
    // MARK: - handling handoff
    /*
    override func actionForUserActivity(userActivity: [NSObject : AnyObject]?, context: AutoreleasingUnsafeMutablePointer<AnyObject?>) -> String? {
        println("Watch App launched from handoff")
        
        let activity: String? = userActivity?[YoActivityKey] as? String
        if activity == YoActivityIdentifierViewingGlance {
            // If User was viewing glance they should now be shown their inbox
            self.launchedFromGlance = true
        }
        
        // return the controller you wish to be opened instead of the main controller.
        // or nil to open main controller
        return nil
    }
    */
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]?) {
        super.handleUserActivity(userInfo)
        print("Watch App launched from handoff")
        
        // return the controller you wish to be opened instead of the main controller.
        // or nil to open main controller
    }
}
