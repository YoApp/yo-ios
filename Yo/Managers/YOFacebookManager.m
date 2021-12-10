//
//  YOFacebookManager.m
//  Yo
//
//  Created by Peter Reveles on 10/16/14.
//
//

#import "YOFacebookManager.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Social/Social.h>

#define HAS_SENT_FBID @"hasSentFBID"

@implementation YOFacebookManager

+ (void)logInWithCompletionHandler:(void (^)(BOOL isLoggedIn))block{
    if (![YOFacebookManager isLoggedIn]) {
        // Open a session showing the user the login UI
        // You must ALWAYS ask for public_profile permissions when opening a session
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             if (![[NSUserDefaults standardUserDefaults] boolForKey:HAS_SENT_FBID]) [self updateFBUserInfo];
             // If the session was opened successfully
             if (!error && state == FBSessionStateOpen){
                 // User is logged in, next step grab contacts
                 block(YES);
             }
             if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
                 // If the session is closed
                 // Show the user the logged-out UI
                 block(NO);
             }
             // Handle errors
             if (error){
                 // Clear this token
                 block(NO);
                 [FBSession.activeSession closeAndClearTokenInformation];
             }
         }];
    }
}

+ (BOOL)isLoggedIn{
    return (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended);
}

#pragma mark - Social

+ (void)shareURL:(NSURL *)url text:(NSString *)text picture:(NSURL *)picture image:(UIImage *)image{
    // Check if the Facebook app is installed and we can present the share dialog
    
    FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:url
                                                                   name:text
                                                                caption:@" "
                                                            description:@" "
                                                                picture:picture];
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentShareDialogWithParams:params]) {
        // Present the share dialog
        [FBDialogs presentShareDialogWithParams:params
                                    clientState:nil
                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                            if(error) {
                                                // An error occurred, we need to handle the error
                                                // See: https://developers.facebook.com/docs/ios/errors
                                                NSLog(@"Error publishing story: %@", error.description);
                                            }
                                        }];
    }
    else {
        // Present the apple share sheet
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                SLComposeViewController *shareSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                [shareSheet setInitialText:text];
                [shareSheet addImage:image];
                [[APPDELEGATE topVC] presentViewController:shareSheet animated:YES completion:nil];
            });
        }
        // Present the feed dialog
        else {
            // Put together the dialog parameters
            NSMutableDictionary *params2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            @" ", @"caption",
                                            @" ", @"description",
                                            nil];
            
            if (text) params2[@"name"] = text;
            if (url) params2[@"link"] = url.absoluteString;
            if (picture) params2[@"picture"] = picture.absoluteString;
            
            // Show the feed dialog
            [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                                   parameters:params2
                                                      handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                          if (error) {
                                                              // An error occurred, we need to handle the error
                                                              // See: https://developers.facebook.com/docs/ios/errors
                                                              NSLog(@"Error publishing story: %@", error.description);
                                                          } else {
                                                              if (result == FBWebDialogResultDialogNotCompleted) {
                                                                  // User cancelled.
                                                              } else {
                                                                  // Handle the publish feed callback
                                                                  
                                                              }
                                                          }
                                                      }];
        }
    }
}

#pragma mark - hidden

+ (void)updateFBUserInfo{
    [FBRequestConnection startWithGraphPath:@"/me"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              /* handle the result */
                              if (!error) {
                                  [self updateUserInfo:result];
                              }
                          }];
}

+ (void)updateUserInfo:(id)userInfo{
    
    NSString *fbid = userInfo[@"id"];
    //NSString *email = userInfo[@"email"];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    if (fbid && fbid.length) params[@"fbid"] = fbid;
    //if (email && email.length) params[@"email"] = email;
    
    [[YoAPIClient sharedInstance] POST:@"rpc/set_me" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAS_SENT_FBID];
    } failure:nil];
}

@end
