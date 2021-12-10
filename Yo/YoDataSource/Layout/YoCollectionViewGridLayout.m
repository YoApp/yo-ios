/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoCollectionViewGridLayout_Internal.h"
#import "YoGridLayoutSeparatorView.h"
#import "UICollectionReusableView+YoGridLayout.h"
#import "UIView+YoAdditions.h"

NSUInteger const YoGlobalSection = NSUIntegerMax;

NSString *const YoCollectionElementKindPlaceholder = @"YoCollectionElementKindPlaceholder";
static NSString *const YoGridLayoutRowSeparatorKind = @"YoGridLayoutRowSeparatorKind";
static NSString *const YoGridLayoutSectionSeparatorKind = @"YoGridLayoutSectionSeparatorKind";
static NSString *const YoGridLayoutGlobalHeaderBackgroundKind = @"YoGridLayoutGlobalHeaderBackgroundKind";

static const CGFloat YoGridLayoutMeasuringHeight = 1000;

static const NSInteger YoGridLayoutZIndexDefault = 1;
static const NSInteger YoGridLayoutZIndexPlaceholder = 50;
static const NSInteger YoGridLayoutZIndexSeparator = 100;
static const NSInteger YoGridLayoutZIndexHeader = 1000;
static const NSInteger YoGridLayoutZIndexPinned = 10000;
static const NSInteger YoGridLayoutZIndexPinnedOverlap = 9000;

static inline NSUInteger YoGridLayoutGetIndices(NSIndexPath *indexPath, NSUInteger *outIndex, BOOL globalSection) {
	if (indexPath.length == 1) {
		if (outIndex) *outIndex = globalSection ? [indexPath indexAtPosition:0] : NSNotFound;
		return globalSection ? YoGlobalSection : [indexPath indexAtPosition:0];
	}
	if (outIndex) *outIndex = [indexPath indexAtPosition:1];
	return [indexPath indexAtPosition:0];
}

@interface YoCollectionViewGridLayout ()

@property (nonatomic) CGSize layoutSize;
@property (nonatomic) CGSize oldLayoutSize;
@property (nonatomic) BOOL preparingLayout;

@property (nonatomic) NSInteger totalNumberOfItems;
@property (nonatomic, strong) NSMutableArray *layoutAttributes;
@property (nonatomic, strong) NSMutableArray *pinnableAttributes;
@property (nonatomic, strong) YoGridLayoutInfo *layoutInfo;
@property (nonatomic, strong) NSMutableDictionary *indexPathKindToSupplementaryAttributes;
@property (nonatomic, strong) NSMutableDictionary *oldIndexPathKindToSupplementaryAttributes;
@property (nonatomic, strong) NSMutableDictionary *indexPathKindToDecorationAttributes;
@property (nonatomic, strong) NSMutableDictionary *oldIndexPathKindToDecorationAttributes;
@property (nonatomic, strong) NSMutableDictionary *indexPathToItemAttributes;
@property (nonatomic, strong) NSMutableDictionary *oldIndexPathToItemAttributes;

/// A dictionary mapping the section index to the YoDataSourceSectionOperationDirection value
@property (nonatomic, strong) NSMutableDictionary *updateSectionDirections;
@property (nonatomic, strong) NSMutableSet *insertedIndexPaths;
@property (nonatomic, strong) NSMutableSet *removedIndexPaths;
@property (nonatomic, strong) NSMutableIndexSet *insertedSections;
@property (nonatomic, strong) NSMutableIndexSet *removedSections;
@property (nonatomic, strong) NSMutableIndexSet *reloadedSections;
@property (nonatomic) CGPoint contentOffsetDelta;
@end

@implementation YoCollectionViewGridLayout  {
    struct {
        /// the data source has the snapshot metrics method
		BOOL dataSourceHasSnapshotMetrics;
        /// layout data becomes invalid if the data source changes
		BOOL layoutDataIsValid;
        /// layout metrics will only be valid if layout data is also valid
		BOOL layoutMetricsAreValid;
        /// contentOffset of collection view is valid
		BOOL useCollectionViewContentOffset;
    } _flags;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    [self yo_commonInitCollectionViewGridLayout];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self)
        return nil;

    [self yo_commonInitCollectionViewGridLayout];
    return self;
}

- (void)yo_commonInitCollectionViewGridLayout
{
    [self registerClass:[YoGridLayoutSeparatorView class] forDecorationViewOfKind:YoGridLayoutRowSeparatorKind];
    [self registerClass:[YoGridLayoutSeparatorView class] forDecorationViewOfKind:YoGridLayoutSectionSeparatorKind];
    [self registerClass:[YoGridLayoutSeparatorView class] forDecorationViewOfKind:YoGridLayoutGlobalHeaderBackgroundKind];

    _indexPathKindToDecorationAttributes = [NSMutableDictionary dictionary];
    _oldIndexPathKindToDecorationAttributes = [NSMutableDictionary dictionary];
    _indexPathToItemAttributes = [NSMutableDictionary dictionary];
    _oldIndexPathToItemAttributes = [NSMutableDictionary dictionary];
    _indexPathKindToSupplementaryAttributes = [NSMutableDictionary dictionary];
    _oldIndexPathKindToSupplementaryAttributes = [NSMutableDictionary dictionary];

    _updateSectionDirections = [NSMutableDictionary dictionary];
    _layoutAttributes = [NSMutableArray array];
    _pinnableAttributes = [NSMutableArray array];
}

#pragma mark - UICollectionViewLayout API

+ (Class)layoutAttributesClass
{
    return [YoCollectionViewGridLayoutAttributes class];
}

+ (Class)invalidationContextClass
{
    return [YoGridLayoutInvalidationContext class];
}

- (void)invalidateLayoutWithContext:(YoGridLayoutInvalidationContext *)context
{
    NSParameterAssert([context isKindOfClass:[YoGridLayoutInvalidationContext class]]);

    BOOL invalidateDataSourceCounts = context.invalidateDataSourceCounts;
    BOOL invalidateEverything = context.invalidateEverything;
    BOOL invalidateLayoutMetrics = context.invalidateLayoutMetrics;

    _flags.useCollectionViewContentOffset = context.invalidateLayoutOrigin;

    if (invalidateEverything) {
        _flags.layoutMetricsAreValid = NO;
        _flags.layoutDataIsValid = NO;
    }

    if (_flags.layoutDataIsValid) {
        _flags.layoutMetricsAreValid = !(invalidateDataSourceCounts || invalidateLayoutMetrics);

        if (invalidateDataSourceCounts)
            _flags.layoutDataIsValid = NO;
    }

    [super invalidateLayoutWithContext:context];
}

