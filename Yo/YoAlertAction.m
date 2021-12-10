//
//  YoAlertAction.m
//  Yo
//
//  Created by Peter Reveles on 5/26/15.
//
//

#import "YoAlertAction.h"

@interface YoAlertAction ()
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) void (^tapBlock)();
@end

@implementation YoAlertAction

- (instancetype)initWithTitle:(NSString *)title tapBlock:(void (^)())block{
    self = [super init];
    if (self) {
        _title = title;
        _tapBlock = block;
    }
    return self;
}

@end
