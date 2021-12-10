//
//  YoShareSheet.h
//  Yo
//
//  Created by Peter Reveles on 11/24/14.
//
//

#import <Foundation/Foundation.h>
#import "YoBaseViewController.h"

// will present options to share on:
// Facebook
// Twitter
// WhatsApp
// Apple Default Activity Controller

@interface YoShareSheet : YoBaseViewController

/*!
 * Intializes Yo Share Sheet for sharing listed params
 *
 * \param url
 * The url to share (required).
 *
 * \param message
 * The test to share (required).
 *
 * \param image
 * An image to share (optional).
 *
 */
- (instancetype)initForURL:(NSURL *)url message:(NSString *)message image:(UIImage *)image;

- (void)show;

/*!
 * Create a Yo brand graphic like USERNAME is on Yo
 *
 * \param message
 * The the message to display is word is displayed on its own cell (required).
 *
 */

+ (UIImage *)yoBrandGraphicFormessage:(NSString *)message purpleTop:(BOOL)purpleTop;

@end
