//
//  YOActionCell.m
//  Yo
//
//  Created by Or Arbel on 5/23/14.
//
//

#import "YOActionCell.h"

@implementation YOActionCell

#define BELIZE     @"2980B9"
#define WISTERIA   @"8E44AD"
#define ALIZARIN   @"e74c3c"

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.deleteButton.backgroundColor = [UIColor colorWithHexString:BELIZE];
    self.cancelButton.backgroundColor = [UIColor colorWithHexString:WISTERIA];
    self.blockButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.deleteButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.blockButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
}

- (IBAction)deleteButtonTapped:(id)sender {
    if (self.deleteBlock) {
        self.deleteBlock();
    }
    else {
        DDLogWarn(@"Missing delete block");
    }
}

- (IBAction)blockButtonTapped:(id)sender {
    if (self.blockUserBlock) {
        self.blockUserBlock();
    }
    else {
        DDLogWarn(@"Missing block");
    }
}

- (IBAction)cancelButtonTapped:(id)sender {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    else {
        DDLogWarn(@"Missing cancel block");
    }
}

@end