- (void)prepareLayout
{
	if (!self.collectionView.window) {
		_flags.layoutMetricsAreValid = _flags.layoutDataIsValid = NO;
	}
	
	[super prepareLayout];

    if (!CGRectIsEmpty(self.collectionView.bounds)) {
        [self buildLayout];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;
{
    NSMutableArray *result = [NSMutableArray array];

    [self filterSpecialAttributes];

    for (YoCollectionViewGridLayoutAttributes *attributes in _layoutAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect))
            [result addObject:attributes];
    }

    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger itemIndex;
	NSUInteger sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, YES);

	if (sectionIndex == YoGlobalSection || sectionIndex >= _layoutInfo.sections.count) {
        return nil;
	}

	YoCollectionViewGridLayoutAttributes *attributes = _indexPathToItemAttributes[indexPath];
	if (attributes) {
		return attributes;
	}
	
    YoGridLayoutSectionInfo *section = [self sectionInfoForSectionAtIndex:sectionIndex];

	if (itemIndex >= section.items.count) {
        return nil;
	}

	UICollectionView *collectionView = self.collectionView;
	YoDataSource *dataSource = (YoDataSource *)collectionView.dataSource;
	if (![dataSource isKindOfClass:[YoDataSource class]]) {
		dataSource = nil;
	}

    YoGridLayoutItemInfo *item = section.items[itemIndex];

    attributes = [[self.class layoutAttributesClass] layoutAttributesForCellWithIndexPath:indexPath];

    // Need to be clever if we're still preparing the layout…
    attributes.frame = item.frame;
	attributes.zIndex = YoGridLayoutZIndexDefault;
    attributes.backgroundColor = section.backgroundColor;
    attributes.selectedBackgroundColor = section.selectedBackgroundColor;
	attributes.hidden = _preparingLayout || [dataSource collectionView:collectionView itemAtIndexPathIsHidden:indexPath];

	if (!_preparingLayout) {
        _indexPathToItemAttributes[indexPath] = attributes;
	}
	
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger itemIndex;
	NSUInteger sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, YES);

    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    YoCollectionViewGridLayoutAttributes *attributes = _indexPathKindToSupplementaryAttributes[indexPathKind];
    if (attributes)
        return attributes;

    YoGridLayoutSectionInfo *section = [self sectionInfoForSectionAtIndex:sectionIndex];
    YoGridLayoutSupplementalItemInfo *supplementalItem;

	if ([kind isEqualToString:YoCollectionElementKindPlaceholder]) {
		// supplementalItem might become nil if there's no placeholder, but that just means we return attributes that are empty
        supplementalItem = section.placeholder;
	} else {
		NSArray *supplementalItems = section.supplementalItemArraysByKind[kind];
		if (itemIndex >= supplementalItems.count) { return nil; };
        supplementalItem = supplementalItems[itemIndex];
    }

    attributes = [[self.class layoutAttributesClass] layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];

    // Need to be clever if we're still preparing the layout…
    if (_preparingLayout) {
        attributes.hidden = YES;
    }

	attributes.frame = supplementalItem.frame;
	attributes.zIndex = supplementalItem.zIndex;
    attributes.padding = supplementalItem.padding;
    attributes.backgroundColor = supplementalItem.backgroundColor ? : section.backgroundColor;
    attributes.selectedBackgroundColor = section.selectedBackgroundColor;

	if (!_preparingLayout) {
        _indexPathKindToSupplementaryAttributes[indexPathKind] = attributes;
	}

    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath *)indexPath
{
    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    YoCollectionViewGridLayoutAttributes *attributes = _indexPathKindToDecorationAttributes[indexPathKind];
    if (attributes)
        return attributes;

	NSUInteger itemIndex;
	NSUInteger sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, YES);

	attributes = [[self.class layoutAttributesClass] layoutAttributesForDecorationViewOfKind:kind withIndexPath:indexPath];

	if (_preparingLayout) {
		attributes.hidden = YES;
	}

	if ([kind isEqual:YoGridLayoutSectionSeparatorKind]) {
		YoGridLayoutSectionInfo *section = [self sectionInfoForSectionAtIndex:sectionIndex];

		attributes.backgroundColor = section.sectionSeparatorColor;
		attributes.zIndex = YoGridLayoutZIndexSeparator;

		CGRect frame = CGRectMake(section.sectionSeparatorInsets.left, 0, CGRectGetWidth(section.frame) - section.sectionSeparatorInsets.left - section.sectionSeparatorInsets.right, self.collectionView.yo_hairlineWidth);
		if (itemIndex == 0) {
			frame.origin.y = section.frame.origin.y;
		} else if (itemIndex == 1) {
			frame.origin.y = CGRectGetMaxY(section.frame);
		}
		attributes.frame = frame;
	}

	if (!_preparingLayout) {
		_indexPathKindToDecorationAttributes[indexPathKind] = attributes;
	}

	return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds
{
    CGRect bounds = self.collectionView.bounds;
    YoGridLayoutInvalidationContext *context = (YoGridLayoutInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];

    context.invalidateLayoutOrigin = newBounds.origin.x != bounds.origin.x || newBounds.origin.y != bounds.origin.y;

    // Only recompute the layout if the actual width has changed.
    context.invalidateLayoutMetrics = ((newBounds.size.width != bounds.size.width) || (newBounds.origin.x != bounds.origin.x));
    return context;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    UICollectionView *collectionView = self.collectionView;
    UIEdgeInsets insets = collectionView.contentInset;
    CGPoint targetContentOffset = proposedContentOffset;
    targetContentOffset.y += insets.top;

    CGFloat availableHeight = CGRectGetHeight(UIEdgeInsetsInsetRect(collectionView.bounds, insets));
    targetContentOffset.y = MIN(targetContentOffset.y, MAX(0, _layoutSize.height - availableHeight));

    NSInteger firstInsertedIndex = [self.insertedSections firstIndex];
    if (NSNotFound != firstInsertedIndex && YoDataSourceSectionOperationDirectionNone != [self.updateSectionDirections[@(firstInsertedIndex)] intValue]) {
        YoGridLayoutSectionInfo *globalSection = [self sectionInfoForSectionAtIndex:YoGlobalSection];
        CGFloat globalNonPinnableHeight = [self heightOfAttributes:globalSection.nonPinnableHeaderAttributes];
        CGFloat globalPinnableHeight = CGRectGetHeight(globalSection.frame) - globalNonPinnableHeight;

        YoGridLayoutSectionInfo *sectionInfo = [self sectionInfoForSectionAtIndex:firstInsertedIndex];
        CGFloat minY = CGRectGetMinY(sectionInfo.frame);
        if (targetContentOffset.y + globalPinnableHeight > minY) {
            // need to make the section visible
            targetContentOffset.y = MAX(globalNonPinnableHeight, minY - globalPinnableHeight);
        }
    }

    targetContentOffset.y -= insets.top;
    return targetContentOffset;
}

