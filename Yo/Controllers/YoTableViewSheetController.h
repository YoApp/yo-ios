//
//  YoTableViewSheetController.h
//  Yo
//
//  Created by Peter Reveles on 10/24/14.
//
//

// Notes:
// init share sheet as soon as possible before presenting to allow time to load contacts
// if necessary

#import "YoBaseTableViewController.h"

#define CELL_HEIGHT 80.0f
#define MAX_VISIBLE_CELL_COUNT_iPhone4 4
#define MAX_VISIBLE_CELL_COUNT_iPhone5 5

@protocol YoTableViewSheetDelegate <NSObject>
@optional
- (void)yoTableViewSheetWillDissmiss;
- (void)yoTableViewSheetDidDissmiss;

@end

@interface YoTableViewSheetController : YoBaseTableViewController

-(instancetype)init;

@property (nonatomic, weak) id <YoTableViewSheetDelegate> delegate;

//** sets data source for table view and reloads */
- (void)updateDataSource:(NSArray *)dataSource;

- (void)presentShareSheetOnView:(UIView *)view;

- (void)dissmiss;

//** Feel free to implement this method and return ur own */
- (int)maxVisibleCellCount;

+ (YOCell *)createCell;

@end
