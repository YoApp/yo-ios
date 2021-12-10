//
//  YoAnalytics.h
//  Yo
//
//  Created by Peter Reveles on 2/17/15.
//
//

#import <Foundation/Foundation.h>
#import "YoActivity.h"
#import "YoViewControllerProtocol.h"

@interface YoActivityManager : NSObject

#pragma mark - Life 

+ (instancetype)sharedInstance;

#pragma mark - Intial Setup

- (NSString *)getAppID;

//** Call to begin session. This will generate a new session id. */
- (void)startSession;

- (NSInteger)getSessionNumber;

@property (nonatomic, strong) NSString *username;

//** Call this on viewWillAppear for all controllers. */
- (void)controllerWillBePresented:(UIViewController <YoViewControllerProtocol> *)viewController;

- (void)controllerPresented:(UIViewController <YoViewControllerProtocol> *)viewController;

- (void)controllerDidDisAppear:(UIViewController <YoViewControllerProtocol> *)viewController NS_EXTENSION_UNAVAILABLE("Not available in extension");

@property(nonatomic, readonly) NSString *currentViewController;

- (NSArray *)getControllerHistoryWithMaxCount:(NSInteger)maxCount;

@end
