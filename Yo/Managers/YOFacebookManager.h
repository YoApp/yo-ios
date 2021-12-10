//
//  YOFacebookManager.h
//  Yo
//
//  Created by Peter Reveles on 10/16/14.
//
//

#import <Foundation/Foundation.h>

@interface YOFacebookManager : NSObject

+ (BOOL)isLoggedIn;

+ (void)logInWithCompletionHandler:(void (^)(BOOL isLoggedIn))block;

+ (void)shareURL:(NSURL *)url text:(NSString *)text picture:(NSURL *)picture image:(UIImage *)image;

@end
