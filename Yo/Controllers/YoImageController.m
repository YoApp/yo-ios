//
//  YoImageController.m
//  Yo
//
//  Created by Or Arbel on 6/2/15.
//
//

#import "YoImageController.h"
#import "Yo.h"
#import "YoThisViewController.h"
#import "YoCameraView.h"
#import "YoImgUploadClient.h"
#import "YoInbox.h"
#import "FLAnimatedImage.h"
#import <MediaPlayer/MediaPlayer.h>
#import "YoButton.h"

@interface YoImageController () <UIScrollViewDelegate, UIActionSheetDelegate, YoCameraViewDelegate, UIGestureRecognizerDelegate>

@property(strong, nonatomic) YoThisViewController *yoThisController;
@property(strong, nonatomic) YoCameraView *cameraView;
@property(strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property(strong, nonatomic) IBOutlet FLAnimatedImageView *imageView;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *aiView;
@property(strong, nonatomic) IBOutlet YoButton *sendButton;

@end

void *YoContext = &YoContext;

@implementation YoImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sendButton.hidden = YES;
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOpacity = 0.5f;
    self.imageView.layer.shadowOffset = CGSizeMake(3.0f, 3.0f);
    self.imageView.layer.shadowRadius = 5.0f;
    self.imageView.layer.masksToBounds = NO;
    
    if (self.yo.isGroupYo) {
        self.fullNameLabel.text = MakeString(@"%@ to %@", self.yo.senderObject.displayName, self.yo.groupName);
    }
    else {
        self.fullNameLabel.text = self.yo.senderObject.displayName;
    }
    self.usernameLabel.text = [self.yo.creationDate agoString];
    [self.profileImageView setImageWithURL:self.yo.senderObject.photoURL];
    
    if (self.yo.image) {
        self.aiView.hidden = YES;
        if ([[self.yo.url absoluteString] hasSuffix:@".gif"]) {
            self.imageView.animatedImage = self.yo.animatedImage;
        }
        else {
            self.imageView.image = self.yo.image;
            
        }
        [[[YoUser me] yoInbox] updateOrAddYo:self.yo
                                  withStatus:YoStatusRead];
    }
    else {
        //////////////// Video ////////////////
        if ([[self.yo.url absoluteString] hasSuffix:@".mov"]) {
            self.mode = YoImageControllerModeVideo;
            [self.rightButton setTitle:@"Video Back 📹" forState:UIControlStateNormal];
            [self.sendButton setTitle:@"Start (4 seconds video)" forState:UIControlStateNormal];
            self.aiView.hidden = YES;
            MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] init];
            moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
            [moviePlayer setContentURL:self.yo.url];
            [moviePlayer setScalingMode:MPMovieScalingModeAspectFit];
            [moviePlayer prepareToPlay];
            [moviePlayer.view setFrame:self.imageView.bounds];
            moviePlayer.controlStyle = MPMovieControlStyleNone;
            [moviePlayer play];
            [self.imageView addSubview:moviePlayer.view];
            self.moviePlayer = moviePlayer;
            
            UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerTapped)];
            tapGr.delegate = self;
            [moviePlayer.view addGestureRecognizer:tapGr];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayVideo) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        }
        //////////////// Gif ////////////////
        else if ([[self.yo.url absoluteString] hasSuffix:@".gif"]) {
            self.mode = YoImageControllerModeGIF;
            self.aiView.hidden = NO;
            [self.aiView startAnimating];
            __weak YoImageController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:self.yo.url];
                if (data) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.aiView.hidden = YES;
                        weakSelf.imageView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                        [[[YoUser me] yoInbox] updateOrAddYo:weakSelf.yo
                                                  withStatus:YoStatusRead];
                    });
                }
                else {
                    weakSelf.aiView.hidden = YES;
                    [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
                }
            });
        }
        //////////////// Image ////////////////
        else {
            self.mode = YoImageControllerModeImage;
            self.aiView.hidden = NO;
            [self.aiView startAnimating];
            __weak YoImageController *weakSelf = self;
            NSURLRequest *request = [NSURLRequest requestWithURL:self.yo.url];
            [self.imageView setImageWithURLRequest:request
                                  placeholderImage:nil
                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                               weakSelf.aiView.hidden = YES;
                                               weakSelf.imageView.image = image;
                                               [[[YoUser me] yoInbox] updateOrAddYo:weakSelf.yo
                                                                         withStatus:YoStatusRead];
                                           }
                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                               weakSelf.aiView.hidden = YES;
                                               [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
                                           }];
        }
    }
    
    self.yoThisController = [YoThisViewController new];
    
    self.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSavePhotoSheet)];
    UILongPressGestureRecognizer *longGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showSavePhotoSheet)];
    [self.imageView addGestureRecognizer:tapGr];
    [self.imageView addGestureRecognizer:longGr];
    
    [self applyCustomActionsIfNeeded];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraView stop];
}

