//
//  YoInboxAudioTableViewCell.h
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "YoInboxTableViewCell.h"

@interface YoInboxAudioTableViewCell : YoInboxTableViewCell

/// a convinience method
- (void)configureForYo:(Yo *)yo;

- (void)pauseAudio;

- (void)playAudio;

- (void)resetAudio;

@end