- (CGSize)collectionViewContentSize
{
	if (_preparingLayout) {
		return _oldLayoutSize;
	}
    return _layoutSize;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
	NSUInteger sectionIndex, itemIndex;

    self.insertedIndexPaths = [NSMutableSet set];
    self.removedIndexPaths = [NSMutableSet set];
    self.insertedSections = [NSMutableIndexSet indexSet];
    self.removedSections = [NSMutableIndexSet indexSet];
    self.reloadedSections = [NSMutableIndexSet indexSet];

    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        if (UICollectionUpdateActionInsert == updateItem.updateAction) {
            NSIndexPath *indexPath = updateItem.indexPathAfterUpdate;
	        sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, NO);
            if (itemIndex == NSNotFound)
                [self.insertedSections addIndex:sectionIndex];
            else
                [self.insertedIndexPaths addObject:indexPath];
        }
        else if (UICollectionUpdateActionDelete == updateItem.updateAction) {
            NSIndexPath *indexPath = updateItem.indexPathBeforeUpdate;
	        sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, NO);
            if (itemIndex == NSNotFound)
                [self.removedSections addIndex:sectionIndex];
            else
                [self.removedIndexPaths addObject:indexPath];
        }
        else if (UICollectionUpdateActionReload == updateItem.updateAction) {
            NSIndexPath *indexPath = updateItem.indexPathAfterUpdate;
	        sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, NO);
            if (itemIndex == NSNotFound)
                [self.reloadedSections addIndex:sectionIndex];
        }
    }

    UICollectionView *collectionView = self.collectionView;
    CGPoint contentOffset = collectionView.contentOffset;

    CGPoint newContentOffset = [self targetContentOffsetForProposedContentOffset:contentOffset];
    self.contentOffsetDelta = CGPointMake(newContentOffset.x - contentOffset.x, newContentOffset.y - contentOffset.y);

    [super prepareForCollectionViewUpdates:updateItems];
}

- (void)finalizeCollectionViewUpdates
{
    self.insertedIndexPaths = nil;
    self.removedIndexPaths = nil;
    self.insertedSections = nil;
    self.removedSections = nil;
    self.reloadedSections = nil;
    [self.updateSectionDirections removeAllObjects];
	[super finalizeCollectionViewUpdates];
}

// FIXME: <rdar://problem/16520988>
// This method is ACTUALLY called for supplementary views
- (NSArray *)indexPathsToDeleteForDecorationViewOfKind:(NSString *)kind
{
    NSMutableArray *result = [NSMutableArray array];

    // FIXME: <rdar://problem/16117605> Be smarter about updating the attributes on layout updates
    [_oldIndexPathKindToDecorationAttributes enumerateKeysAndObjectsUsingBlock:^(YoIndexPathKind *indexPathKind, YoCollectionViewGridLayoutAttributes *attributes, BOOL *stop) {
        if (![indexPathKind.kind isEqualToString:kind])
            return;
        // If we have a similar decoration view in the new attributes, skip it.
        if (_indexPathKindToDecorationAttributes[indexPathKind])
            return;
        [result addObject:indexPathKind.indexPath];
    }];

    return result;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingDecorationElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
        return [self initialLayoutAttributesForAttributes:[_indexPathKindToDecorationAttributes[indexPathKind] copy] slidingInFromDirection:direction];
    }

    BOOL inserted = [self.insertedSections containsIndex:section];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    result = [_indexPathKindToDecorationAttributes[indexPathKind] copy];

    if (inserted)
        result.alpha = 0;

    if (reloaded) {
        if (!_oldIndexPathKindToDecorationAttributes[indexPathKind])
            result.alpha = 0;
    }

    return [self initialLayoutAttributesForAttributes:result];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingDecorationElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
        return [self finalLayoutAttributesForAttributes:[_oldIndexPathKindToDecorationAttributes[indexPathKind] copy] slidingAwayFromDirection:direction];
    }

    BOOL removed = [self.removedSections containsIndex:section];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    result = [_oldIndexPathKindToDecorationAttributes[indexPathKind] copy];

    if (removed)
        result.alpha = 0;

    if (reloaded) {
        if (!_indexPathKindToDecorationAttributes[indexPathKind])
            result.alpha = 0;
    }

    return [self finalLayoutAttributesForAttributes:result];
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
        result = [_indexPathKindToSupplementaryAttributes[indexPathKind] copy];
        if ([YoCollectionElementKindPlaceholder isEqualToString:kind]) {
            result.alpha = 0;
            return [self initialLayoutAttributesForAttributes:result];
        }

        return [self initialLayoutAttributesForAttributes:result slidingInFromDirection:direction];
    }

    BOOL inserted = [self.insertedSections containsIndex:section];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    result = [_indexPathKindToSupplementaryAttributes[indexPathKind] copy];

    if (inserted) {
        result.alpha = 0;
        result = [self initialLayoutAttributesForAttributes:result];
    }
    else if (reloaded) {
        if (!_oldIndexPathKindToSupplementaryAttributes[indexPathKind])
            result.alpha = 0;
    }

    return result;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
        result = [_oldIndexPathKindToSupplementaryAttributes[indexPathKind] copy];
        if ([YoCollectionElementKindPlaceholder isEqualToString:kind]) {
            result.alpha = 0;
            return [self finalLayoutAttributesForAttributes:result];
        }

        return [self finalLayoutAttributesForAttributes:result slidingAwayFromDirection:direction];
    }

    BOOL removed = [self.removedSections containsIndex:section];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
    result = [_oldIndexPathKindToSupplementaryAttributes[indexPathKind] copy];

    if (removed || reloaded)
        result.alpha = 0;

    return [self finalLayoutAttributesForAttributes:result];
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        return [self initialLayoutAttributesForAttributes:[_indexPathToItemAttributes[indexPath] copy] slidingInFromDirection:direction];
    }

    BOOL inserted = [self.insertedSections containsIndex:section] || [self.insertedIndexPaths containsObject:indexPath];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    result = [_indexPathToItemAttributes[indexPath] copy];

    if (inserted)
        result.alpha = 0;

    if (reloaded) {
        if (!_oldIndexPathToItemAttributes[indexPath])
            result.alpha = 0;
    }

    return [self initialLayoutAttributesForAttributes:result];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoCollectionViewGridLayoutAttributes *result = nil;

	NSUInteger section = YoGridLayoutGetIndices(indexPath, NULL, YES);

    YoDataSourceSectionOperationDirection direction = [_updateSectionDirections[@(section)] intValue];
	if (YoDataSourceSectionOperationDirectionNone != direction) {
        return [self finalLayoutAttributesForAttributes:[_oldIndexPathToItemAttributes[indexPath] copy] slidingAwayFromDirection:direction];
    }

    BOOL removed = [self.removedIndexPaths containsObject:indexPath] || [self.removedSections containsIndex:section];
    BOOL reloaded = [self.reloadedSections containsIndex:section];

    result = [_oldIndexPathToItemAttributes[indexPath] copy];

    if (removed)
        result.alpha = 0;

    if (reloaded) {
        // There's no item at this index path, so cross fade
        if (!_indexPathToItemAttributes[indexPath])
            result.alpha = 0;
    }

    return [self finalLayoutAttributesForAttributes:result];
}


