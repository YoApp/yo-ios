//
//  Yo_Extensions.m
//  Yo
//
//  Created by Peter Reveles on 11/24/14.
//
//

#import "Yo_Extensions.h"


@implementation UIColor (Hex)

-(UIColor*) inverseColor
{
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

- (UIColor *)colorForHexString:(NSString *)hexString{
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

@end

@implementation UIImage (Size)

- (UIImage *)scaledToSize:(CGSize)size{
    if (size.width <= 0.0f ||  size.height <= 0.0f)
        return self;
    
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)scaledToWidth:(CGFloat)width{
    if (width <= 0.0f)
        return nil;
    
    BOOL isVerticalOrientation = YES;
    
    NSArray *horizontalImageOrientations = @[@(UIImageOrientationRightMirrored),
                                             @(UIImageOrientationLeftMirrored),
                                             @(UIImageOrientationRight),
                                             @(UIImageOrientationLeft)];
    
    if ([horizontalImageOrientations containsObject:@(self.imageOrientation)])
        isVerticalOrientation = NO;
    
    if (self.size.width == width) return self;
    
    CGFloat ratio = self.size.height/self.size.width;
    
    if (!isVerticalOrientation)
        ratio = self.size.width/self.size.height;
    
    CGSize newSize = CGSizeMake(width, width*ratio);
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = self.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:1.0f orientation:self.imageOrientation];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (BOOL)isEqualToImage:(UIImage *)image {
    NSData *myData = UIImageJPEGRepresentation(self, 1.0);
    NSData *theirData = UIImageJPEGRepresentation(image, 1.0);
    
    return [myData isEqualToData:theirData];
}

@end

@implementation NSURL (YoURL)

+(instancetype)URLWithString:(NSString *)URLString shouldBitlyWrap:(BOOL)shouldBitlyWrap{
    NSURL *url = [NSURL URLWithString:URLString];
    
    if (url && shouldBitlyWrap) {
        static NSString *bitlyUsername = @"orarbel";
        static NSString *apiKey = @"R_2d8f8096e1f59c06e22b38c5e4a973fc";
        
        NSString *shortURLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt", bitlyUsername, apiKey, url.absoluteString]] encoding:NSUTF8StringEncoding error:nil];
        
        shortURLString = [shortURLString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        // urls with # need to be encoded http://dev.bitly.com/links.html
        if ([shortURLString length]) {
            // sometimes bitly will return a dictionay instead of just the url stirng
            NSDictionary *shortURLDictionary = [NSJSONSerialization JSONObjectWithData:[shortURLString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            if (shortURLDictionary) {
                NSString *hiddenURLString = shortURLDictionary[@"data"][@"url"];
                shortURLString = hiddenURLString;
            }
            url = [NSURL URLWithString:shortURLString];
        }
    }
    
    return url;
}
- (NSURL *)bitlyWraped{
    return [NSURL URLWithString:self.absoluteString shouldBitlyWrap:YES];
}
@end

@implementation NSDate (Helpers)

- (BOOL)occuredToday {
    BOOL occuredToday = NO;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    NSDateComponents *selfDateComponents = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
    NSDate *selfSimplified = [cal dateFromComponents:selfDateComponents];
    
    if ([today isEqualToDate:selfSimplified]) {
        // yesterday
        occuredToday = YES;
    }
    
    return occuredToday;
}

- (BOOL)occuredYesterday {
    BOOL occuredYesterday = NO;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    components.day = components.day - 1;
    NSDate *yesterday = [cal dateFromComponents:components];
    
    NSDateComponents *selfDateComponents = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
    NSDate *selfSimplified = [cal dateFromComponents:selfDateComponents];
    
    if ([yesterday isEqualToDate:selfSimplified]) {
        // yesterday
        occuredYesterday = YES;
    }
    
    return occuredYesterday;
}

@end

@implementation NSNull (Yo)

-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    return nil;
}

- (BOOL)boolValue {
    return NO;
}

- (BOOL)hasPrefix:(NSString *)s {
    return NO;
}

- (NSUInteger)length {
    return 0;
}

@end

@implementation UIViewController (Yo)

- (BOOL)isModal {
    return self.presentingViewController.presentedViewController == self
    || (self.navigationController != nil && self.navigationController.presentingViewController.presentedViewController == self.navigationController)
    || [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

@end
