//
//  YoImageController.h
//  Yo
//
//  Created by Or Arbel on 6/2/15.
//
//

#import "YoPresentorController.h"

typedef enum {
    YoImageControllerModeImage,
    YoImageControllerModeGIF,
    YoImageControllerModeVideo
} YoImageControllerMode;

@interface YoImageController : YoPresentorController

@property(assign, nonatomic) YoImageControllerMode mode;

@end
