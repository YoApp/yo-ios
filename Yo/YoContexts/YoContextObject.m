//
//  YoBaseContext.m
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoContextObject.h"

NSString *const YoNotificationContextDidUpdateConfiguration = @"ContextDidUpdateConfiguration";

@implementation YoContextObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// @or: methods to be implemented by subclasses

- (NSString *)textForTitleBar {
    return nil;
}

- (NSString *)textForStatusBar {
    return nil;
}

- (NSString *)textForSentYo {
    return NSLocalizedString(@"Sent Yo!", nil); // default send text
}

- (NSString *)titleForPermissionAlert {
    return nil;
}

- (NSString *)textForPermissionButton {
    return nil;
}

- (BOOL)alwaysShowBanner {
    return NO;
}

- (BOOL)supportsLongPress {
    return NO;
}

- (BOOL)isRecording {
    return NO;
}

- (void)stopRecordingAndCancelYo:(BOOL)cancelYo {
    
}

- (UIView *)backgroundView {
    return [UIView new];
}

- (BOOL)isTableViewTransparent {
    return YES;
}

- (BOOL)isLabelGlowing {
    return NO;
}

- (BOOL)shouldHideTableViewOnChange {
    return NO;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (NSDictionary *)contextParameters {
    return @{};
}

- (void)contextDidAppear {

}

- (void)contextDidDisappear {
    
}

- (void)didPresentSettings {
    
}

- (void)fetchDataIfNeeded {/*NOP*/}

- (void)prepareContextParametersLongTap:(BOOL)isLongTap withCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    [self prepareContextParametersWithCompletionBlock:block];
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    [self prepareContextParametersLongTap:NO withCompletionBlock:block];
} 

- (NSString *)getFirstTimeYoText {
    DDLogWarn(@"should be implemented by subclass.");
    return nil;
}

- (BOOL)recordsOnTap {
    return NO;
}

- (BOOL)recordsOnLongTap {
    return NO;
}

- (NSTimeInterval)getRecordingTimeIsLongTap:(BOOL)isLongTap {
    return 0.0;
}

#pragma mark - Permissions

- (BOOL)doesNeedSpecialPermission {
    return NO;
}

- (NSString *)textForPopupPriorToAskingPermission {
    return nil;
}

- (void)askForSpecialPermission {
    
}

- (UIView *)permissionsBanner {
    return nil;
}

- (BOOL)shouldShowPermissionsBanner {
    return NO;
}

+ (NSString *)contextID
{
    DDLogWarn(@"Should be implemented by subclasses.");
    return nil;
}

- (BOOL)canDisplay {
    return YES;
}

@end
