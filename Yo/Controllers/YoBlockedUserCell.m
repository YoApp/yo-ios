//
//  YOBlockedUserCell.m
//  Yo
//
//  Created by Peter Reveles on 6/2/15.
//
//

#import "YoBlockedUserCell.h"

@interface YoBlockedUserCell ()
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@end

NSString *const YoUserPlaceholderImageName = @"new_action_profileedit";

@implementation YoBlockedUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _checkMarkImageView.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
}

- (void)prepareForReuse
{
    _checkMarkImageView.hidden = YES;
}

- (void)objectDidChange
{
    [self updateUI];
}

- (void)updateUI
{
    NSAssert(self.object != nil, @"<Yo> attempt to updateUI with nil object");
    
    self.nameLabel.text = [self.object displayName];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    // Configure the view for the selected state
    self.checkMarkImageView.hidden = !selected;
}

@end