#pragma mark - helpers

- (void)updateFlagsFromCollectionView
{
    id dataSource = self.collectionView.dataSource;
    _flags.dataSourceHasSnapshotMetrics = [dataSource respondsToSelector:@selector(snapshotMetrics)];
}

- (YoGridLayoutSectionInfo *)sectionInfoForSectionAtIndex:(NSInteger)sectionIndex
{
    return _layoutInfo.sections[@(sectionIndex)];
}

- (NSDictionary *)snapshotMetrics
{
    if (!_flags.dataSourceHasSnapshotMetrics)
        return nil;
    YoDataSource *dataSource = (YoDataSource *)self.collectionView.dataSource;
    return [dataSource snapshotMetrics];
}

- (void)resetLayoutInfo
{
    if (!_layoutInfo)
        _layoutInfo = [[YoGridLayoutInfo alloc] init];
    else
        [_layoutInfo invalidate];

    NSMutableDictionary *tmp;

    tmp = _oldIndexPathKindToSupplementaryAttributes;
    _oldIndexPathKindToSupplementaryAttributes = _indexPathKindToSupplementaryAttributes;
    _indexPathKindToSupplementaryAttributes = tmp;
    [_indexPathKindToSupplementaryAttributes removeAllObjects];

    tmp = _oldIndexPathToItemAttributes;
    _oldIndexPathToItemAttributes = _indexPathToItemAttributes;
    _indexPathToItemAttributes = tmp;
    [_indexPathToItemAttributes removeAllObjects];

    tmp = _oldIndexPathKindToDecorationAttributes;
    _oldIndexPathKindToDecorationAttributes = _indexPathKindToDecorationAttributes;
    _indexPathKindToDecorationAttributes = tmp;
    [_indexPathKindToDecorationAttributes removeAllObjects];
}

- (CGSize)measureSupplementalItemOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionView *collectionView = self.collectionView;
    id<UICollectionViewDataSource> dataSource = collectionView.dataSource;

    UICollectionReusableView *header = [dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
	CGSize fittingSize = CGSizeMake(_layoutInfo.size.width, YoGridLayoutMeasuringHeight);
    CGSize size = [header yo_preferredLayoutSizeFittingSize:fittingSize];
    [header removeFromSuperview];
    return size;
}

/// Create a new section from the metrics.
- (void)createSectionFromMetrics:(YoLayoutSectionMetrics *)metrics forSectionAtIndex:(NSInteger)sectionIndex
{
    UICollectionView *collectionView = self.collectionView;
    UIColor *clearColor = [UIColor clearColor];
	CGFloat height = _layoutInfo.size.height;

    BOOL globalSection = YoGlobalSection == sectionIndex;

	CGFloat rowHeight = metrics.rowHeight ?: YoRowHeightDefault;
    BOOL variableRowHeight = (rowHeight == YoRowHeightVariable);
    NSInteger numberOfItemsInSection = (globalSection ? 0 : [collectionView numberOfItemsInSection:sectionIndex]);

    NSAssert(rowHeight != YoRowHeightRemainder || numberOfItemsInSection == 1, @"Only one item is permitted in a section with remainder row height.");
    NSAssert(rowHeight != YoRowHeightRemainder || sectionIndex == [collectionView numberOfSections] - 1, @"Remainder row height may only be set for last section.");

    if (variableRowHeight)
		rowHeight = YoGridLayoutMeasuringHeight;

    YoGridLayoutSectionInfo *section = [_layoutInfo addSectionWithIndex:sectionIndex];

    UIColor *separatorColor = metrics.separatorColor;
    UIColor *sectionSeparatorColor = metrics.sectionSeparatorColor;
    UIColor *backgroundColor = metrics.backgroundColor;
    UIColor *selectedBackgroundColor = metrics.selectedBackgroundColor;

    section.backgroundColor = ([backgroundColor isEqual:clearColor] ? nil : backgroundColor);
    section.selectedBackgroundColor = ([selectedBackgroundColor isEqual:clearColor] ? nil : selectedBackgroundColor);
    section.separatorColor = ([separatorColor isEqual:clearColor] ? nil : separatorColor);
    section.sectionSeparatorColor = ([sectionSeparatorColor isEqual:clearColor] ? nil : sectionSeparatorColor);
    section.sectionSeparatorInsets = metrics.sectionSeparatorInsets;
    section.separatorInsets = metrics.separatorInsets;
    section.showsSectionSeparatorWhenLastSection = metrics.showsSectionSeparatorWhenLastSection;
    section.insets = metrics.padding;

	for (YoLayoutSupplementaryMetrics *suplMetrics in metrics.supplementaryViews) {
		if ([suplMetrics.supplementaryViewKind isEqual:UICollectionElementKindSectionFooter] && !suplMetrics.height) {
			continue;
		}

		YoGridLayoutSupplementalItemInfo *info = [section addSupplementalItemOfKind:suplMetrics.supplementaryViewKind];
		info.zIndex = suplMetrics.zIndex ?: YoGridLayoutZIndexHeader;
		info.height = suplMetrics.height;
		info.padding = suplMetrics.padding;
		info.hidden = suplMetrics.hidden;

		if ([suplMetrics.supplementaryViewKind isEqual:UICollectionElementKindSectionHeader]) {
			info.shouldPin = suplMetrics.shouldPin;
			info.visibleWhileShowingPlaceholder = suplMetrics.visibleWhileShowingPlaceholder;

			backgroundColor = suplMetrics.backgroundColor;
			if (backgroundColor)
				info.backgroundColor = [backgroundColor isEqual:clearColor] ? nil : backgroundColor;
			else
				info.backgroundColor = section.backgroundColor;

			selectedBackgroundColor = suplMetrics.selectedBackgroundColor;
			if (selectedBackgroundColor)
				info.selectedBackgroundColor = [selectedBackgroundColor isEqual:clearColor] ? nil : selectedBackgroundColor;
			else
				info.selectedBackgroundColor = section.selectedBackgroundColor;
		} else {
			info.backgroundColor = suplMetrics.backgroundColor;
		}
	};

	CGFloat columnWidth = section.columnWidth;

	// A section can either have a placeholder or items. Arbitrarily deciding the placeholder takes precedence.
    if (metrics.hasPlaceholder) {
        YoGridLayoutSupplementalItemInfo *placeholder = [section addSupplementalItemAsPlaceholder];
        placeholder.height = height;
    }
    else {
        for (NSInteger itemIndex = 0; itemIndex < numberOfItemsInSection; ++itemIndex) {
            YoGridLayoutItemInfo *itemInfo = [section addItem];
            itemInfo.frame = CGRectMake(0, 0, columnWidth, rowHeight);
            if (variableRowHeight)
                itemInfo.needSizeUpdate = YES;
        }
    }
}

