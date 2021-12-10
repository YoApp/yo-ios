//
//  YOEditCell.h
//  Yo
//
//  Created by Chris Galzerano on 6/26/14.
//
//

#import "YOCell.h"

@interface YOEditCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *leftButton;
@property (nonatomic, weak) IBOutlet UIButton *middleButton;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;

@property (copy, nonatomic) Block leftBlock;
@property (copy, nonatomic) Block middleBlock;
@property (copy, nonatomic) Block rightBlock;

@end
