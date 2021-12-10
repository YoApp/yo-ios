/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoStateMachine.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

/// The initial state.
extern NSString *const YoLoadStateInitial;
/// The first load of content.
extern NSString *const YoLoadStateLoadingContent;
/// Subsequent loads after the first.
extern NSString *const YoLoadStateRefreshingContent;
/// After content is loaded successfully.
extern NSString *const YoLoadStateContentLoaded;
/// No content is available.
extern NSString *const YoLoadStateNoContent;
/// An error occurred while loading content.
extern NSString *const YoLoadStateError;

/// A block that performs updates on the object that is loading. The object parameter is the original object that received the -loadContentWithBlock: message.
typedef void (^YoLoadingUpdateBlock)(id object);

/// A block called when loading completes.
typedef void (^YoLoadingCompletionBlock)(NSString *state, NSError *error, YoLoadingUpdateBlock update);

/// A helper class passed to the content loading block of an YoLoadableContentViewController.
@interface YoLoading : NSObject

/// Signals that this result should be ignored. Sends a nil value for the state to the completion handler.
- (void)ignore;
/// Signals that loading is complete. This triggers a transition to either the Loaded or Error state.
- (void)done:(BOOL)success error:(NSError *)error;
/// Signals that loading is complete, transitions into the Loaded state and then runs the update block.
- (void)updateWithContent:(YoLoadingUpdateBlock)update;
/// Signals that loading completed with no content, transitions to the No Content state and then runs the update block.
- (void)updateWithNoContent:(YoLoadingUpdateBlock)update;

/// Is this the current loading operation? When -loadContentWithBlock: is called it should inform previous instances of YoLoading that they are no longer the current instance.
@property (nonatomic, getter=isCurrent) BOOL current;

- (instancetype)initWithCompletionHandler:(YoLoadingCompletionBlock)handler;

@end

/// A protocol that defines content loading behavior
@protocol YoContentLoading <NSObject, YoStateMachineDelegate>

/// The current state of the content loading operation
@property (nonatomic, copy) NSString *loadingState;
/// Any error that occurred during content loading.
@property (nonatomic, strong) NSError *loadingError;

/// Public method used to begin loading the content.
- (void)loadContent;
/// Public method used to reset the content of the receiver.
- (void)resetContent;

/// Method used by implementers of -loadContent to manage the loading operation. Usually implemented by the base class that adopts ITCContentLoading.
- (void)loadContentWithBlock:(void(^)(YoLoading *loading))block;

@end

@interface YoStateMachine (YoLoadableContentStateMachine)

+ (instancetype)loadableContentStateMachine;

@end

#pragma clang diagnostic pop
