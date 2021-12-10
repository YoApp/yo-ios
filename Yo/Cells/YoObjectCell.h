//
//  YoObjectCell.h
//  Yo
//
//  Created by Or Arbel on 6/2/15.
//
//

#import "Yo.h"

@interface YoObjectCell : UITableViewCell

@property (strong,nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong,nonatomic) IBOutlet YoLabel *label;
@property (strong,nonatomic) IBOutlet YoLabel *timeLabel;

@property (strong,nonatomic) IBOutlet YoLabel *singleLabel;

@end
