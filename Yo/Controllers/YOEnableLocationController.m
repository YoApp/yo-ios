//
//  YOEnableLocationController.m
//  Yo
//
//  Created by Peter Reveles on 10/8/14.
//
//

#import "YOEnableLocationController.h"

@interface YOEnableLocationController ()

@end

@implementation YOEnableLocationController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.topLabel.text = NSLocalizedString(@"Please Grant Yo\nLocation Access", nil);
    self.topLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:22];

    self.bottomLabel.text = NSLocalizedString(@"Close", nil);
    self.bottomLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];    
}

@end
