/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoContentLoading.h"

NSString *const YoLoadStateInitial = @"Initial";
NSString *const YoLoadStateLoadingContent = @"LoadingState";
NSString *const YoLoadStateRefreshingContent = @"RefreshingState";
NSString *const YoLoadStateContentLoaded = @"LoadedState";
NSString *const YoLoadStateNoContent = @"NoContentState";
NSString *const YoLoadStateError = @"ErrorState";

@interface YoLoading ()

@property (nonatomic, copy) YoLoadingCompletionBlock block;

@end

@implementation YoLoading

- (instancetype)initWithCompletionHandler:(YoLoadingCompletionBlock)handler
{
	NSParameterAssert(handler != nil);
	self = [super init];
	if (!self) return nil;
	self.block = handler;
	self.current = YES;
	return self;
}

- (void)doneWithNewState:(NSString *)newState error:(NSError *)error update:(YoLoadingUpdateBlock)update
{
	YoLoadingCompletionBlock block = self.block;
	self.block = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        block(newState, error, update);
    });
}

- (void)ignore
{
    [self doneWithNewState:nil error:nil update:NULL];
}

- (void)updateWithContent:(YoLoadingUpdateBlock)update
{
    [self doneWithNewState:YoLoadStateContentLoaded error:nil update:update];
}

- (void)done:(BOOL)success error:(NSError *)error
{
	NSString *newState = success ? YoLoadStateContentLoaded : YoLoadStateError;
	[self doneWithNewState:newState error:error update:NULL];
}

- (void)updateWithNoContent:(YoLoadingUpdateBlock)update
{
    [self doneWithNewState:YoLoadStateNoContent error:nil update:update];
}

@end

@implementation YoStateMachine (AAPLLoadableContentStateMachine)

+ (instancetype)loadableContentStateMachine
{
	YoStateMachine *sm = [[YoStateMachine alloc] init];
    sm.currentState = YoLoadStateInitial;
    sm.validTransitions = @{
        YoLoadStateInitial : @[YoLoadStateLoadingContent],
        YoLoadStateLoadingContent : @[YoLoadStateContentLoaded, YoLoadStateNoContent, YoLoadStateError],
        YoLoadStateRefreshingContent : @[YoLoadStateContentLoaded, YoLoadStateNoContent, YoLoadStateError],
        YoLoadStateContentLoaded : @[YoLoadStateRefreshingContent, YoLoadStateNoContent, YoLoadStateError],
        YoLoadStateNoContent : @[YoLoadStateRefreshingContent, YoLoadStateContentLoaded, YoLoadStateError],
        YoLoadStateError : @[YoLoadStateLoadingContent, YoLoadStateRefreshingContent, YoLoadStateNoContent, YoLoadStateContentLoaded]
    };
    return sm;
}

@end
