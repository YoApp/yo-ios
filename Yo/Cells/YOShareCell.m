//
//  YOShareCell.m
//  Yo
//
//  Created by Or Arbel on 5/25/14.
//
//

#import "YOShareCell.h"

@implementation YOShareCell

#define BELIZE     @"2980B9"
#define WISTERIA   @"8E44AD"
#define ALIZARIN   @"e74c3c"

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.leftButton.backgroundColor = [UIColor colorWithHexString:BELIZE];
    self.leftMiddleButton.backgroundColor = [UIColor colorWithHexString:WISTERIA];
    self.rightMiddleButton.backgroundColor = [UIColor colorWithHexString:GREEN];
    self.rightButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.leftButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.leftMiddleButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.rightMiddleButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.rightButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    
    self.leftButton.adjustsImageWhenHighlighted = NO;
    self.leftMiddleButton.adjustsImageWhenHighlighted = NO;
    self.rightMiddleButton.adjustsImageWhenHighlighted = NO;
    self.rightButton.adjustsImageWhenHighlighted = NO;
    
    self.leftButton.showsTouchWhenHighlighted = YES;
    self.leftMiddleButton.showsTouchWhenHighlighted = YES;
    self.rightMiddleButton.showsTouchWhenHighlighted = YES;
    self.rightButton.showsTouchWhenHighlighted = YES;
    
    self.leftButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.leftMiddleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.rightMiddleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (IBAction)leftButtonTapped:(id)sender {
    if (self.leftBlock) {
        self.leftBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)leftMiddleButtonTapped:(id)sender {
    if (self.leftMiddleBlock) {
        self.leftMiddleBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)rightMiddleButtonTapped:(id)sender {
    if (self.rightMiddleBlock) {
        self.rightMiddleBlock();
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
