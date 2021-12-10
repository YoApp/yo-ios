//
//  YOSoundCell.h
//  Yo
//
//  Created by Or Arbel on 5/24/14.
//
//

#import "YOCell.h"

@interface YOSoundCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *labelButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *buyButton;

@property (nonatomic, weak) IBOutlet UIView *bottomLimiter;

@property (copy, nonatomic) Block labelBlock;
@property (copy, nonatomic) Block playBlock;
@property (copy, nonatomic) Block buyBlock;

@end
