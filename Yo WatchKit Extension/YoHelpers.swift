//
//  YoHelpers.swift
//  Yo
//
//  Created by Peter Reveles on 3/1/15.
//
//

import Foundation

extension UIColor {
    func colorWithHex(hex:String) -> UIColor {
        var proccessedHex: String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        proccessedHex = proccessedHex.uppercaseString
        
        func stringByStripingPrefixIfPossible(prefix: String, string: String) -> String {
            var result = string
            if string.hasPrefix(prefix) {
                let startIndex = string.startIndex.advancedBy(2)
                result = string.substringFromIndex(startIndex)
            }
            return result
        }
        
        proccessedHex = stringByStripingPrefixIfPossible("0X", string: proccessedHex)
        
        if proccessedHex.characters.count != 6 {
            return UIColor.grayColor()
        }
        
        var currentPointInString: String.Index = proccessedHex.startIndex
        
        let firstThirdRange = Range<String.Index>(start: currentPointInString, end: currentPointInString.advancedBy(2))
        currentPointInString = currentPointInString.advancedBy(2)
        let secondThirdRange = Range<String.Index>(start: currentPointInString, end: currentPointInString.advancedBy(2))
        currentPointInString = currentPointInString.advancedBy(2)
        let thirdRange = Range<String.Index>(start: currentPointInString, end: currentPointInString.advancedBy(2))
        let rString = proccessedHex.substringWithRange(firstThirdRange)
        let gString = proccessedHex.substringWithRange(secondThirdRange)
        let bString = proccessedHex.substringWithRange(thirdRange)
        
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        func floatFromTwoCharColorHex(TwoCharColorHex: String) -> CGFloat {
            var result: UInt32 = 0
            NSScanner(string: TwoCharColorHex).scanHexInt(&result)
            var floatResult = CGFloat(result)/255.0
            return floatResult
        }
        
        let red = floatFromTwoCharColorHex(rString)
        let green = floatFromTwoCharColorHex(gString)
        let blue = floatFromTwoCharColorHex(bString)
        
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func colorForIndex(index: NSInteger) -> UIColor {
        var color: UIColor
        switch index % 8 {
        case 0:
            color = UIColor().colorWithHex(TURQUOISE)
        case 1:
            color = UIColor().colorWithHex(EMERALD)
        case 2:
            color = UIColor().colorWithHex(PETER)
        case 3:
            color = UIColor().colorWithHex(ASPHALT)
        case 4:
            color = UIColor().colorWithHex(GREEN)
        case 5:
            color = UIColor().colorWithHex(SUNFLOWER)
        case 6:
            color = UIColor().colorWithHex(BELIZE)
        case 7:
            color = UIColor().colorWithHex(WISTERIA)
        default:
            color = UIColor().colorWithHex(WISTERIA)
        }
        return color
    }
}










