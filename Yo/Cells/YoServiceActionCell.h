//
//  YOActionCell.h
//  Yo
//
//  Created by Or Arbel on 5/23/14.
//
//

#import "YOActionCell.h"

@interface YoServiceActionCell : YOCell

@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *unsubscribeButton;

@property (copy, nonatomic) Block unsubscribeFromServiceBlock;
@property (copy, nonatomic) Block cancelBlock;

@end
