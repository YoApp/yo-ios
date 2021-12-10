//
//  YoObjectProvider.m
//  Yo
//
//  Created by Peter Reveles on 8/4/15.
//
//

#import "YoObjectProvider.h"

@interface YoObjectProvider ()
@property (nonatomic, readwrite) NSMutableArray *mutableObjects;
@end

@implementation YoObjectProvider

- (instancetype)init {
    return [self initWithObjects:nil];
}

- (instancetype)initWithObjects:(NSArray *)objects {
    self = [super init];
    if (self) {
        self.mutableObjects = [objects mutableCopy];
    }
    return self;
}

- (id)objectAtIndex:(NSInteger)index {
    return [self.objects objectAtIndex:index];
}

- (void)removeObjectAtIndex:(NSInteger)index {
    [self.mutableObjects removeObjectAtIndex:index];
}

- (NSArray *)objects {
    return [_mutableObjects copy];
}

@end
