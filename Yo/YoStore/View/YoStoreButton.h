//
//  YoStoreButton.h
//  Yo
//
//  Created by Peter Reveles on 2/26/15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, YoStoreButtonStyle) {
    YoStoreButtonStyleBordered,
    YoStoreButtonStylePlain,
    YoStoreButtonStyleWhite,
};

@interface YoStoreButton : UIButton
@property (assign, nonatomic) YoStoreButtonStyle style;
@end
