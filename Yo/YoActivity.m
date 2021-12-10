//
//  YoActivity.m
//  Yo
//
//  Created by Peter Reveles on 2/18/15.
//
//

#import "YoActivity.h"

@interface YoActivity ()
@property(nonatomic, strong) NSDate *startDate;
@property(nonatomic, strong) NSDate *stopDate;
@property(nonatomic, strong) NSString *name;
@end

@implementation YoActivity

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name;
    }
    return self;
}

- (void)started {
    _startDate = [NSDate date];
    _stopDate = nil;
}

- (void)ended {
    _stopDate = [NSDate date];
}

- (NSTimeInterval)timeElapsed {
    NSTimeInterval timeElapsed = 0.0f;
    
    if (self.startDate) {
        if (self.stopDate) {
            timeElapsed = [self.stopDate timeIntervalSinceDate:self.startDate];
        }
        else {
            timeElapsed = [[NSDate date] timeIntervalSinceDate:self.startDate];
        }
    }
    
    return timeElapsed;
}

- (NSDictionary *)info {
    NSDictionary *info = info = @{@"name":self.name?:@"no_name",
                                  @"time_elapsed":@([self timeElapsed])};
    return info;
}

@end
