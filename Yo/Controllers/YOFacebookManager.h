 //
//  YOFacebookManager.h
//  Yo
//
//  Created by Peter Reveles on 10/16/14.
//
//

#import <Foundation/Foundation.h>

@interface YOFacebookManager : NSObject

+ (instancetype)sharedInstance;

- (void)logout;

+ (BOOL)isLoggedIn;

- (NSString *)accessToken;

- (void)logInWithCompletionHandler:(void (^)(BOOL isLoggedIn))block;

- (void)getFacebookProfileInfoWithCompletionBlock:(void (^)(id userInfo))block;

#pragma mark Sharing

+ (void)shareURL:(NSURL *)url image:(UIImage *)image;

+ (void)shareURLs:(NSArray *)urls image:(UIImage *)image;

+ (void)presentAppInviteController;

+ (void)presentSendMessageControllerwithTitle:(NSString *)title message:(NSString *)message url:(NSURL *)url;

+ (void)migrateToken;

@end
