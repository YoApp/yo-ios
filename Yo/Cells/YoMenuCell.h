//
//  YoMenuCellTableViewCell.h
//  Yo
//
//  Created by Or Arbel on 5/15/15.
//
//

@interface YoMenuCell : UITableViewCell

@property (nonatomic, assign) NSString *menuTitle;

- (void)startActivityIndicator;

- (void)endActivityIndicator;

@end
