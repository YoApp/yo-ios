//
//  YoCameraContext.h
//  Yo
//
//  Created by Or Arbel on 5/31/15.
//
//

#import "YoContextObject.h"

@interface YoCameraContext : YoContextObject <YoContextRecording>

- (BOOL)isRecording;

@end
