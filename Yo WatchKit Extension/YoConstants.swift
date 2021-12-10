//
//  YoConstants.swift
//  Yo
//
//  Created by Peter Reveles on 3/4/15.
//
//

import Foundation
import WatchKit

// MARK: - Times
let YoTimeForDoubleTap:Double = 0.3
let YoTimeForTextFlash:Double = 2.0

// MARK: - Location Constants
let YoLocationPinColor: WKInterfaceMapPinColor = WKInterfaceMapPinColor.Red
let YoLocationVisableRegionSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.008, 0.008)

// MARK: - In Watch Text

let YoBackText = NSLocalizedString("yo back", comment: "")
let YoBackLocationText = NSLocalizedString("📍 yo back", comment: "the first word is an emoji dont translate")

let YoInboxSuffixSingular = NSLocalizedString("new yo", comment: "this will be prefixed with the number of new yos")
let YoInboxSuffixPlural = NSLocalizedString("new yo's", comment: "this will be prefixed with the number of new yos")

func GetYoInboxSufficForYoCount(yoCount: NSInteger) -> String {
    if yoCount == 1 {
        return YoInboxSuffixSingular
    }
    else {
        return YoInboxSuffixPlural
    }
}

func GetYoLocationSufficForYoCount(yoCount: NSInteger) -> String {
    if yoCount == 1 {
        return NSLocalizedString("location", comment: "as in 1 yo location")
    }
    else {
        return NSLocalizedString("locations", comment: "as in 2 yo location")
    }
}

func GetYoPhotoSufficForYoCount(yoCount: NSInteger) -> String {
    if yoCount == 1 {
        return NSLocalizedString("photo", comment: "as in 1 yo photo")
    }
    else {
        return NSLocalizedString("photos", comment: "as in 2 yo photos")
    }
}

func GetYoLinkSufficForYoCount(yoCount: NSInteger) -> String {
    if yoCount == 1 {
        return NSLocalizedString("link", comment: "as in 1 yo link")
    }
    else {
        return NSLocalizedString("links", comment: "as in 2 yo links")
    }
}

let YoSentYoText = NSLocalizedString("sent yo", comment: "message displayed after sending yo").capitalizedString + "!"
let YoSentYoLocationText = NSLocalizedString("sent yo location", comment: "message displayed after sending yo location").capitalizedString + "!"

// MARK: InterfaceController
let YoNoContactsPrompt = NSLocalizedString("no contacts.", comment: "").capitalizedString
let YoLoggedOutPrompt = NSLocalizedString("please login", comment: "").capitalizedString

// MARK: User Activities
let YoActivityKey = "yo_activity"
let YoActivityIdentifierViewingGlance = "com.yo.yo.user-activity.viewing-glance"
let YoActivityIdentifierViewingYo = "com.yo.yo.user-activity.viewing-yo"