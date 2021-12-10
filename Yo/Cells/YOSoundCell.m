//
//  YOSoundCell.m
//  Yo
//
//  Created by Or Arbel on 5/24/14.
//
//

#import "YOSoundCell.h"

@implementation YOSoundCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.labelButton.backgroundColor = [UIColor clearColor];
    self.playButton.backgroundColor = [UIColor colorWithHexString:WISTERIA];
    self.buyButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.bottomLimiter.backgroundColor = [UIColor colorWithHexString:PETER];
    
    self.labelButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.playButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.buyButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
}

- (IBAction)labelButtonTapped:(id)sender {
    if (self.labelBlock) {
        self.labelBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)playButtonTapped:(id)sender {
    if (self.playBlock) {
        self.playBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)buyButtonTapped:(id)sender {
    if (self.buyBlock) {
        self.buyBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

@end
