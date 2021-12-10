//
//  ThemeManager.m
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import "YoThemeManager.h"
#import "YoConfigManager.h"

#define kDefaultTheme @"Classic,#9B59B6,#ffffff,#e74c3c,#1ABC9C,#29d471,#1e9cf0,#255e97,#1bba9b,#fccb08,#268acb,#9944bc"

enum {
    YoThemeColorPositionName,
    YoThemeColorPositionBackground,
    YoThemeColorPositionText,
    YoThemeColorPositionMenuButton,
    YoThemeColorPositionBottomLeftButton
};

@interface YoThemeManager ()

@property (nonatomic, strong) NSArray *components;
@property (nonatomic, strong) NSMutableArray *colorForRowsArray;

@end

@implementation YoThemeManager

+ (instancetype)sharedInstance {
    
    static YoThemeManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        [_sharedInstance parseThemeString];
    });
    
    return _sharedInstance;
}

- (void)parseThemeString {
    NSString *theme = nil;
    if ([[YoConfigManager sharedInstance] theme]) {
        theme = [[YoConfigManager sharedInstance] theme];
    }
    else {
        theme = kDefaultTheme;
    }
    self.components = [theme componentsSeparatedByString:@","];
    self.colorForRowsArray = nil;
}

- (NSArray *)colorsForRows {
    if (self.colorForRowsArray) {
        return self.colorForRowsArray;
    }
    NSArray *hexStrings = [self.components subarrayWithRange:NSMakeRange(5, self.components.count - 5)];
    self.colorForRowsArray = [NSMutableArray array];
    for (NSString *hexString in hexStrings) {
        [self.colorForRowsArray addObject:[UIColor colorWithHexString:hexString]];
    }
    return self.colorForRowsArray;
}

- (UIColor *)backgroundColor {
    return [UIColor colorWithHexString:self.components[YoThemeColorPositionBackground]];
}

- (UIColor *)textColor {
    return [UIColor colorWithHexString:self.components[YoThemeColorPositionText]];
}

- (UIColor *)menuButtonColor {
    return [UIColor colorWithHexString:self.components[YoThemeColorPositionMenuButton]];
}

- (UIColor *)bottomLeftButtonColor {
    return [UIColor colorWithHexString:self.components[YoThemeColorPositionBottomLeftButton]];
}

- (UIColor *)colorForRow:(NSUInteger)row {
    return [[self colorsForRows] objectAtIndex:row % [[YoThemeManager sharedInstance] colorsForRows].count];
}

@end
