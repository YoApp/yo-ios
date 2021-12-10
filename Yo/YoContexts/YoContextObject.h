//
//  YoBaseContext.h
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

@class YoUserTableViewCell;
#import "YoRecordingView.h"

extern NSString *const YoNotificationContextDidUpdateConfiguration;

/**
 Subclasses who record content should adhear to YoContextRecording
**/
@protocol YoContextRecording <NSObject>

// Questions

- (BOOL)recordsOnTap;

- (BOOL)recordsOnLongTap;

- (BOOL)isRecording;

// Properties

- (NSTimeInterval)getRecordingTimeIsLongTap:(BOOL)isLongTap;

- (YoRecordingViewStyle)recordingStyleIsLongTap:(BOOL)isLongTap;

- (NSString *)getTextToDisplayWhileRecordingIsLongTap:(BOOL)isLongTap;

// Tasks

- (void)stopRecordingAndCancelYo:(BOOL)cancelYo;

@end


typedef void (^PrepareContextParametersCompletionBlock) (NSDictionary *contextParameters, BOOL cancelled);

@interface YoContextObject : NSObject

@property(nonatomic, copy) PrepareContextParametersCompletionBlock completionBlock;
@property(nonatomic, strong) UITableView *tableView; // @or: UITableView to be assigned by the presenting controller
@property(nonatomic, strong) UIButton *button;
@property(nonatomic, strong) UIView *view;

// trainsitioning (Telling the context things)

- (void)contextDidAppear;
- (void)contextDidDisappear;

- (void)fetchDataIfNeeded;

// misc

- (void)didPresentSettings;

// configuration

- (BOOL)alwaysShowBanner;

- (BOOL)doesNeedSpecialPermission;

- (BOOL)shouldShowPermissionsBanner;

- (BOOL)supportsLongPress;

- (BOOL)isTableViewTransparent;

- (BOOL)isLabelGlowing;

- (BOOL)shouldHideTableViewOnChange;

- (BOOL)canDisplay;

- (UITableViewCellSeparatorStyle)cellSeparatorStyle;

// grabing objects

- (UIView *)permissionsBanner;

- (NSString *)titleForPermissionAlert;

- (NSString *)textForPopupPriorToAskingPermission;

- (NSString *)textForPermissionButton;

- (NSString *)getFirstTimeYoText;

- (NSString *)textForTitleBar;

- (NSString *)textForStatusBar;

- (NSString *)textForSentYo;

- (UIView *)backgroundView;

- (UIButton *)button; // @or: some context may have a button for example camera context (to switch cameras)

/**
 Give your context a unique ID.
 **/
+ (NSString *)contextID;

// requests

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block;

- (void)prepareContextParametersLongTap:(BOOL)isLongTap withCompletionBlock:(PrepareContextParametersCompletionBlock)block;

- (void)checkPermissionsIsLongTap:(BOOL)isLongTap completionHandler:(void (^)(BOOL granted, NSString *errorMessage))handler;

- (void)askForSpecialPermission;

@end
