//
//  YOEditCell.m
//  Yo
//
//  Created by Chris Galzerano on 6/26/14.
//
//

#import "YOEditCell.h"

@implementation YOEditCell

#define BELIZE     @"2980B9"
#define WISTERIA   @"8E44AD"
#define ALIZARIN   @"e74c3c"

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.leftButton.backgroundColor = [UIColor colorWithHexString:BELIZE];
    self.middleButton.backgroundColor = [UIColor colorWithHexString:WISTERIA];
    self.rightButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.leftButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.middleButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.rightButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
}

- (IBAction)leftButtonTapped:(id)sender {
    if (self.leftBlock) {
        self.leftBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)middleButtonTapped:(id)sender {
    if (self.middleBlock) {
        self.middleBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)rightButtonTapped:(id)sender {
    if (self.rightBlock) {
        self.rightBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

@end