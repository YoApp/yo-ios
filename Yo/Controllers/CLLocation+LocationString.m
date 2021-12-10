//
//  CLLocation+LocationString.m
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import "CLLocation+LocationString.h"

@implementation CLLocation (LocationString)

- (NSString *)getStringReresentation
{
    return [NSString stringWithFormat:@"%f;%f", self.coordinate.latitude, self.coordinate.longitude];
}

@end
