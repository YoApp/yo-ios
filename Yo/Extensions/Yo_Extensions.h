//
//  Yo_Extensions.h
//  Yo
//
//  Created by Peter Reveles on 11/24/14.
//
//

#import <Foundation/Foundation.h>
#import "UINavigationController+CompletionHandler.h"
#import "UIScrollView+KeyboardSupport.h"
#import "UIView+AlphaAnimation.h"
#import "YoLabel.h"

@interface UIColor (Hex)
-(UIColor*) inverseColor;
- (UIColor *)colorForHexString:(NSString *)hexString;
@end

@interface UIImage (Size)
/**
 @param size the desired new size of the image.
 
 @return A UIImage scaled to size
 */
- (UIImage *)scaledToWidth:(CGFloat)width;

- (UIImage *)scaledToSize:(CGSize)size;

- (UIImage *)fixOrientation;

- (BOOL)isEqualToImage:(UIImage *)image;

@end

@interface NSURL (YoURL)
+(instancetype)URLWithString:(NSString *)URLString shouldBitlyWrap:(BOOL)shouldBitlyWrap;
- (NSURL *)bitlyWraped;
@end

@interface NSDate (Helpers)

- (BOOL)occuredToday;

- (BOOL)occuredYesterday;

@end

@interface NSNull (Yo)

- (BOOL)boolValue;
- (BOOL)hasPrefix:(NSString *)s;
- (NSUInteger)length;

@end

@interface UIViewController (Yo)

- (BOOL)isModal;

@end