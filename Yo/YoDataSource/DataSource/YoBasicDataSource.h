/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoDataSource.h"

/// A subclass of YoDataSource that manages a single section of items backed by an NSArray.
@interface YoBasicDataSource : YoDataSource

@property (nonatomic, copy) NSArray *items;

/// By default, setting the items is not animated.
- (void)setItems:(NSArray *)items animated:(BOOL)animated;

@end
