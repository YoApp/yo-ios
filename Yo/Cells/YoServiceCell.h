//
//  YoServiceCell.h
//  Yo
//
//  Created by Or Arbel on 8/30/14.
//
//

#import "YOCell.h"

typedef NS_ENUM(NSUInteger, YoServiceCellType) {
    YoServiceCellTypeYoable,
    YoServiceCellTypeSubcategory,
};

@interface YoServiceCell : YOCell

@property(nonatomic, strong) IBOutlet UILabel *nameLabel;
@property(nonatomic, strong) IBOutlet UILabel *descriptionLabel;

@property(nonatomic, strong) IBOutlet UIButton *toggleSubscribtionButton;
@property(nonatomic, strong) IBOutlet UIButton *openButton;

@property(nonatomic, strong) NSDictionary *service;

@property (copy, nonatomic) Block toggleTappedBlock;
@property (copy, nonatomic) Block openTappedBlock;

@property (assign, nonatomic) YoServiceCellType type;

@end
