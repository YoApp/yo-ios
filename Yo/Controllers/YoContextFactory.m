//
//  YoContextFactory.m
//  Yo
//
//  Created by Peter Reveles on 7/9/15.
//
//

#import "YoContextFactory.h"

#import "YoJustYoContext.h"
#import "YoMapContext.h"
#import "YoClipboardContext.h"
#import "YoLastPhotoContext.h"
#import "YoVideoContext.h"
#import "YoCameraContext.h"
#import "YoEasterEggContext.h"
#import "YoEmojiContext.h"
#import "YoWebContext.h"
#import "YoGifContext.h"
#import "YoAudioContext.h"
#import "YoContextPlusEmoji.h"

@implementation YoContextFactory

+ (YoContextObject *)newContextOfIdentifier:(NSString *)contextID
{
    Class class = [self getContextIDToContextClassDictionary][contextID];
    YoContextObject *context = [[class alloc] init];
    return context;
}

+ (NSDictionary *)getContextIDToContextClassDictionary
{
    static NSDictionary *contextIDsToContextClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        contextIDsToContextClass = @{
                                     [YoJustYoContext contextID]:[YoJustYoContext class],
                                     [YoMapContext contextID]:[YoMapContext class],
                                     [YoClipboardContext contextID]:[YoClipboardContext class],
                                     [YoLastPhotoContext contextID]:[YoLastPhotoContext class],
                                     [YoVideoContext contextID]:[YoVideoContext class],
                                     [YoCameraContext contextID]:[YoCameraContext class],
                                     [YoEasterEggContext contextID]:[YoEasterEggContext class],
                                     [YoEmojiContext contextID]:[YoEmojiContext class],
                                     [YoWebContext contextID]:[YoWebContext class],
                                     [YoGifContext contextID]:[YoGifContext class],
                                     [YoAudioContext contextID]:[YoAudioContext class],
                                     [YoContextPlusEmoji contextID]:[YoContextPlusEmoji class]
                                     };
    });
    return contextIDsToContextClass;
}

@end
