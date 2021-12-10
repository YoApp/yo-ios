//
//  YoTwitterManager.h
//  Yo
//
//  Created by Peter Reveles on 2/11/15.
//
//

#import <Foundation/Foundation.h>

@interface YoTwitterHandleManager : NSObject

+ (instancetype)sharedInstance;

- (void)loadWithCompletionBlock:(void (^)(BOOL success))block;

- (void)updateWithCompletionBlock:(void (^)(BOOL success))block;

- (NSString *)handleForYoUsername:(NSString *)username;

@end
