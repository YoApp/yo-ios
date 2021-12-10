//
//  YoAddGroupMemberCell.h
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//


@interface YoAddGroupMemberCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *adminLabel;
@property (nonatomic, strong) IBOutlet UIImageView *removeButtonImageView;

@property (assign, nonatomic) BOOL showAdminLabel;
@end
