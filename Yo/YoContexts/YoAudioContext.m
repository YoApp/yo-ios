//
//  YoAudioContext.m
//  Yo
//
//  Created by Or Arbel on 7/8/15.
//
//

#import "YoAudioContext.h"
#import <AVFoundation/AVFoundation.h>
#import "YoImgUploadClient.h"
#import "YoUserTableViewCell.h"

@interface YoAudioContext () <AVAudioRecorderDelegate>

@property(nonatomic, strong) AVAudioRecorder *recorder;
@property (strong, nonatomic) NSTimer *recordingTimer;
@property(nonatomic, assign) BOOL isLastYoCancelled;

@end

@implementation YoAudioContext

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
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    
    [self.recorder prepareToRecord];
    [self.recorder record];
}

- (void)stopRecordingAndCancelYo:(BOOL)cancelYo {
    [self.recordingTimer invalidate];
    self.isLastYoCancelled = cancelYo;
    [self.recorder stop];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag {
    if (self.isLastYoCancelled) {
        self.completionBlock(nil, YES);
    }
    else if (flag == NO) {
        self.completionBlock(nil, NO);
    }
    else {
        NSString *filename = MakeString(@"%@.aac", [[NSProcessInfo processInfo] globallyUniqueString]);
        [[YoImgUploadClient sharedClient] uploadFileToS3WithFilePath:[self.recorder.url path]
                                                            filename:filename
                                                         contentType:@"audio/x-caf"
                                                     completionBlock:^(NSString *fileURL, NSError *error) {
                                                         if (fileURL) {
                                                             NSDictionary *extraParameters = @{@"link": fileURL};
                                                             self.completionBlock(extraParameters, NO);
                                                         }
                                                         else {
                                                             [Flurry logError:nil message:nil error:error];
                                                             self.completionBlock(nil, NO);
                                                         }
                                                     }];
    }
}

#pragma mark -

- (BOOL)supportsLongPress {
    return YES;
}

- (NSString *)textForStatusBar {
    return @"Tap name to Yo a voice 🎤";
}

- (NSString *)textForSentYo {
    return @"Sent Voice 🎤";
}

- (BOOL)isLabelGlowing {
    return YES;
}

- (UIView *)backgroundView {
    if ( ! self.view) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        self.view.backgroundColor = [UIColor colorWithHexString:PETER];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voice"]];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.center = CGPointMake(self.view.width/2, self.view.height/2);
        [self.view addSubview:imageView];
    }
    return self.view;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (BOOL)isRecording {
    return self.recorder.isRecording;
}

- (void)stopRecordingAndDontCancelYo {
    [self stopRecordingAndCancelYo:NO];
}  

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    self.completionBlock = block;
    
    [self startRecording];
    
    self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                           target:self
                                                         selector:@selector(stopRecordingAndDontCancelYo)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)checkPermissionsIsLongTap:(BOOL)isLongTap completionHandler:(void (^)(BOOL, NSString *))handler {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
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
}

- (NSString *)getTextToDisplayWhileRecordingIsLongTap:(BOOL)isLongTap {
    return NSLocalizedString(@"Recording", nil);
}

- (NSTimeInterval)getRecordingTimeIsLongTap:(BOOL)isLongTap {
    return 4.0;
}

- (YoRecordingViewStyle)recordingStyleIsLongTap:(BOOL)isLongTap {
    return YoRecordingViewSendAndCancelStyle;
}

+ (NSString *)contextID
{
    return @"audio";
}

- (NSString *)getFirstTimeYoText {
    return @"🎤 Yo Voice";
}

- (BOOL)recordsOnTap {
    return YES;
}

- (BOOL)recordsOnLongTap {
    return YES;
}

@end
