//
//  YoBaseShareSheet.h
//  Yo
//
//  Created by Peter Reveles on 11/15/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Flurry.h"

#define MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL 2

@class YOCell;

typedef NS_ENUM(NSUInteger, YoShareType) {
    YoShareType_URL,
    YoShareType_IMG,
};

@protocol YoSendDelegate <NSObject>
- (void)noImgURLFor:(YoModelObject *)object cellAtIndexPath:(NSIndexPath *)indexPath;
- (void)noImgURLForYoAllCell:(YOCell *)cell;
- (NSArray *)indexPathsInWaiting; // of NSIndexPath
@end

@interface YoBaseExtensionController : UIViewController

- (NSString *)yoAllWithYoAllStatusCell:(YOCell *)statusCell;
- (NSString *)sendYoTo:(YoModelObject *)object;
- (NSString *)sendYoTo:(YoModelObject *)object withIndexPath:(NSIndexPath *)indexPath;

- (void)close;

@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (nonatomic, strong) NSString *urlToShare;

@property (nonatomic, assign) YoShareType shareType;

@property (nonatomic, weak) id <YoSendDelegate> delegate;

// intercept
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end