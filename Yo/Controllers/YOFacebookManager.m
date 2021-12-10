//
//  YOFacebookManager.m
//  Yo
//
//  Created by Peter Reveles on 10/16/14.
//
//

#import "YOFacebookManager.h"
#import <Social/Social.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

#define HAS_SENT_FBID @"hasSentFBID"

@interface YOFacebookManager ()

@property (nonatomic, strong) FBSDKLoginManager *login;

@end

@implementation YOFacebookManager

+ (instancetype)sharedInstance {
    
    static YOFacebookManager *_currentSession = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentSession = [[self alloc] init];
        _currentSession.login = [[FBSDKLoginManager alloc] init];
    });
    
    return _currentSession;
}

- (void)logInWithCompletionHandler:(void (^)(BOOL isLoggedIn))block {
    
    if (![YOFacebookManager isLoggedIn]) {
        [self.login logInWithReadPermissions:@[@"public_profile", @"email"]
                          fromViewController:[APPDELEGATE topVC]
                                     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                         if (error) {
                                             block(NO);
                                         } else if (result.isCancelled) {
                                             block(NO);
                                         } else {
                                             if (![[YoUser me] fbid]) [self updateFBUserInfo];
                                             block(YES);
                                         }
                                     }];
    }
    else {
        if (block) {
            block(YES);
        }
    }
}

+ (BOOL)isLoggedIn {
    return [FBSDKAccessToken currentAccessToken].tokenString.length > 0;
}

- (NSString *)accessToken {
    return [FBSDKAccessToken currentAccessToken].tokenString;
}

- (void)logout {
    [self.login logOut];
}

#pragma mark - Private Methods

+ (void)shareText:(NSString *)text url:(NSURL *)url image:(UIImage *)image {
    // Apple UI
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *shareSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [shareSheet addURL:url];
        [shareSheet setInitialText:text];
        [shareSheet addImage:image];
        [[APPDELEGATE topVC] presentViewController:shareSheet animated:YES completion:nil];
    }
    else {
        if (![YOFacebookManager isLoggedIn]) {
            
            [[YOFacebookManager sharedInstance] logInWithCompletionHandler:^(BOOL isLoggedIn) {
                if (isLoggedIn) {
                    [YOFacebookManager shareText:text url:url image:image];
                }
            }];
        }
        else {
            
            if (image) {
                FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
                photo.image = image;
                photo.userGenerated = YES;
                FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
                [FBSDKShareDialog showFromViewController:[APPDELEGATE topVC]
                                             withContent:content
                                                delegate:nil];
            }
            else if (url) {
                
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = url;
                content.contentDescription = text;
                [FBSDKShareDialog showFromViewController:[APPDELEGATE topVC]
                                             withContent:content
                                                delegate:nil];
            }
            
        }
    }
}

#pragma mark Sharing

+ (void)shareURL:(NSURL *)url image:(UIImage *)image {
    [self shareText:nil url:url image:image];
}

+ (void)shareURLs:(NSArray *)urls image:(UIImage *)image {
    NSMutableArray *mutableURLs = [urls mutableCopy];
    NSURL *firstURL = [mutableURLs firstObject];
    [mutableURLs removeObject:firstURL];
    
    // create string of components of array
    NSString *text = nil;
    if ([mutableURLs count]) {
        text = [mutableURLs componentsJoinedByString:@"\n"];
    }
    
    [self shareText:text url:firstURL image:image];
}

#pragma mark Hidden

- (void)updateFBUserInfo {
    [self getFacebookProfileInfoWithCompletionBlock:^(id userInfo) {
        NSString *fbid = userInfo[@"id"];
        //NSString *email = userInfo[@"email"];
        
        NSMutableDictionary *params = [NSMutableDictionary new];
        
        if (fbid && fbid.length) params[@"fbid"] = fbid;
        //if (email && email.length) params[@"email"] = email;
        [[YoApp currentSession] changeUserProperties:params completionHandler:nil];
    }];
}

- (void)getFacebookProfileInfoWithCompletionBlock:(void (^)(id userInfo))block {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (block) {
            block(result);
        }
    }];
}

@end
