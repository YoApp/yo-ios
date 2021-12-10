//
//  YOProfileView.h
//  Yo
//
//  Created by Tomer on 7/23/14.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YOProfileViewMode) {
    YOProfileViewMode_Default,
    YOProfileViewMode_NoImage,
};

@interface YOProfileView : UIView

@property (nonatomic, weak)     IBOutlet UIImageView    *cellImageView;
@property (nonatomic, weak)     IBOutlet UILabel        *fullNameLabel;
@property (weak, nonatomic)     IBOutlet UIImageView    *checkmarkView;

// note: this method needs updating if YOProfileView constraints are changed
- (void)updateCellForMode:(YOProfileViewMode)mode;

@end