- (void)playerTapped {
    [self.moviePlayer stop];
    [self.moviePlayer play];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.moviePlayer.view setFrame:self.imageView.bounds];
}

- (void)didPlayVideo {
    [[[YoUser me] yoInbox] updateOrAddYo:self.yo
                              withStatus:YoStatusRead];
}

- (void)showSavePhotoSheet {
    if (self.mode == YoImageControllerModeVideo) {
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Save Photo", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
    }
}

- (void)close {
    [self closeWithCompletionBlock:nil];
}

- (IBAction)leftButtonPressed:(UIButton *)sender {
    if (self.isCustomReplies) {
        [super leftButtonPressed:sender];
    }
    else {
        [self.yoThisController presentShareSheetOnView:self.view toForwardYo:self.yo];
    }
}

- (IBAction)rightButtonPressed:(id)sender {
    
    if (self.isCustomReplies) {
        [super rightButtonPressed:sender];
    }
    else {
        
        [self.moviePlayer stop];
        self.sendButton.hidden = NO;
        
        AVCaptureDevicePosition position;
        if( [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            position = AVCaptureDevicePositionFront;
        }
        else {
            position = AVCaptureDevicePositionBack;
        }
        self.cameraView = [[YoCameraView alloc] initWithFrame:self.imageView.bounds andPosition:position isVideo:(self.mode == YoImageControllerModeVideo)];
        self.cameraView.delegate = self;
        [self.cameraView start];
        
        UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self.cameraView action:@selector(switchCamera)];
        [self.cameraView addGestureRecognizer:tapGr];
        
        [self.imageView addSubview:self.cameraView];
    }
}

- (IBAction)sendPhotoPressed:(UIButton *)sender {
    
    if (self.mode == YoImageControllerModeVideo) {
        
        if ([self.cameraView isRecording]) {
            [self.sendButton removeProgressView];
            [self.cameraView stopRecordingVideo];
        }
        else {
            [sender setTitle:@"Recording Video" forState:UIControlStateNormal];
            [self.moviePlayer stop];
            [self.cameraView startRecordingVideo];
            [self.sendButton animateProgressWithDuration:4.0];
            [NSTimer scheduledTimerWithTimeInterval:4.0 target:self.cameraView selector:@selector(stopRecordingVideo) userInfo:nil repeats:NO];
        }
    }
    else {
        [self showActivityOnView:sender];
        [sender setTitle:@"Sent Photo 📷" forState:UIControlStateNormal];
        [sender.titleLabel removeFromSuperview];
        
        [self.cameraView takePictureWithCompletionBlock:^(UIImage *image) {
            image = [image scaledToWidth:320];
            if (image) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self removeActivityFromView:sender];
                    [sender addSubview:sender.titleLabel];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self close];
                    });
                });
                START_BACKGROUND_TASK
                [[YoImgUploadClient sharedClient] uploadToS3WithImage:image
                                                      completionBlock:^(NSString *imageURL, NSError *error) {
                                                          if (imageURL) {
                                                              NSDictionary *extraParameters = @{@"link": imageURL};
                                                              
                                                              [[YoManager sharedInstance] yo:self.yo.senderUsername
                                                                           contextParameters:extraParameters
                                                                           completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                                                               if (result != YoResultSuccess) {
                                                                                   [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed to send photo 😔"];
                                                                               }
                                                                               END_BACKGROUND_TASK
                                                                           }];
                                                          }
                                                          else {
                                                              [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
                                                              END_BACKGROUND_TASK
                                                          }
                                                      }];
            }
            else {
                [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
            }
        }];
    }
}

- (void)cameraView:(YoCameraView *)cameraView didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    if (error) {
        DDLogError(@"%@", error);
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
    }
    else {
        [self removeActivityFromView:self.sendButton];
        [self.sendButton setTitle:@"Sent Video 📹" forState:UIControlStateNormal];
        [self.sendButton addSubview:self.sendButton.titleLabel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self close];
        });
        
        START_BACKGROUND_TASK
        NSString *filename = MakeString(@"%@.mov", [[NSProcessInfo processInfo] globallyUniqueString]);
        [[YoImgUploadClient sharedClient] uploadFileToS3WithFilePath:[outputFileURL path]
                                                            filename:filename
                                                         contentType:@"video/quicktime"
                                                     completionBlock:^(NSString *imageURL, NSError *error) {
                                                         
                                                         [[YoManager sharedInstance] yo:self.yo.senderUsername
                                                                      contextParameters:@{@"link": imageURL, @"reply_to": self.yo.yoID}
                                                                      completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                                                          if (result != YoResultSuccess) {
                                                                              [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed to send video 😔"];
                                                                          }
                                                                          END_BACKGROUND_TASK
                                                                      }];
                                                     }];
    }
}

@end