- (void)createLayoutInfoFromDataSource
{
    [self resetLayoutInfo];

    UICollectionView *collectionView = self.collectionView;
    NSDictionary *layoutMetrics = [self snapshotMetrics];

	NSInteger numberOfSections = collectionView.numberOfSections;

	_layoutInfo.size = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).size;

    YoLayoutSectionMetrics *globalMetrics = layoutMetrics[@(YoGlobalSection)];
    if (globalMetrics)
        [self createSectionFromMetrics:globalMetrics forSectionAtIndex:YoGlobalSection];

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex) {
        YoLayoutSectionMetrics *metrics = layoutMetrics[@(sectionIndex)];
        [self createSectionFromMetrics:metrics forSectionAtIndex:sectionIndex];
    }
}

- (void)invalidateLayoutForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger itemIndex;
	NSUInteger sectionIndex = YoGridLayoutGetIndices(indexPath, &itemIndex, NO);

    YoGridLayoutSectionInfo *sectionInfo = [self sectionInfoForSectionAtIndex:sectionIndex];
    YoGridLayoutItemInfo *itemInfo = sectionInfo.items[itemIndex];

    UICollectionView *collectionView = self.collectionView;

    // This call really only makes sense if the section has variable height rows…
    CGRect rect = itemInfo.frame;
    CGSize fittingSize = CGSizeMake(sectionInfo.columnWidth, UILayoutFittingExpandedSize.height);

    // This is really only going to work if it's an YoCollectionViewCell, but we'll pretend
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    rect.size = [cell yo_preferredLayoutSizeFittingSize:fittingSize];
    itemInfo.frame = rect;

    YoGridLayoutInvalidationContext *context = [[YoGridLayoutInvalidationContext alloc] init];
    context.invalidateLayoutMetrics = YES;
    [self invalidateLayoutWithContext:context];
}

