//
//  YoBannerStore.h
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import <Foundation/Foundation.h>
#import "YoContextBanner.h"

@interface YoBannerStore : NSObject

- (void)getContextBannerForOpenCount:(NSInteger)openCount
                              currentContexts:(NSArray *)contexts
                                     location:(CLLocation *)location
                        withCompletionHandler:(void (^)(YoContextBanner *banner, NSError *error))handler;

@end
