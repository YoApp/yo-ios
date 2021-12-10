//
//  YoNetworkRequestMaker.m
//  Yo
//
//  Created by Peter Reveles on 3/5/15.
//
//

#import "YoNetworkAssistant.h"

@implementation YoNetworkAssistant

+ (void)pullImageFromURL:(NSURL *)url withCompletionBlock:(void (^)(UIImage *image))completionBlock {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    if (request != nil) {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NS_DURING
            UIImage *image = nil;
            if (data) {
                image = [[UIImage alloc] initWithData:data];
            }
            if (completionBlock) {
                completionBlock(image);
            }
            NS_HANDLER
            if (completionBlock) {
                completionBlock(nil);
            }
            NS_ENDHANDLER
        }];
    }
    else {
        completionBlock(nil);
    }
}

@end
