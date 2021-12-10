//
//  YoABTestingFrameWork.h
//  Yo
//
//  Created by Peter Reveles on 2/13/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YoABTestOption) {
    YoABTestOptionA,
    YoABTestOptionB
};

typedef NS_ENUM(NSUInteger, YoABTest) {
    YoABTestNoTest,
    YoABTestOBoarding,
    YoABTestShowDetailsButton
};

@interface YoABTestingFrameWork : NSObject

+ (instancetype)sharedInstance;

- (void)loadWithCompletionBlock:(void (^)(BOOL success))block;

- (void)updateWithCompletionBlock:(void (^)(BOOL success))block;

- (YoABTestOption)optionForTest:(YoABTest)test;

- (NSString *)log;

@end
