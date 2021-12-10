//
//  YoVideoContext.m
//  Yo
//
//  Created by Or Arbel on 5/22/15.
//
//

#import "YoVideoContext.h"
#import "YoCameraView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "YoPermissionsInstructionView.h"
#import "YoImgUploadClient.h"

@interface YoVideoContext () <YoCameraViewDelegate>

@property (nonatomic, strong) MPMoviePlayerController *playerController;

@property (strong, nonatomic) UIView *internalBackgroundView;
@property (strong, nonatomic) YoCameraView *cameraView;
@property (strong, nonatomic) UIImageView *defaultImageView;
@property (strong, nonatomic) UIButton *flipCameraButton;

@end

@implementation YoVideoContext

- (id)init {
    if (self = [super init]) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateNormal];
        button.frame = CGRectMake(0, 0, 50, 50);
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        button.layer.cornerRadius = button.width / 2.0;
        button.layer.masksToBounds = YES;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowRadius = 3.0f;
        button.layer.shadowOpacity = 0.5f;
        self.flipCameraButton = button;
    }
    return self;
}

- (NSString *)textForTitleBar {
    return @"Yo Video 📷";
}

- (NSString *)textForStatusBar {
    return @"Tap name to send a video 📷";
}

- (NSString *)textForSentYo {
    return @"Sent Video";
}

- (UIView *)backgroundView {
    
    if ( ! self.internalBackgroundView) {
        self.internalBackgroundView = [UIView new];
        self.internalBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    UIImage *image = [UIImage imageNamed:@"defaultCamera.jpg"];
    self.defaultImageView = [UIImageView new];
    self.defaultImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.defaultImageView.image = image;
    [self.internalBackgroundView addSubview:self.defaultImageView];
    
#if !TARGET_IPHONE_SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self applyCameraViewIfPermitted]; // @or: prevent slow loading of the app
    });
#endif
    
    return self.internalBackgroundView;
}

- (void)applyCameraViewIfPermitted {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        if (self.cameraView == nil) {
            self.cameraView = [[YoCameraView alloc] initWithFrame:[UIScreen mainScreen].bounds andPosition:AVCaptureDevicePositionFront isVideo:YES];
            self.cameraView.delegate = self;
            [self.flipCameraButton addTarget:self.cameraView action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
            [self.internalBackgroundView addSubview:self.cameraView];
            [self.internalBackgroundView bringSubviewToFront:self.flipCameraButton];
        }
    }
    else {
        [self.cameraView stop];
        [self.cameraView removeFromSuperview];
        self.cameraView = nil;
    }
}

- (UIButton *)button {
    if (!([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] &&
          [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])) {
        return nil;
    }
    
    if (!_flipCameraButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateNormal];
        [button addTarget:self.cameraView action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0, 0, 50, 50);
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        button.layer.cornerRadius = button.width / 2.0;
        button.layer.masksToBounds = YES;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowRadius = 3.0f;
        button.layer.shadowOpacity = 0.5f;
        _flipCameraButton = button;
    }
    return _flipCameraButton;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    self.completionBlock = block;
    [self.cameraView startRecordingVideo];
    [NSTimer scheduledTimerWithTimeInterval:4.0 target:self.cameraView selector:@selector(stopRecordingVideo) userInfo:nil repeats:NO];
}

- (void)contextDidAppear {
    [self applyCameraViewIfPermitted];
    [self.cameraView start];
}

- (void)contextDidDisappear {
    //[self.cameraView stop];
}

- (void)didPresentSettings {
    [self.cameraView stop];
}

#pragma mark - Permissions

- (BOOL)doesNeedSpecialPermission {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return authStatus == AVAuthorizationStatusNotDetermined;
}

- (NSString *)textForPopupPriorToAskingPermission {
    return NSLocalizedString(@"📷\nSend a photo to your friends in 1 tap" , nil);
}

- (NSString *)textForPermissionButton {
    return @"Enable Camera";
}

- (NSString *)titleForPermissionAlert {
    return @"Yo Photo";
}

- (void)askForSpecialPermission {
#if ! TARGET_IPHONE_SIMULATOR
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        // Will get here on both iOS 7 & 8 even though camera permissions weren't required
        // until iOS 8. So for iOS 7 permission will always be granted.
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self applyCameraViewIfPermitted];
            });
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificaitonAVMediaTypeVideoServicesDenied object:self];
        }
    }];
#endif
}

- (UIView *)permissionsBanner {
    YoPermissionsInstructionView *permissionsView = LOAD_NIB(@"YoPermissionsInstructionView");
    permissionsView.instructionImageView.image = [UIImage imageNamed:YoInstructionImageCamera];
    BOOL canOpenYoAppSettings = NO;
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        canOpenYoAppSettings = YES;
    }
    NSString *instructionsText = @"Send photos to your friends by granting Yo access to your camera in the Settings App.";
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
    BOOL shouldDisplayPermissionsBanner = NO;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied ||
        authStatus == AVAuthorizationStatusRestricted) {
        shouldDisplayPermissionsBanner = YES;
    }
    return shouldDisplayPermissionsBanner;
}

- (void)cameraView:(YoCameraView *)cameraView didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    if (error) {
        DDLogError(@"%@", error);
        self.completionBlock(nil, NO);
    }
    else {
        NSString *filename = MakeString(@"%@.mov", [[NSProcessInfo processInfo] globallyUniqueString]);
        [[YoImgUploadClient sharedClient] uploadFileToS3WithFilePath:[outputFileURL path]
                                                            filename:filename
                                                         contentType:@"video/quicktime"
                                                     completionBlock:^(NSString *imageURL, NSError *error) {
                                                         if (error) {
                                                             DDLogError(@"%@", error);
                                                         }
                                                         if (imageURL) {
                                                             self.completionBlock(@{@"link": imageURL}, NO);
                                                         }
                                                         else {
                                                             self.completionBlock(nil, NO);
                                                         }
                                                     }];
    }
}

+ (NSString *)contextID
{
    return @"video";
}

- (NSString *)getFirstTimeYoText {
    return @"📹 Yo Video";
}

- (BOOL)recordsOnTap {
    return YES;
}

- (BOOL)recordsOnLongTap {
    return YES;
}

@end
