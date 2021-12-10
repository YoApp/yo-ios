//
//  YOActionCell.m
//  Yo
//
//  Created by Or Arbel on 5/23/14.
//
//

#import "YoServiceActionCell.h"

@implementation YoServiceActionCell

#define BELIZE     @"2980B9"
#define WISTERIA   @"8E44AD"
#define ALIZARIN   @"e74c3c"

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.cancelButton.backgroundColor = [UIColor colorWithHexString:WISTERIA];
    self.unsubscribeButton.backgroundColor = [UIColor colorWithHexString:ALIZARIN];
    
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.unsubscribeButton.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
}

- (IBAction)unsubscribeButtonTapped:(id)sender {
    if (self.unsubscribeFromServiceBlock) {
        self.unsubscribeFromServiceBlock();
    }
    else {
        DDLogWarn(@"Missing unsubscribe block");
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
