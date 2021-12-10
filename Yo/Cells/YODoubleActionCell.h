//
//  YODoubleActionCell.h
//  Yo
//
//  Created by Or Arbel on 6/15/14.
//
//

#import "YOCell.h"

@interface YODoubleActionCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *leftButton;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;

@property (copy, nonatomic) Block leftBlock;
@property (copy, nonatomic) Block rightBlock;


@end
