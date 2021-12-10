//
//  YoCameraContext.m
//  Yo
//
//  Created by Or Arbel on 5/31/15.
//
//

#import "YoCameraContext.h"
#import "YoCameraView.h"
#import "YoImgUploadClient.h"
#import "YoPermissionsInstructionView.h"
#import "YoUserTableViewCell.h"

@interface YoCameraContext () <YoCameraViewDelegate>

@property (strong, nonatomic) UIView *internalBackgroundView;
@property (strong, nonatomic) YoCameraView *cameraView;
@property (strong, nonatomic) UIButton *flipCameraButton;
@property (strong, nonatomic) NSTimer *recordingTimer;
@property (strong, nonatomic) NSTimer *pictureTimer;
@property (assign, nonatomic) NSString *successText;
@property(nonatomic, assign) BOOL isLastYoCancelled;
@property (nonatomic, weak) UIImageView *imagePreview;
@end

@implementation YoCameraContext

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
        
        self.successText = @"Sent Photo 📷";
    }
    return self;
}

- (NSString *)textForTitleBar {
    return @"Yo Photo 📷";
}

- (NSString *)textForStatusBar {
    return @"Tap for Photo 📷. Hold for Video 📹";
}

- (NSString *)textForSentYo {
    return self.successText;
}

- (UIView *)backgroundView {
    
    if ( ! self.internalBackgroundView) {
        self.internalBackgroundView = [UIView new];
        self.internalBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    UIImageView *imagePreview = [UIImageView new];
    imagePreview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    imagePreview.contentMode = UIViewContentModeScaleAspectFill;
    [self.internalBackgroundView addSubview:imagePreview];
    _imagePreview = imagePreview;
    
    //NSDictionary *views = @{@"defaultImageView":self.defaultImageView};
    
    /*[self.internalBackgroundView addConstraints:
     [NSLayoutConstraint
     constraintsWithVisualFormat:@"H:|[defaultImageView]|"
     options:0 metrics:nil views:views]];
     
     [self.internalBackgroundView addConstraints:
     [NSLayoutConstraint
     constraintsWithVisualFormat:@"V:|[defaultImageView]|"
     options:0 metrics:nil views:views]];
     
     [self.internalBackgroundView setNeedsLayout];
     [self.internalBackgroundView layoutIfNeeded];*/
    
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
            BOOL shouldStartAsBackCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"should.start.as.back.camera"];
            AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
            if (shouldStartAsBackCamera) {
                position = AVCaptureDevicePositionBack;
            }
            self.cameraView = [[YoCameraView alloc] initWithFrame:[UIScreen mainScreen].bounds andPosition:position isVideo:YES];
            self.cameraView.delegate = self;
            [self.flipCameraButton addTarget:self.cameraView action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
            [self.internalBackgroundView insertSubview:self.cameraView belowSubview:self.imagePreview];
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

- (BOOL)supportsLongPress {
    return YES;
}

- (BOOL)isRecording {
    return [self.cameraView isRecording];
}

- (void)stopRecordingAndCancelYo:(BOOL)cancelYo {
    if (self.recordingTimer.isValid) {
        [self.recordingTimer invalidate];
        self.isLastYoCancelled = cancelYo;
        [self.cameraView stopRecordingVideo];
    }
    else {
        [self endImagePreviewAndCancelYo:cancelYo];
    }
}

- (void)endImagePreview {
    [self endImagePreviewAndCancelYo:NO];
}

- (void)endImagePreviewAndCancelYo:(BOOL)cancelYo {
    [self.pictureTimer invalidate];
    self.imagePreview.image = nil;
    [self.cameraView start];
    if (cancelYo) {
        self.isLastYoCancelled = YES;
        self.completionBlock(nil, cancelYo);
    }
    else {
        self.isLastYoCancelled = NO;
        [[YoImgUploadClient sharedClient] uploadToS3WithImage:self.cameraView.lastPictureTaken
                                              completionBlock:^(NSString *imageURL, NSError *error) {
                                                  if (imageURL) {
                                                      NSDictionary *extraParameters = @{@"link": imageURL};
                                                      self.completionBlock(extraParameters, NO);
                                                  }
                                                  else {
                                                      [Flurry logError:nil message:nil error:error];
                                                      self.completionBlock(nil, NO);
                                                  }
                                              }];
    }
}

- (void)prepareContextParametersLongTap:(BOOL)isLongTap withCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    self.completionBlock = block;
    if (isLongTap) {
        self.successText = @"Sent Video 📹";
        [self.cameraView startRecordingVideo];
        self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                               target:self.cameraView
                                                             selector:@selector(stopRecordingVideo)
                                                             userInfo:nil
                                                              repeats:NO];
    }
    else {
        self.successText = @"Sent Photo 📷";
        [self.cameraView takePictureWithCompletionBlock:^(UIImage *image) {
            image = [image scaledToWidth:320];
            if (image) {
                [self.cameraView stop];
                
                UIImage *previewImage;
                if (self.cameraView.devicePosition == AVCaptureDevicePositionFront) {
                    previewImage = [UIImage imageWithCGImage:[image CGImage]
                                                       scale:1.0
                                                 orientation:UIImageOrientationLeftMirrored];
                }
                else {
                    previewImage = image;
                }
                _imagePreview.image = previewImage;
                //_imagePreview.frame = self.view.frame;
                self.pictureTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                     target:self
                                                                   selector:@selector(endImagePreview)
                                                                   userInfo:nil
                                                                    repeats:NO];
            }
            else {
                block(nil, NO);
            }
        }];
    }
}

- (void)contextDidAppear {
    self.isLastYoCancelled = NO;
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

- (void)checkPermissionsIsLongTap:(BOOL)isLongTap completionHandler:(void (^)(BOOL, NSString *))handler {
    if (isLongTap) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    handler(YES, nil);
                }
                else {
                    handler(NO, @"To record video, please grant mic permissions under settings.");
                }
            });
        }];
    }
    else {
        handler (YES, nil);
    }
}

- (void)cameraView:(YoCameraView *)cameraView didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    if (error) {
        DDLogError(@"%@", error);
        self.completionBlock(nil, NO);
    }
    else {
        if (self.isLastYoCancelled) {
            self.completionBlock(nil, YES);
            self.isLastYoCancelled = NO;
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
}

- (NSTimeInterval)getRecordingTimeIsLongTap:(BOOL)isLongTap {
    if (isLongTap) {
        return 4.0;
    }
    else {
        return 4.0;
    }
}

- (YoRecordingViewStyle)recordingStyleIsLongTap:(BOOL)isLongTap {
    if (isLongTap) {
        return YoRecordingViewSendAndCancelStyle;
    }
    else {
        return YoRecordingViewCancelStyle;
    }
}

- (NSString *)getTextToDisplayWhileRecordingIsLongTap:(BOOL)isLongTap {
    if (isLongTap) {
        return NSLocalizedString(@"Recording", nil);
    }
    else {
        return NSLocalizedString(@"Uploading", nil);
    }
}

+ (NSString *)contextID
{
    return @"camera";
}

- (NSString *)getFirstTimeYoText {
    NSRange range = [self.successText rangeOfString:@"📹"];
    BOOL containsVideoCameraEmoji = (range.location != NSNotFound);
    return containsVideoCameraEmoji ? @"📹 Yo Video": @"📷 Yo Photo";
}

- (BOOL)recordsOnTap {
    return YES;
}

- (BOOL)recordsOnLongTap {
    return YES;
}

- (BOOL)canDisplay {
    BOOL canDisplay = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    return canDisplay;
}

@end
