//
//  ThemeManager.h
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import <Foundation/Foundation.h>

@interface YoThemeManager : NSObject

+ (instancetype)sharedInstance;

- (void)parseThemeString;

- (NSArray *)colorsForRows;
- (UIColor *)backgroundColor;
- (UIColor *)textColor;
- (UIColor *)menuButtonColor;
- (UIColor *)bottomLeftButtonColor;
- (UIColor *)colorForRow:(NSUInteger)row;

@end
