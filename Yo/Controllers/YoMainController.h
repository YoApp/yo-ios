//
//  YOMainController.h
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YoBaseTableViewController.h"
#import "YoStatusBar.h"
#import "YoNavigationController.h"

#define YoStoreURL @"https://index.justyo.co"

@interface YoMainController : YoBaseViewController

- (void)animateTopCells:(NSInteger)numbersOfCells;

@end