- (void)addLayoutAttributesForSection:(YoGridLayoutSectionInfo *)section atIndex:(NSInteger)sectionIndex dataSource:(YoDataSource *)dataSource
{
	UICollectionView *collectionView = self.collectionView;

    Class attributeClass = self.class.layoutAttributesClass;

    CGRect sectionFrame = section.frame;

    BOOL globalSection = (YoGlobalSection == sectionIndex);

    UIColor *separatorColor = section.separatorColor;
    UIColor *sectionSeparatorColor = section.sectionSeparatorColor;
    NSInteger numberOfItems = [section.items count];

	const CGFloat hairline = collectionView.yo_hairlineWidth;

    [section.pinnableHeaderAttributes removeAllObjects];
    [section.nonPinnableHeaderAttributes removeAllObjects];
	
	NSMutableArray *newAttributes = [NSMutableArray array];

    if (YoGlobalSection == sectionIndex && section.backgroundColor) {
        // Add the background decoration attribute
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:0];
        YoCollectionViewGridLayoutAttributes *backgroundAttribute = [attributeClass layoutAttributesForDecorationViewOfKind:YoGridLayoutGlobalHeaderBackgroundKind withIndexPath:indexPath];
        // This will be updated by -filterSpecialAttributes
        backgroundAttribute.frame = section.frame;
        backgroundAttribute.unpinnedY = section.frame.origin.y;
		backgroundAttribute.zIndex = YoGridLayoutZIndexDefault;
        backgroundAttribute.pinnedHeader = NO;
        backgroundAttribute.backgroundColor = section.backgroundColor;
        backgroundAttribute.hidden = NO;
        [newAttributes addObject:backgroundAttribute];

        section.backgroundAttribute = backgroundAttribute;
        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:YoGridLayoutGlobalHeaderBackgroundKind];
        _indexPathKindToDecorationAttributes[indexPathKind] = backgroundAttribute;
    }

	NSArray *headers = section.supplementalItemArraysByKind[UICollectionElementKindSectionHeader], *footers = section.supplementalItemArraysByKind[UICollectionElementKindSectionFooter];

	[headers enumerateObjectsUsingBlock:^(YoGridLayoutSupplementalItemInfo *header, NSUInteger headerIndex, BOOL *stop) {
        CGRect headerFrame = header.frame;

        // ignore headers if there are no items and the header isn't a global header
        if (!numberOfItems && !header.visibleWhileShowingPlaceholder)
            return;

        if (!header.height || header.hidden)
            return;

        NSIndexPath *indexPath = globalSection ? [NSIndexPath indexPathWithIndex:headerIndex] : [NSIndexPath indexPathForItem:headerIndex inSection:sectionIndex];
        YoCollectionViewGridLayoutAttributes *headerAttribute = [attributeClass layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
        headerAttribute.frame = headerFrame;
        headerAttribute.unpinnedY = headerFrame.origin.y;
		headerAttribute.zIndex = header.zIndex;
        headerAttribute.pinnedHeader = NO;
        headerAttribute.backgroundColor = header.backgroundColor ? : section.backgroundColor;
        headerAttribute.selectedBackgroundColor = header.selectedBackgroundColor;
        headerAttribute.padding = header.padding;
        headerAttribute.hidden = NO;
        [newAttributes addObject:headerAttribute];

        if (header.shouldPin) {
            [section.pinnableHeaderAttributes addObject:headerAttribute];
            [self.pinnableAttributes addObject:headerAttribute];
        }
        else if (globalSection) {
            [section.nonPinnableHeaderAttributes addObject:headerAttribute];
        }

        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:UICollectionElementKindSectionHeader];
        _indexPathKindToSupplementaryAttributes[indexPathKind] = headerAttribute;
    }];

    YoCollectionViewGridLayoutAttributes *lastAttribute = [newAttributes lastObject];
    if (![lastAttribute.representedElementKind isEqualToString:YoGridLayoutSectionSeparatorKind] && sectionSeparatorColor && _totalNumberOfItems) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
        YoCollectionViewGridLayoutAttributes *separatorAttributes = [attributeClass layoutAttributesForDecorationViewOfKind:YoGridLayoutSectionSeparatorKind withIndexPath:indexPath];
        separatorAttributes.frame = CGRectMake(section.sectionSeparatorInsets.left, section.frame.origin.y, CGRectGetWidth(sectionFrame) - section.sectionSeparatorInsets.left - section.sectionSeparatorInsets.right, hairline);
        separatorAttributes.backgroundColor = sectionSeparatorColor;
		separatorAttributes.zIndex = YoGridLayoutZIndexSeparator;
        [newAttributes addObject:separatorAttributes];

        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:YoGridLayoutSectionSeparatorKind];
        _indexPathKindToDecorationAttributes[indexPathKind] = separatorAttributes;
    }

    YoGridLayoutSupplementalItemInfo *placeholder = section.placeholder;
    if (placeholder) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
        YoCollectionViewGridLayoutAttributes *placeholderAttribute = [attributeClass layoutAttributesForSupplementaryViewOfKind:YoCollectionElementKindPlaceholder withIndexPath:indexPath];
        placeholderAttribute.frame = placeholder.frame;
		placeholderAttribute.zIndex = YoGridLayoutZIndexPlaceholder;
        [newAttributes addObject:placeholderAttribute];

        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:YoCollectionElementKindPlaceholder];
        _indexPathKindToSupplementaryAttributes[indexPathKind] = placeholderAttribute;
    }

	_totalNumberOfItems += section.items.count;

	[section.items enumerateObjectsUsingBlock:^(YoGridLayoutItemInfo *item, NSUInteger itemIndex, BOOL *stop) {
		CGRect frame = item.frame;

		// If there's a separator, add it above the current row…
		if (itemIndex && separatorColor) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
			YoCollectionViewGridLayoutAttributes *separatorAttributes = [attributeClass layoutAttributesForDecorationViewOfKind:YoGridLayoutRowSeparatorKind withIndexPath:indexPath];
			separatorAttributes.frame = CGRectMake(section.separatorInsets.left, CGRectGetMinY(frame), CGRectGetWidth(frame) - section.separatorInsets.left - section.separatorInsets.right, hairline);
			separatorAttributes.backgroundColor = separatorColor;
			separatorAttributes.zIndex = YoGridLayoutZIndexSeparator;
			[newAttributes addObject:separatorAttributes];

			YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:YoGridLayoutRowSeparatorKind];
			_indexPathKindToDecorationAttributes[indexPathKind] = separatorAttributes;
		}

		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex++ inSection:sectionIndex];
		YoCollectionViewGridLayoutAttributes *newAttribute = [attributeClass layoutAttributesForCellWithIndexPath:indexPath];
		newAttribute.frame = frame;
		newAttribute.zIndex = YoGridLayoutZIndexDefault;
		newAttribute.backgroundColor = section.backgroundColor;
		newAttribute.selectedBackgroundColor = section.selectedBackgroundColor;
		newAttribute.hidden = [dataSource collectionView:collectionView itemAtIndexPathIsHidden:indexPath];

		[newAttributes addObject:newAttribute];

		_indexPathToItemAttributes[indexPath] = newAttribute;
	}];

	[section enumerateArraysOfOtherSupplementalItems:^(NSString *kind, NSArray *obj, BOOL *stop) {
		NSUInteger index = 0;

		for (YoGridLayoutSupplementalItemInfo *item in obj) {
			// ignore headers if there are no items and the header isn't a global header
			if (!numberOfItems || !item.height || item.hidden)
				continue;

			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index++ inSection:sectionIndex];
			YoCollectionViewGridLayoutAttributes *itemAttribute = [attributeClass layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
			itemAttribute.frame = item.frame;
			itemAttribute.zIndex = item.zIndex;
			itemAttribute.backgroundColor = item.backgroundColor ? : section.backgroundColor;
			itemAttribute.selectedBackgroundColor = item.selectedBackgroundColor;
			itemAttribute.padding = item.padding;
			itemAttribute.hidden = NO;
			[newAttributes addObject:itemAttribute];

			YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:kind];
			_indexPathKindToSupplementaryAttributes[indexPathKind] = itemAttribute;
		}
	}];

	[footers enumerateObjectsUsingBlock:^(YoGridLayoutSupplementalItemInfo *footer, NSUInteger footerIndex, BOOL *stop) {
        // ignore the footer if there are no items or the footer has no height
        if (!numberOfItems || !footer.height || footer.hidden)
            return;

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:footerIndex inSection:sectionIndex];
        YoCollectionViewGridLayoutAttributes *footerAttribute = [attributeClass layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPath];
		footerAttribute.frame = footer.frame;
		footerAttribute.zIndex = footer.zIndex;
        footerAttribute.backgroundColor = footer.backgroundColor ? : section.backgroundColor;
        footerAttribute.selectedBackgroundColor = footer.selectedBackgroundColor;
        footerAttribute.padding = footer.padding;
        footerAttribute.hidden = NO;
        [newAttributes addObject:footerAttribute];

        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:UICollectionElementKindSectionFooter];
        _indexPathKindToSupplementaryAttributes[indexPathKind] = footerAttribute;
    }];

    NSUInteger numberOfSections = [_layoutInfo.sections count];

    // Add the section separator below this section provided it's not the last section (or if the section explicitly says to)
    if (sectionSeparatorColor && _totalNumberOfItems && (sectionIndex + 1 < numberOfSections || section.showsSectionSeparatorWhenLastSection)) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:sectionIndex];
        YoCollectionViewGridLayoutAttributes *separatorAttributes = [attributeClass layoutAttributesForDecorationViewOfKind:YoGridLayoutSectionSeparatorKind withIndexPath:indexPath];
        separatorAttributes.frame = CGRectMake(section.sectionSeparatorInsets.left, CGRectGetMaxY(section.frame), CGRectGetWidth(sectionFrame) - section.sectionSeparatorInsets.left - section.sectionSeparatorInsets.right, hairline);
        separatorAttributes.backgroundColor = sectionSeparatorColor;
		separatorAttributes.zIndex = YoGridLayoutZIndexSeparator;
        [newAttributes addObject:separatorAttributes];

        YoIndexPathKind *indexPathKind = [[YoIndexPathKind alloc] initWithIndexPath:indexPath kind:YoGridLayoutSectionSeparatorKind];
        _indexPathKindToDecorationAttributes[indexPathKind] = separatorAttributes;
	}
	
	[newAttributes sortWithOptions:NSSortConcurrent|NSSortStable usingComparator:^(YoCollectionViewGridLayoutAttributes *obj1, YoCollectionViewGridLayoutAttributes *obj2) {
		CGRect frame1 = obj1.frame, frame2 = obj2.frame;
		
		CGFloat max1 = CGRectGetMaxY(frame1), max2 = CGRectGetMaxY(frame2);
		
		if (max1 > max2) {
			return NSOrderedDescending;
		} else if (max1 < max2) {
			return NSOrderedAscending;
		}
		
		NSInteger z1 = obj1.zIndex;
		NSInteger z2 = obj2.zIndex;
		
		if (z1 > z2) {
			return NSOrderedAscending;
		} else if (z1 < z2) {
			return NSOrderedAscending;
		}
		
		CGFloat min1 = CGRectGetMinY(frame1), min2 = CGRectGetMinY(frame2);
		
		if (min1 > max2) {
			return NSOrderedAscending;
		} else if (min1 < min2)  {
			return NSOrderedDescending;
		}
		
		return NSOrderedSame;
	}];

	[_layoutAttributes addObjectsFromArray:newAttributes];
}

