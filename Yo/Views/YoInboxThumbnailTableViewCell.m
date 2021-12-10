//
//  YoTableViewCell.m
//  Yo
//
//  Created by Peter Reveles on 8/4/15.
//
//

#import "YoInboxThumbnailTableViewCell.h"
#import "Yo.h"
#import <FLAnimatedImage/FLAnimatedImage.h>

@interface YoInboxThumbnailTableViewCell ()
@property (nonatomic, strong) FLAnimatedImageView *thumbnailImageView;
@property (nonatomic, strong) UIImage *placeholderImage;
@end

@implementation YoInboxThumbnailTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.yoSizeType = YoTVCSizeTypeSquare;
        
        self.placeholderImage = [UIImage imageNamed:@"checkbox_square"];
        
        self.thumbnailImageView = [self newAnimatedImageView];
        self.yoPreview = self.thumbnailImageView;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbnailImageView.image = nil;
    self.thumbnailImageView.animatedImage = nil;
}

- (void)configureForYo:(Yo *)yo {
    [super configureForYo:yo];
    
    NSURL *URL = yo.thumbnailURL;
    BOOL isGif = [yo.type isEqualToString:@"gif"] || [URL.absoluteString hasSuffix:@"gif"];
    [self imageView:self.thumbnailImageView
    setImageFromURL:URL
        placeholder:self.placeholderImage
    isAnimatedImage:isGif];
}

- (void)imageView:(FLAnimatedImageView *)imageView
  setImageFromURL:(NSURL *)imageURL
      placeholder:(UIImage *)placeholder
  isAnimatedImage:(BOOL)isAniamtedImage {
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:imageURL
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if (isAniamtedImage) {
                                                  FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                                                  imageView.animatedImage = animatedImage;
                                              }
                                              else {
                                                  UIImage *image = [UIImage imageWithData:data];
                                                  imageView.image = image;
                                              }
                                          });
                                      }];
    [dataTask resume];
    
    // set placeholder
    if (imageView.image == nil) {
        imageView.image = placeholder;
    }
}

- (FLAnimatedImageView *)newAnimatedImageView {
    FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
    animatedImageView.contentMode = UIViewContentModeScaleAspectFill;
    animatedImageView.layer.masksToBounds = YES;
    animatedImageView.layer.cornerRadius = 3.0f;
    animatedImageView.image = [UIImage imageNamed:@"checkbox_square"];
    return animatedImageView;
}

@end
