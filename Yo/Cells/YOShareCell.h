//
//  YOShareCell.h
//  Yo
//
//  Created by Or Arbel on 5/25/14.
//
//

#import "YOCell.h"

@interface YOShareCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *leftButton;
@property (nonatomic, weak) IBOutlet UIButton *leftMiddleButton;
@property (nonatomic, weak) IBOutlet UIButton *rightMiddleButton;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;

@property (copy, nonatomic) Block leftBlock;
@property (copy, nonatomic) Block leftMiddleBlock;
@property (copy, nonatomic) Block rightMiddleBlock;
@property (copy, nonatomic) Block rightBlock;

@end
