//
//  YoCameraView.m
//  Yo
//
//  Created by Or Arbel on 5/21/15.
//
//

#import "YoCameraView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface YoCameraView () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) BOOL freeze;

#pragma mark - Video

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) UIImage *lastPictureTaken;

@end

@implementation YoCameraView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    BOOL shouldStartAsBackCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"should.start.as.back.camera"];
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    if (shouldStartAsBackCamera) {
        position = AVCaptureDevicePositionBack;
    }
    if (self = [self initWithFrame:frame andPosition:position]) {
        
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andPosition:(AVCaptureDevicePosition)position {
    return [self initWithFrame:frame andPosition:position isVideo:NO];
}

- (id)initWithFrame:(CGRect)frame andPosition:(AVCaptureDevicePosition)position isVideo:(BOOL)isVideo {
    if (self = [super initWithFrame:frame]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CaptureSessionStarted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionStarted:) name:@"CaptureSessionStarted" object:nil];
        
        self.session = [AVCaptureSession new];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.session beginConfiguration];
            
            if (isVideo) {
                [self prepareVideoRecording];
            }
            
            [self.session setSessionPreset:AVCaptureSessionPresetMedium];
            
            NSError *error = nil;
            self.device = [self cameraWithPosition:position];
            AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
            
            if (deviceInput) {
                
                [self.session addInput:deviceInput];
                
                self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
                self.previewLayer.frame = self.bounds;
                [[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                [self.layer addSublayer:self.previewLayer];
                
                AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
                if ([self.session canAddOutput:stillImageOutput]) {
                    [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
                    [self.session addOutput:stillImageOutput];
                    [self setStillImageOutput:stillImageOutput];
                }
            }
            else {
                DDLogError(@"no device input");
            }
            
            [self.session commitConfiguration];
            
        });
    };
    
    return self;
}

- (void)captureSessionStarted:(NSNotification *)notification {
    if (notification.object != self) {
        [self.session stopRunning];
    }
}

- (void)start {
    if ( ! [self.session isRunning]) {
        [self.session startRunning];
        
        if (self.device.focusMode != AVCaptureFocusModeContinuousAutoFocus && [self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            NSError *error;
            if ([self.device lockForConfiguration:&error]) {
                self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                [self.device unlockForConfiguration];
            }
        }
    }
}

- (void)stop {
    [self.session stopRunning];
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)switchCamera {
    //Indicate that some changes will be made to the session
    [self.session beginConfiguration];
    
    //Remove existing input
    AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
    [self.session removeInput:currentCameraInput];
    
    //Get new input
    AVCaptureDevicePosition newPosition;
    if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
    {
        self.device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"should.start.as.back.camera"];
        newPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        self.device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"should.start.as.back.camera"];
        newPosition = AVCaptureDevicePositionBack;
    }
    
    //Add input to session
    NSError *err = nil;
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&err];
    if(!newVideoInput || err)
    {
        NSLog(@"Error creating capture device input: %@", err.localizedDescription);
    }
    else
    {
        if ([self.session canAddInput:newVideoInput]) {
            [self.session addInput:newVideoInput];
        }
    }
    
    AVCaptureVideoDataOutput *videoOutput = self.session.outputs[0];
    AVCaptureConnection *connection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[videoOutput connections]];
    if ([connection isVideoOrientationSupported]) {
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    if (newPosition == AVCaptureDevicePositionFront) {
        if ([connection isVideoMirroringSupported]) {
            [connection setVideoMirrored:YES];
        }
    }
    
    //Commit all the configuration changes at once
    [self.session commitConfiguration];
}

- (void)takePictureWithCompletionBlock:(void (^)(UIImage *image))completionBlock {
    UIView *flashView = [[UIView alloc] initWithFrame:self.bounds];
    flashView.backgroundColor = [UIColor whiteColor];
    flashView.alpha = 0.0;
    [self addSubview:flashView];
    [UIView animateWithDuration:0.05 animations:^{
        flashView.alpha = 1.0;
    }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05 animations:^{
                             flashView.alpha = 0.0;
                         }
                                          completion:^(BOOL finished) {
                                              [flashView removeFromSuperview];
                                          }];
                     }];
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer)
        {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            _lastPictureTaken = image;
            //[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            completionBlock(image);
        }
    }];
}

- (AVCaptureDevicePosition)devicePosition {
    return self.device.position;
}

#pragma mark - Video

- (void)prepareVideoRecording {
    
    self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    self.movieOutput.maxRecordedDuration = maxDuration;
    
    self.movieOutput.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    AVCaptureConnection *captureConnection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoOrientationSupported]) {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [captureConnection setVideoOrientation:orientation];
    }
    
    if ([self.session canAddOutput:self.movieOutput]) {
        [self.session addOutput:self.movieOutput];
    }
    else {
        // @or: TODO show error
    }
    
    NSError *error = nil;
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    
}

- (void)startRecordingVideo {
    
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:outputPath error:&error];
        if (error) {
            DDLogError(@"%@", error);
        }
    }
    
    if (self.audioInput && [self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    [self.movieOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (void)stopRecordingVideo {
    [self.movieOutput stopRecording];
    
    [self.session beginConfiguration];
    
    //[self.session setSessionPreset:AVCaptureSessionPreset640x480];
    
    [self.session removeInput:self.audioInput];
    [self.session commitConfiguration];
}

- (BOOL)isRecording {
    return self.movieOutput.isRecording;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    if (recordedSuccessfully) {
        [self.delegate cameraView:self didFinishRecordingToOutputFileAtURL:outputFileURL error:nil];
        /*ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
         if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
         {
         [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
         completionBlock:^(NSURL *assetURL, NSError *error)
         {
         if (error)
         {
         DDLogError(@"%@", error);
         }
         }];
         }*/
    }
    else {
        [self.delegate cameraView:self didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

@end
