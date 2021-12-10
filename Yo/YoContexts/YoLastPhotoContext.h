//
//  YoLastPhotoContext.h
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoContextObject.h"

@interface YoLastPhotoContext : YoContextObject

- (void)hasNewPhoto:(void (^)(BOOL hasNewPhoto))block;

@end
