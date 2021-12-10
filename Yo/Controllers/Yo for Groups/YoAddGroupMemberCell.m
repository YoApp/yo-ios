//
//  YoAddGroupMemberCell.m
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import "YoAddGroupMemberCell.h"

@implementation YoAddGroupMemberCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.profileImageView.layer.cornerRadius = 8.0;
    self.profileImageView.layer.masksToBounds = YES;
    
    self.showAdminLabel = NO;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.showAdminLabel = NO;
}

- (void)setShowAdminLabel:(BOOL)showAdminLabel {
    _showAdminLabel = showAdminLabel;
    if (showAdminLabel) {
        self.adminLabel.text = NSLocalizedString(@"admin", nil).capitalizedString;
    }
    else {
        self.adminLabel.text = nil;
    }
    [self.adminLabel setNeedsDisplay];
}

@end
