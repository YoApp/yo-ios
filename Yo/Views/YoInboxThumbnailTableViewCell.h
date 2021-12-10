//
//  YoTableViewCell.h
//  Yo
//
//  Created by Peter Reveles on 8/4/15.
//
//

#import "YoInboxTableViewCell.h"

@class Yo, FLAnimatedImageView;

@interface YoInboxThumbnailTableViewCell : YoInboxTableViewCell

@property (nonatomic, strong, readonly) FLAnimatedImageView *thumbnailImageView;

/// a convinience method
- (void)configureForYo:(Yo *)yo;

@end