- (CGFloat)heightOfAttributes:(NSArray *)attributes
{
    if (![attributes count])
        return 0;

    CGFloat minY = CGFLOAT_MAX;
    CGFloat maxY = CGFLOAT_MIN;

    for (YoCollectionViewGridLayoutAttributes *attr in attributes) {
        minY = MIN(minY, CGRectGetMinY(attr.frame));
        maxY = MAX(maxY, CGRectGetMaxY(attr.frame));
    }

    return maxY - minY;
}

- (void)buildLayout
{
    if (_flags.layoutMetricsAreValid)
        return;

    if (_preparingLayout)
        return;

    _preparingLayout = YES;

    [self updateFlagsFromCollectionView];

    if (!_flags.layoutDataIsValid) {
        [self createLayoutInfoFromDataSource];
        _flags.layoutDataIsValid = YES;
    }

    UICollectionView *collectionView = self.collectionView;
    UIEdgeInsets contentInset = collectionView.contentInset;

	CGSize size = UIEdgeInsetsInsetRect(collectionView.bounds, contentInset).size;

	_oldLayoutSize = _layoutSize;
    _layoutSize = CGSizeZero;
	_layoutInfo.size = size;
    _layoutInfo.contentOffsetY = collectionView.contentOffset.y + contentInset.top;

	CGPoint origin = CGPointZero;

    [self.layoutAttributes removeAllObjects];
    [self.pinnableAttributes removeAllObjects];
    self.totalNumberOfItems = 0;

    YoDataSource *dataSource = (YoDataSource *)collectionView.dataSource;
    if (![dataSource isKindOfClass:[YoDataSource class]])
        dataSource = nil;

    NSInteger numberOfSections = [collectionView numberOfSections];

    __block BOOL shouldInvalidate = NO;

    CGFloat globalNonPinningHeight = 0;
    YoGridLayoutSectionInfo *globalSection = [self sectionInfoForSectionAtIndex:YoGlobalSection];
    if (globalSection) {
		[globalSection computeLayoutForSection:YoGlobalSection origin:origin measureItem:NULL measureSupplementaryItem:^(NSString *kind, NSIndexPath *indexPath, CGRect frame) {
			shouldInvalidate |= YES;
			return [self measureSupplementalItemOfKind:kind atIndexPath:indexPath];
		}];
		[self addLayoutAttributesForSection:globalSection atIndex:YoGlobalSection dataSource:dataSource];
        globalNonPinningHeight = [self heightOfAttributes:globalSection.nonPinnableHeaderAttributes];
    }

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex) {
        YoCollectionViewGridLayoutAttributes *attributes = [_layoutAttributes lastObject];
		if (attributes) {
			origin.y = CGRectGetMaxY(attributes.frame);
		}
        YoGridLayoutSectionInfo *section = [self sectionInfoForSectionAtIndex:sectionIndex];
		[section computeLayoutForSection:sectionIndex origin:origin measureItem:^(NSIndexPath *indexPath, CGRect frame) {
			return [dataSource collectionView:collectionView sizeFittingSize:frame.size forItemAtIndexPath:indexPath];
		} measureSupplementaryItem:^(NSString *kind, NSIndexPath *indexPath, CGRect frame) {
			shouldInvalidate |= YES;
			return [self measureSupplementalItemOfKind:kind atIndexPath:indexPath];
		}];

		[self addLayoutAttributesForSection:section atIndex:sectionIndex dataSource:dataSource];
    }

	YoCollectionViewGridLayoutAttributes *attributes = [_layoutAttributes lastObject];
	if (attributes) {
		size.height = CGRectGetMaxY(attributes.frame);
	} else {
		size.height = origin.y;
	}

	if (_layoutInfo.contentOffsetY >= globalNonPinningHeight && size.height - globalNonPinningHeight < size.height) {
		size.height += globalNonPinningHeight;
    }

	_layoutSize = size;

    [self filterSpecialAttributes];

    _flags.layoutMetricsAreValid = YES;
    _preparingLayout = NO;

    // If the headers change, we need to invalidate…
    if (shouldInvalidate)
        [self invalidateLayout];
}

- (void)resetPinnableAttributes:(NSArray *)pinnableAttributes
{
    for (YoCollectionViewGridLayoutAttributes *attributes in pinnableAttributes) {
        attributes.pinnedHeader = NO;
        CGRect frame = attributes.frame;
        frame.origin.y = attributes.unpinnedY;
        attributes.frame = frame;
    }
}

- (CGFloat)applyBottomPinningToAttributes:(NSArray *)attributes maxY:(CGFloat)maxY
{
    for (YoCollectionViewGridLayoutAttributes *attr in [attributes reverseObjectEnumerator]) {
        CGRect frame = attr.frame;
        if (CGRectGetMaxY(frame) < maxY) {
            frame.origin.y = maxY - CGRectGetHeight(frame);
            maxY = frame.origin.y;
        }
		attr.zIndex = YoGridLayoutZIndexPinned;
        attr.frame = frame;
    }

    return maxY;
}

// pin the attributes starting at minY as long a they don't cross maxY and return the new minY
- (CGFloat)applyTopPinningToAttributes:(NSArray *)attributes minY:(CGFloat)minY
{
    for (YoCollectionViewGridLayoutAttributes *attr in attributes) {
        CGRect  attrFrame = attr.frame;
        if (attrFrame.origin.y  < minY) {
            attrFrame.origin.y = minY;
            minY = CGRectGetMaxY(attrFrame);    // we have a new pinning offset
        }
        attr.frame = attrFrame;
    }
    return minY;
}

