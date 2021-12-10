//
//  YoCameraView.h
//  Yo
//
//  Created by Or Arbel on 5/21/15.
//
//

#import <UIKit/UIKit.h>

@class YoCameraView;

@protocol YoCameraViewDelegate <NSObject>

- (void)cameraView:(YoCameraView *)cameraView didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error;

@end

@interface YoCameraView : UIView

@property (nonatomic, strong) AVCaptureSession *session;

@property (strong, nonatomic) UIImage *defaultImage;

@property (weak, nonatomic) id<YoCameraViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame andPosition:(AVCaptureDevicePosition)position;
- (id)initWithFrame:(CGRect)frame andPosition:(AVCaptureDevicePosition)position isVideo:(BOOL)isVideo;

- (void)start;
- (void)stop;
- (void)switchCamera;

- (void)takePictureWithCompletionBlock:(void (^)(UIImage *image))completionBlock;

@property (nonatomic, readonly) UIImage *lastPictureTaken;

@property (nonatomic, readonly) AVCaptureDevicePosition devicePosition;

- (void)prepareVideoRecording;
- (void)startRecordingVideo;
- (void)stopRecordingVideo;
- (BOOL)isRecording;

@end
