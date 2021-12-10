//
//  YOFindFriendCell.m
//  Yo
//
//  Created by Or Arbel on 4/15/14.
//
//

#import "YOFindFriendCell.h"

@implementation YOFindFriendCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.label.font = [UIFont fontWithName:@"Montserrat-Bold" size:38];
    self.nameLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:28];
}

@end