- (void)finalizePinnedAttributes:(NSArray *)attributes zIndex:(NSInteger)zIndex
{
    [attributes enumerateObjectsUsingBlock:^(YoCollectionViewGridLayoutAttributes *attr, NSUInteger attrIndex, BOOL *stop) {
        CGRect frame = attr.frame;
        attr.pinnedHeader = frame.origin.y != attr.unpinnedY;
        NSInteger depth = 1 + attrIndex;
        attr.zIndex = zIndex - depth;
    }];
}

- (YoGridLayoutSectionInfo *)firstSectionOverlappingYOffset:(CGFloat)yOffset
{
    __block YoGridLayoutSectionInfo *result = nil;

    [_layoutInfo.sections enumerateKeysAndObjectsUsingBlock:^(NSNumber *sectionIndex, YoGridLayoutSectionInfo *sectionInfo, BOOL *stop) {
        if (YoGlobalSection == [sectionIndex unsignedIntegerValue])
            return;

        CGRect frame = sectionInfo.frame;
        if (CGRectGetMinY(frame) <= yOffset && yOffset <= CGRectGetMaxY(frame)) {
            result = sectionInfo;
            *stop = YES;
        }
    }];

    return result;
}

- (void)filterSpecialAttributes
{
    UICollectionView *collectionView = self.collectionView;
    NSInteger numSections = [collectionView numberOfSections];

    if (numSections <= 0 || numSections == NSNotFound)  // bail if we have no sections
        return;

    CGPoint contentOffset;

    if (_flags.useCollectionViewContentOffset)
        contentOffset = collectionView.contentOffset;
    else
        contentOffset = [self targetContentOffsetForProposedContentOffset:collectionView.contentOffset];

    CGFloat pinnableY = contentOffset.y + collectionView.contentInset.top;
    CGFloat nonPinnableY = pinnableY;

    [self resetPinnableAttributes:self.pinnableAttributes];

    // Pin the headers as appropriate
    YoGridLayoutSectionInfo *section = [self sectionInfoForSectionAtIndex:YoGlobalSection];
    if (section.pinnableHeaderAttributes) {
        pinnableY = [self applyTopPinningToAttributes:section.pinnableHeaderAttributes minY:pinnableY];
		[self finalizePinnedAttributes:section.pinnableHeaderAttributes zIndex:YoGridLayoutZIndexPinned];
    }

    if (section.nonPinnableHeaderAttributes && [section.nonPinnableHeaderAttributes count]) {
        [self resetPinnableAttributes:section.nonPinnableHeaderAttributes];
        nonPinnableY = [self applyBottomPinningToAttributes:section.nonPinnableHeaderAttributes maxY:nonPinnableY];
		[self finalizePinnedAttributes:section.nonPinnableHeaderAttributes zIndex:YoGridLayoutZIndexPinned];
    }

    if (section.backgroundAttribute) {
        CGRect frame = section.backgroundAttribute.frame;
        frame.origin.y = MIN(nonPinnableY, collectionView.bounds.origin.y);
        CGFloat bottomY = MAX(CGRectGetMaxY([[section.pinnableHeaderAttributes lastObject] frame]), CGRectGetMaxY([[section.nonPinnableHeaderAttributes lastObject] frame]));
        frame.size.height =  bottomY - frame.origin.y;
        section.backgroundAttribute.frame = frame;
    }

    YoGridLayoutSectionInfo *overlappingSection = [self firstSectionOverlappingYOffset:pinnableY];
    if (overlappingSection) {
        [self applyTopPinningToAttributes:overlappingSection.pinnableHeaderAttributes minY:pinnableY];
		[self finalizePinnedAttributes:overlappingSection.pinnableHeaderAttributes zIndex:YoGridLayoutZIndexPinnedOverlap];
    };
}

- (YoCollectionViewGridLayoutAttributes *)initialLayoutAttributesForAttributes:(YoCollectionViewGridLayoutAttributes *)attributes
{
    attributes.frame = CGRectOffset(attributes.frame, -self.contentOffsetDelta.x, -self.contentOffsetDelta.y);;
    return attributes;
}

- (YoCollectionViewGridLayoutAttributes *)finalLayoutAttributesForAttributes:(YoCollectionViewGridLayoutAttributes *)attributes
{
    CGFloat deltaX = + self.contentOffsetDelta.x;
    CGFloat deltaY = + self.contentOffsetDelta.y;
    CGRect frame = attributes.frame;
    if (attributes.pinnedHeader) {
        CGFloat newY = MAX(attributes.unpinnedY, CGRectGetMinY(frame) + deltaY);
        frame.origin.y = newY;
        frame.origin.x += deltaX;
    }
    else
        frame = CGRectOffset(frame, deltaX, deltaY);

    attributes.frame = frame;
    return attributes;
}

- (YoCollectionViewGridLayoutAttributes *)initialLayoutAttributesForAttributes:(YoCollectionViewGridLayoutAttributes *)attributes slidingInFromDirection:(YoDataSourceSectionOperationDirection)direction
{
    CGRect frame = attributes.frame;
    CGRect cvBounds = self.collectionView.bounds;

    if (direction == YoDataSourceSectionOperationDirectionLeft)
        frame.origin.x -= cvBounds.size.width;
    else
        frame.origin.x += cvBounds.size.width;

    attributes.frame = frame;
    return [self initialLayoutAttributesForAttributes:attributes];
}

- (YoCollectionViewGridLayoutAttributes *)finalLayoutAttributesForAttributes:(YoCollectionViewGridLayoutAttributes *)attributes slidingAwayFromDirection:(YoDataSourceSectionOperationDirection)direction
{
    CGRect frame = attributes.frame;
    CGRect cvBounds = self.collectionView.bounds;
    if (direction == YoDataSourceSectionOperationDirectionLeft)
        frame.origin.x += cvBounds.size.width;
    else
        frame.origin.x -= cvBounds.size.width;

    attributes.alpha = 0;
    attributes.frame = CGRectOffset(frame, self.contentOffsetDelta.x, self.contentOffsetDelta.y);
    return attributes;
}

#pragma mark - YoDataSource delegate methods

- (void)dataSource:(__unused YoDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger sectionIndex, BOOL *stop) {
        _updateSectionDirections[@(sectionIndex)] = @(direction);
    }];
}

- (void)dataSource:(__unused YoDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(YoDataSourceSectionOperationDirection)direction
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger sectionIndex, BOOL *stop) {
        _updateSectionDirections[@(sectionIndex)] = @(direction);
    }];
}

- (void)dataSource:(__unused YoDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(YoDataSourceSectionOperationDirection)direction
{
    _updateSectionDirections[@(section)] = @(direction);
    _updateSectionDirections[@(newSection)] = @(direction);
}

@end
