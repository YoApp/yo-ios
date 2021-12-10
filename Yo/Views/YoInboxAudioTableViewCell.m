//
//  YoInboxAudioTableViewCell.m
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "YoInboxAudioTableViewCell.h"
#import "Yo+Utility.h"
#import <AVFoundation/AVFoundation.h>

#define YoInboxAudioTableViewCellWillPlayNotification @"YoInboxAudioTableViewCellWillPlayNotification"

@interface YoInboxAudioTableViewCell ()
@property (nonatomic, strong, readwrite) UIButton *audioButton;
@property (nonatomic, strong, readwrite) AVPlayer *player;
@end

@implementation YoInboxAudioTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.yoSizeType = YoTVCSizeTypeSquare;
        
        self.audioButton = [[UIButton alloc] init];
        self.audioButton.backgroundColor = [UIColor clearColor];
        [self.audioButton setImage:[UIImage imageNamed:@"audio_play_icon"] forState:UIControlStateNormal];
        [self.audioButton setImage:[UIImage imageNamed:@"audio_play_icon"] forState:UIControlStateHighlighted];
        [self.audioButton setImage:[UIImage imageNamed:@"audio_pause_icon"] forState:UIControlStateSelected];
        
        [self.audioButton addTarget:self action:@selector(audioButtonTouchedUpInside) forControlEvents:UIControlEventTouchUpInside];
        
        self.yoPreview = self.audioButton;
        
        self.player = [[AVPlayer alloc] init];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[self.player currentItem]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioCellWillPlayWithNotifcation:)
                                                     name:YoInboxAudioTableViewCellWillPlayNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self pauseAudio];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

- (void)configureForYo:(Yo *)yo {
    [super configureForYo:yo];
    
    if ([yo hasAudioURL] == NO) {
        //[NSException raise:YoExceptionInValidCellTypeForYo format:@"Sending configureForYo: message to YoInboxAudioTableView Cell with Yo that does not have an audio file URL"];
        return;
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:yo.url];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)audioButtonTouchedUpInside {
    if (self.audioButton.selected) { // selected means it's playing
        [self pauseAudio];
    }
    else {
        [self playAudio];
    }
}

- (void)pauseAudio {
    [self.player pause];
    self.audioButton.selected = NO;
}

- (void)playAudio {
    // give us a chance to stop playing
    [[NSNotificationCenter defaultCenter] postNotificationName:YoInboxAudioTableViewCellWillPlayNotification object:self];
    [self.player play];
    self.audioButton.selected = YES;
}

- (void)resetAudio {
    AVPlayerItem *playerItem = self.player.currentItem;
    [playerItem seekToTime:kCMTimeZero];
}

#pragma mark - Notifications

- (void)audioCellWillPlayWithNotifcation:(NSNotification *)notification {
    id object = [notification object];
    if ([object isKindOfClass:[YoInboxAudioTableViewCell class]]) {
        YoInboxAudioTableViewCell *otherAudioCell = object;
        if ([otherAudioCell isEqual:self]) {
            return;
        }
        else {
            [self pauseAudio];
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self pauseAudio];
    [self resetAudio];
}

@end
