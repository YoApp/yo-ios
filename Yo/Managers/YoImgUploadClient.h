//
//  YoImgUploadClient.h
//  Yo
//
//  Created by Peter Reveles on 11/3/14.
//
//

/* currently does not support gifs */

#import <Foundation/Foundation.h>

@interface YoImgUploadClient : NSObject

+ (YoImgUploadClient *)sharedClient;

- (void)uploadOptimizedToS3WithImage:(UIImage *)image
                     completionBlock:(void(^)(NSString *imageURL, NSError *error))completion;


- (void)uploadToS3WithImage:(UIImage *)image
            completionBlock:(void(^)(NSString *imageURL, NSError *error))completion;

- (void)uploadFileToS3WithFilePath:(NSString *)filePath
                          filename:(NSString *)filename
                       contentType:(NSString *)contentType
                   completionBlock:(void(^)(NSString *imageURL, NSError *error))completion;

@end