//
//  YoLastPhotoContext.m
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoLastPhotoContext.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <FXBlurView/FXBlurView.h>
#import "YoImgUploadClient.h"

@interface YoLastPhotoContext ()

@property(nonatomic, strong) UIImageView *bgImageView;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UIImage *lastImage;
@property(nonatomic, strong) ALAssetRepresentation *lastRepr;

@property(nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@implementation YoLastPhotoContext

- (NSString *)textForStatusBar {
    return @"Tap name to Yo your latest photo 😎";
}

- (NSString *)textForSentYo {
    return @"Sent Yo Photo!";
}

- (void)hasNewPhoto:(void (^)(BOOL hasNewPhoto))block  {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusAuthorized) {
        if ( ! self.assetsLibrary) {
            self.assetsLibrary = [[ALAssetsLibrary alloc] init];
        }
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                          usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                              if (nil != group) {
                                                  [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                      if (result) {
                                                          
                                                          *stop = YES;
                                                          self.lastRepr = [result defaultRepresentation];
                                                          self.lastImage = [UIImage imageWithCGImage:[self.lastRepr fullScreenImage]];
                                                          
                                                          if ( ! [[[NSUserDefaults standardUserDefaults] objectForKey:@"last.photo.url"]
                                                                  isEqualToString:[[result valueForProperty:ALAssetPropertyAssetURL] absoluteString]]) {
                                                              
                                                              NSDate *date = [result valueForProperty:ALAssetPropertyDate];
                                                              if ([[NSDate date] timeIntervalSinceDate:date] < 60 * 30) { // @or: 30 minutes
                                                                  [[NSUserDefaults standardUserDefaults] setObject:[[result valueForProperty:ALAssetPropertyAssetURL] absoluteString] forKey:@"last.photo.url"];
                                                                  block(YES);
                                                              }
                                                              else {
                                                                  block(NO);
                                                              }
                                                          }
                                                          else {
                                                              block(NO);
                                                          }
                                                      }
                                                  }];
                                              }
                                          }
                                        failureBlock:^(NSError *error) {
                                            DDLogError(@"%@", error);
                                            // @or: no permission? TODO handle
                                        }];
    }
    else {
        block(NO);
    }
}

- (UIImage *)lastPhoto {
    return self.lastImage;
}

- (UIView *)backgroundView {
    
    if ( ! self.view) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        
        self.bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.bgImageView.image = [self.lastImage blurredImageWithRadius:40 iterations:3 tintColor:[UIColor blackColor]];
        [self.view addSubview:self.bgImageView];
        
        self.imageView = [[UIImageView alloc] initWithImage:self.lastImage];
        self.imageView.frame = self.view.bounds;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.imageView];
    }
    return self.view;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    
    [[YoImgUploadClient sharedClient] uploadOptimizedToS3WithImage:self.imageView.image completionBlock:^(NSString *imageURL, NSError *error) {
        if (imageURL) {
            NSDictionary *extraParameters = @{@"link": imageURL};
            block(extraParameters, NO);
        }
        else {
            block(nil, NO);
        }
    }];
    
}

+ (NSString *)contextID
{
    return @"last_photo";
}

- (NSString *)getFirstTimeYoText {
    return @"📷 Yo Photo";
}

@end
