//
//  YoJustYoContext.m
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoJustYoContext.h"
#import "YoPermissionsInstructionView.h"

@implementation YoJustYoContext

- (NSString *)textForTitleBar {
    return @"Yo";
}

- (NSString *)textForStatusBar {
    return @"Tap name to send a Yo";
}

- (NSString *)textForSentYo {
    return @"Sent Yo!";
}

- (UIView *)backgroundView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (BOOL)isTableViewTransparent {
    return NO;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleNone;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    block(@{}, NO);
}

- (UIView *)permissionsBanner {
    YoPermissionsInstructionView *permissionsView = LOAD_NIB(@"YoPermissionsInstructionView");
    permissionsView.instructionImageView.image = [UIImage imageNamed:YoInstructionImagePushNotifications];
    BOOL canOpenYoAppSettings = NO;
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        canOpenYoAppSettings = YES;
    }
    NSString *instructionsText = @"Receive Yos from your friends by enabling push notification in the Settings App.";
    if (canOpenYoAppSettings) {
        [permissionsView.actionButton setTitle:NSLocalizedString(@"Tap to Open Settings", nil)
                                      forState:UIControlStateNormal];
        [permissionsView.actionButton addTarget:self action:@selector(didTapPermissionsBanner:)
                               forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [permissionsView.actionButton removeFromSuperview];
    }
    permissionsView.textLabel.text = instructionsText;
    [permissionsView.textLabel sizeToFit];
    CGFloat padding = 24.0f + 10.0f + (14.0f * 2);
    if (CGRectGetHeight([[UIScreen mainScreen] bounds]) < 667.0f) {
        padding+=24.0f;
    }
    CGFloat shouldBeHeight = permissionsView.textLabel.height + permissionsView.settingsAppIconImageView.height + permissionsView.instructionImageView.height + padding;
    if (canOpenYoAppSettings) {
        shouldBeHeight += permissionsView.actionButton.height + 14.0f;
    }
    permissionsView.height = shouldBeHeight;
    return permissionsView;
}

- (void)didTapPermissionsBanner:(id)sender {
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else {
        DDLogWarn(@"Error: Attempted to open settings when opening settings is unavailble");
    }
}

- (BOOL)shouldShowPermissionsBanner {
    return NO; // @or: app can work without push, using the inbox
}

+ (NSString *)contextID
{
    return @"just_yo";
}

- (NSString *)getFirstTimeYoText {
    return @"Yo";
}

@end
