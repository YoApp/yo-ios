//
//  YoMenuFooter.m
//  Yo
//
//  Created by Or Arbel on 5/15/15.
//
//

#import "YoMenuFooter.h"

@implementation YoMenuFooter

- (IBAction)downArrowButtonPressed:(id)sender {
    if (self.downArrowPressedBlock) {
        self.downArrowPressedBlock();
    }
}

@end
