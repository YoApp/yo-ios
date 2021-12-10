//
//  YOActionCell.h
//  Yo
//
//  Created by Or Arbel on 5/23/14.
//
//

#import "YOCell.h"

@interface YOActionCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *blockButton;

@property (copy, nonatomic) Block deleteBlock;
@property (copy, nonatomic) Block blockUserBlock;
@property (copy, nonatomic) Block cancelBlock;

@end
