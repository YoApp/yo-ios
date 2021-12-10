//
//  YoClipboardContext.h
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoContextObject.h"

@interface YoClipboardContext : YoContextObject

- (instancetype)initWithClipboardItem:(id)item NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) id item;

+ (BOOL)canPresentItem:(id)item;

@end
