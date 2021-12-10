//
//  YODoubleActionCell.m
//  Yo
//
//  Created by Or Arbel on 6/15/14.
//
//

#import "YODoubleActionCell.h"

@implementation YODoubleActionCell

#define BELIZE     @"2980B9"
#define WISTERIA   @"8E44AD"
#define ALIZARIN   @"e74c3c"

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.leftButton.backgroundColor = [UIColor colorWithHexString:BELIZE];
    self.rightButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.leftButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
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

- (IBAction)rightButtonTapped:(id)sender {
    if (self.rightBlock) {
        self.rightBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}


@end
