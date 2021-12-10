//
//  YoNetworkRequestMaker.h
//  Yo
//
//  Created by Peter Reveles on 3/5/15.
//
//

#import <Foundation/Foundation.h>

@interface YoNetworkAssistant : NSObject

+ (void)pullImageFromURL:(NSURL *)url withCompletionBlock:(void (^)(UIImage *image))completionBlock;

@end
