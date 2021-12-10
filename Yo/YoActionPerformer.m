//
//  YoExectuableAction.m
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import "YoActionPerformer.h"

#import "YoWebBrowserController.h"
#import "YoStoreController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <Appirater/Appirater.h>
#import "YoMainNavigationController.h"
#import "YoiOSAssistant.h"

@implementation YoActionPerformer

+ (void)performAction:(NSString *)action withParameters:(id)params{
    if ([action isEqualToString:YoActionOpenYoStore]) {
        [self openYoStore];
    }
    else if ([action isEqualToString:YoActionAddContact]) {
        NSString *username = params[@"username"];
        [self addContactWithUsername:username];
    }
    else {
        DDLogCDebug(@"%@ could peform %@", self, action);
    }
}

#pragma mark - Actions

+ (void)openYoStore {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoStoreStoryboard bundle:nil];
    UIViewController *storeController = [mainStoryBoard instantiateInitialViewController];
    YoNavigationController *navController = [[YoNavigationController alloc] initWithRootViewController:storeController];
    storeController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [[APPDELEGATE mainController] presentViewController:navController animated:YES completion:nil];
}

+ (void)addContactWithUsername:(NSString *)username {
    if (username == nil) {
        return;
    }
    
    YoUser *user = [[YoUser alloc] init];
    user.username = username;
    
    [[[YoUser me] contactsManager] promoteObjectToTop:user];
    [[[YoUser me] contactsManager] addObject:user withCompletionBlock:nil];
    
    [[APPDELEGATE mainController] animateTopCells:1];
}

@end
