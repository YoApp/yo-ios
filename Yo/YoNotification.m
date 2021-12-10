//
//  YoNotification.m
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import "YoNotification.h"

@interface YoNotification ()
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NSInteger openCountThreshold;
@property (nonatomic, strong) id notificationInfo;
@end

@implementation YoNotification

- (instancetype)initWithMessage:(NSString *)message tapBlock:(void (^)())tapBlock {
    self = [super init];
    if (self) {
        _message = [message copy];
        _tapBlock = tapBlock;
    }
    return self;
}

@end
