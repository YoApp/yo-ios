/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoCollectionViewGridLayout.h"
#import "YoCollectionViewGridLayoutAttributes.h"
#import "YoDataSourceDelegate.h"
#import "YoLayoutMetrics.h"

typedef CGSize (^YoLayoutMeasureBlock)(NSUInteger itemIndex, CGRect frame);
typedef CGSize (^YoLayoutMeasureKindBlock)(NSString *kind, NSUInteger itemIndex, CGRect frame);

@class YoGridLayoutInfo;

/// Layout information about a supplementary item (header, footer, or placeholder)
@interface YoGridLayoutSupplementalItemInfo : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic) CGFloat height;
@property (nonatomic) BOOL shouldPin;
@property (nonatomic) BOOL visibleWhileShowingPlaceholder;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIColor *selectedBackgroundColor;
@property (nonatomic) BOOL hidden;
@property (nonatomic) UIEdgeInsets padding;
@property (nonatomic) NSInteger zIndex;

@end

/// Layout information about an item (cell)
@interface YoGridLayoutItemInfo : NSObject

@property (nonatomic) CGRect frame;
@property (nonatomic) BOOL needSizeUpdate;

@end

/// Layout information for a section
@interface YoGridLayoutSectionInfo : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic, weak) YoGridLayoutInfo *layoutInfo;

@property (nonatomic, readonly) NSMutableArray *items;
@property (nonatomic, readonly) NSMutableDictionary *supplementalItemArraysByKind;
- (void)enumerateArraysOfOtherSupplementalItems:(void(^)(NSString *kind, NSArray *items, BOOL *stop))block;
@property (nonatomic, readonly) YoGridLayoutSupplementalItemInfo *placeholder;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic) UIEdgeInsets separatorInsets;
@property (nonatomic) UIEdgeInsets sectionSeparatorInsets;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic, strong) UIColor *sectionSeparatorColor;
@property (nonatomic) BOOL showsSectionSeparatorWhenLastSection;
@property (nonatomic, readonly) CGFloat columnWidth;

@property (nonatomic, strong) NSMutableArray *pinnableHeaderAttributes;
@property (nonatomic, strong) NSMutableArray *nonPinnableHeaderAttributes;
@property (nonatomic, strong) YoCollectionViewGridLayoutAttributes *backgroundAttribute;

- (YoGridLayoutSupplementalItemInfo *)addSupplementalItemOfKind:(NSString *)kind;
- (YoGridLayoutSupplementalItemInfo *)addSupplementalItemAsPlaceholder;
- (YoGridLayoutItemInfo *)addItem;

- (void)computeLayoutForSection:(NSUInteger)sectionIndex origin:(CGPoint)start measureItem:(CGSize(^)(NSIndexPath *, CGRect))measureItemBlock measureSupplementaryItem:(CGSize(^)(NSString *, NSIndexPath *, CGRect))measureSupplementaryItemBlock;

@end

/// The layout information
@interface YoGridLayoutInfo : NSObject

@property (nonatomic) CGSize size;
@property (nonatomic) CGFloat contentOffsetY;
@property (nonatomic, strong) NSMutableDictionary *sections;

- (YoGridLayoutSectionInfo *)addSectionWithIndex:(NSInteger)sectionIndex;

- (void)invalidate;

@end

/// Used to look up supplementary & decoration attributes
@interface YoIndexPathKind : NSObject<NSCopying>

- (instancetype)initWithIndexPath:(NSIndexPath *)indexPath kind:(NSString *)kind;

@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) NSString *kind;

@end
