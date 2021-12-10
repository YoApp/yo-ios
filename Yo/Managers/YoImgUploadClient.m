//
//  YoImgUploadClient.m
//  Yo
//
//  Created by Peter Reveles on 11/3/14.
//
//

#import "YoImgUploadClient.h"
#import "Yo_Extensions.h"
//#import <Bolts/Bolts.h>
#import <AWSS3/AWSS3.h>


@interface YoImgUploadClient ()
@end

@implementation YoImgUploadClient

+ (YoImgUploadClient *)sharedClient {
    
    static YoImgUploadClient *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc] init];
    });
    
    return _sharedClient;
}

- (void)uploadOptimizedToS3WithImage:(UIImage *)image completionBlock:(void (^)(NSString *, NSError *))completion {
    
    image = [image scaledToWidth:640.0f];
    [self uploadToS3WithImage:image completionBlock:completion];
    
}

#pragma mark S3

- (void)uploadToS3WithImage:(UIImage *)image
            completionBlock:(void(^)(NSString *imageURL, NSError *error))completion {
    
    NSString *filename = MakeString(@"%@.jpg", [[NSProcessInfo processInfo] globallyUniqueString]);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToURL:[NSURL fileURLWithPath:filePath] atomically:YES];
    
    [self uploadFileToS3WithFilePath:filePath
                            filename:filename
                         contentType:@"image/jpeg"
                     completionBlock:completion];
    
}

- (void)uploadFileToS3WithFilePath:(NSString *)filePath
                          filename:(NSString *)filename
                       contentType:(NSString *)contentType
                   completionBlock:(void(^)(NSString *imageURL, NSError *error))completion {
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                    identityPoolId:@"us-east-1:04f68538-bb09-4840-9b6b-faf799854230"];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    NSString *username = [YoUser me].username?:@"NULL";
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = MakeString(@"yo-app1");
    uploadRequest.key = MakeString(@"users/%@/uploads/%@", username, filename);
    uploadRequest.body = [NSURL fileURLWithPath:filePath];
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    uploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:fileSize];
    uploadRequest.contentType = contentType;
    
    [[[AWSS3TransferManager defaultS3TransferManager] upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        // Do something with the response
        NSLog(@"result: %@", task.error);
       
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        
        if (completion) {
            
            if (task.error) {
                [Flurry logError:nil message:nil error:task.error];
                completion(nil, task.error);
            }
            else {
                NSString *urlString = MakeString(@"https://s3.amazonaws.com/yo-app1/users/%@/uploads/%@", username, filename);
                completion(urlString, nil);
            }
        }
        
        return nil;
    }];
    
}

@end
