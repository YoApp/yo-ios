/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import <UIKit/UIKit.h>

#import "YoCollectionViewGridLayoutAttributes.h"

extern NSUInteger const YoGlobalSection;

extern NSString * const YoCollectionElementKindPlaceholder;

@interface YoCollectionViewGridLayout : UICollectionViewLayout

/// Recompute the layout for a specific item. This will remeasure the cell and then update the layout.
- (void)invalidateLayoutForItemAtIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic) UICollectionViewScrollDirection scrollDirection; // default is UICollectionViewScrollDirectionVertical

@end
