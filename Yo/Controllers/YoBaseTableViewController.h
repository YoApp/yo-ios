//
//  BaseController.h
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YOCell.h"
#import <AVFoundation/AVFoundation.h>
#import "YOShareCell.h"
#import "YOEditCell.h"
#import "YoContactBookConstants.h"
#import "YoBaseViewController.h"

typedef NS_ENUM(NSUInteger, YoInviteType) {
    YoInviteType_Default,
    YoInviteType_YoCount,
};

@interface YoBaseTableViewController : YoBaseViewController

@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSIndexPath *showShareMenuForIndexPath;
@property(nonatomic, assign) BOOL verifyOutgoingSMS;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewTop;

@property(nonatomic, strong) NSString *shareText;

#pragma mark - Sharing to be moved

- (void)tweetWithImage:(UIImage *)image message:(NSString *)message;
- (void)shareOnFacebookWithImage:(UIImage *)image;

- (void)shareWithAppleDefaultUIText:(NSString *)text url:(NSURL *)url image:(UIImage *)image data:(NSData *)data;

#pragma mark - Utility

- (void)colorCell:(YOCell *)cell withIndexPath:(NSIndexPath *)indexPath;

- (void)presentBrowserWithURLString:(NSString *)urlString;

- (YOShareCell *)createYOShareCellWithInviteType:(YoInviteType)inviteType;

- (void)reloadTableViewCellsColorsInSection:(NSInteger)section;

// utility methods

- (BOOL)currentDeviceIsIpod;

@end
