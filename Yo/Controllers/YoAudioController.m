//
//  YoAudioController.m
//  Yo
//
//  Created by Or Arbel on 7/8/15.
//
//

#import "YoAudioController.h"
#import "YoInbox.h"
#import <AVFoundation/AVFoundation.h>
#import "YoImgUploadClient.h"

@interface YoAudioController () <AVAudioRecorderDelegate>

@property(nonatomic, weak) IBOutlet UIButton *playButton;

@property(nonatomic, strong) IBOutlet YoButton *sendButton;

@property(nonatomic, strong) AVPlayer *audioPlayer;
@property(nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation YoAudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fullNameLabel.text = self.yo.senderObject.displayName;
    [self.profileImageView setImageWithURL:self.yo.senderObject.photoURL];
    self.usernameLabel.text = [self.yo.creationDate agoString];
    
    AVPlayerItem *aPlayerItem = [[AVPlayerItem alloc] initWithURL:self.yo.url];
    self.audioPlayer = [[AVPlayer alloc] initWithPlayerItem:aPlayerItem];
    
    self.audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.audioPlayer currentItem]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [self playPressed:self.playButton];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[AVAudioSession sharedInstance] setActive:NO error: nil];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    [self.audioPlayer pause];
    self.playButton.selected = NO;
    
    [[[YoUser me] yoInbox] updateOrAddYo:self.yo
                              withStatus:YoStatusRead];
    
}

- (IBAction)closeWithCompletionBlock:(void (^)())completion {
    [self.audioPlayer pause];
    [self.recorder pause];
    [super closeWithCompletionBlock:completion];
}

- (IBAction)playPressed:(UIButton *)sender {
    
    if (self.playButton.selected) {
        self.playButton.selected = NO;
        [self.audioPlayer pause];
    }
    else {
        self.playButton.selected = YES;
        [self.audioPlayer play];
    }
    
}

- (IBAction)leftButtonPressed:(UIButton *)sender {
    
    if (self.isCustomReplies) {
        [super leftButtonPressed:sender];
    }
    else {
        
        [self showActivityOnView:sender];
        
        [sender setTitle:@"Sent 👍" forState:UIControlStateNormal];
        [sender.titleLabel removeFromSuperview];
        [[YoManager sharedInstance] yo:self.yo.senderUsername
                     contextParameters:@{@"context": @"👍", @"reply_to": self.yo.yoID}
                     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                         if (result != YoResultSuccess) {
                             [sender setTitle:@"Failed" forState:UIControlStateNormal];
                         }
                         BOOL success = (result == YoResultSuccess);
                         NSDictionary *context = @{Yo_USERNAME_KEY:self.yo.senderUsername, @"success":@(success)};
                         [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished object:self userInfo:context];
                         [self removeActivityFromView:sender];
                         [sender addSubview:sender.titleLabel];
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [self close];
                         });
                     }];
    }
}

- (IBAction)rightButtonPressed:(UIButton *)sender {
    if (self.isCustomReplies) {
        [super rightButtonPressed:sender];
    }
    else {
        self.sendButton.hidden = NO;
    }
}

- (IBAction)sendButtonPressed:(UIButton *)sender {
    
    if (self.recorder.recording) {
        [self.recorder stop];
        [self.sendButton removeProgressView];
    }
    else {
        
        [sender setTitle:@"Recording Audio" forState:UIControlStateNormal];
        [self.audioPlayer pause];
        [self startRecording];
        [self.sendButton animateProgressWithDuration:4.0];
        [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(stopRecording) userInfo:nil repeats:NO];
    }
}

- (void)startRecording {
    if ( ! self.recorder) {
        
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"MyAudioMemo.aac",
                                   nil];
        
        NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
        
        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryRecord error:nil];
        
        // Define the recorder setting
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        
        // Initiate and prepare the recorder
        self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
        self.recorder.delegate = self;
    }
    [self.recorder prepareToRecord];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [self.recorder record];
}

- (void)stopRecording {
    [self.recorder stop];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)successfully {
    
    if ( ! successfully) {
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed to record 😔"];
        return;
    }
    
    [self removeActivityFromView:self.sendButton];
    [self.sendButton setTitle:@"Sent Voice 🎤" forState:UIControlStateNormal];
    [self.sendButton addSubview:self.sendButton.titleLabel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self close];
    });
    
    START_BACKGROUND_TASK
    NSString *filename = MakeString(@"%@.aac", [[NSProcessInfo processInfo] globallyUniqueString]);
    [[YoImgUploadClient sharedClient] uploadFileToS3WithFilePath:[self.recorder.url path]
                                                        filename:filename
                                                     contentType:@"audio/x-caf"
                                                 completionBlock:^(NSString *imageURL, NSError *error) {
                                                     
                                                     [[YoManager sharedInstance] yo:self.yo.senderUsername
                                                                  contextParameters:@{@"link": imageURL, @"reply_to": self.yo.yoID}
                                                                  completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                                                      if (result != YoResultSuccess) {
                                                                          [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed to send voice 😔"];
                                                                      }
                                                                      END_BACKGROUND_TASK
                                                                  }];
                                                 }];
}

@end
