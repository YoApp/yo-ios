//
//  Yo+Utility.m
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "Yo+Utility.h"

#import "YoMapController.h"
#import "YoImageController.h"
#import "PlainYoController.h"
#import "YoWebBrowserController.h"
#import "YoAudioController.h"

@implementation Yo (Utility)

- (BOOL)hasAudioURL {
    if ([@[@"aac", @"mp3"] containsObject:self.url.pathExtension]) {
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - Open Yo

#ifndef IS_APP_EXTENSION
- (void)open {
    
    if ( ! [self isFromService]) {
        [[[YoUser me] contactsManager] promoteObjectToTopWithUsername:self.senderUsername];
    }
    
    YoBaseViewController *presentingController = (YoBaseViewController *)[APPDELEGATE topVC];
    if ([presentingController isKindOfClass:[UINavigationController class]]) {
        presentingController = (YoBaseViewController *)[(UINavigationController *)presentingController topViewController];
    }
    if ( ! [presentingController isKindOfClass:[YoBaseViewController class]]) {
        return;
    }
    YoBaseViewController *presentedController = nil;
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (self.image || [self.category isEqualToString:kYoCategoryPhoto] ||
        [@[@"jpg", @"png", @"gif", @"mov"] containsObject:[self.url pathExtension]]) {
        YoImageController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoImageControllerID"];
        vc.yo = self;
        presentedController = vc;
    }
    else if (self.url) {
        if ([@[@"aac", @"mp3"] containsObject:[self.url pathExtension]]) {
            YoAudioController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoAudioControllerID"];
            vc.yo = self;
            presentedController = vc;
        }
        else {
            YoWebBrowserController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoWebBrowserControllerID"];
            vc.sourceYo = self;
            presentedController = vc;
        }
    }
    else if (self.location) {
        YoMapController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoMapControllerID"];
        vc.yo = self;
        presentedController = vc;
    }
    else {
        PlainYoController *vc = [storyboard instantiateViewControllerWithIdentifier:@"PlainYoControllerID"];
        vc.yo = self;
        presentedController = vc;
    }
    
    presentedController.modalPresentationStyle = UIModalPresentationCustom;
    presentedController.transitioningDelegate = presentedController;
    [presentingController showBlurredBackgroundWithViewController:presentedController];
    
}
#endif

@end
