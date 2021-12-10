/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoCollectionViewGridLayout_Internal.h"

@implementation YoGridLayoutSupplementalItemInfo
@end

@implementation YoGridLayoutItemInfo
@end

@implementation YoGridLayoutSectionInfo

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _items = [NSMutableArray array];
	_supplementalItemArraysByKind = [NSMutableDictionary dictionary];
    _pinnableHeaderAttributes = [NSMutableArray array];

    return self;
}

- (NSMutableArray *)nonPinnableHeaderAttributes
{
    // Lazy initialise this, because it's only used for the global section
    if (_nonPinnableHeaderAttributes)
        return _nonPinnableHeaderAttributes;
    _nonPinnableHeaderAttributes = [NSMutableArray array];
    return _nonPinnableHeaderAttributes;
}

- (YoGridLayoutSupplementalItemInfo *)addSupplementalItemAsPlaceholder
{
    YoGridLayoutSupplementalItemInfo *supplementalInfo = [[YoGridLayoutSupplementalItemInfo alloc] init];
    _placeholder = supplementalInfo;
    return supplementalInfo;
}

- (YoGridLayoutSupplementalItemInfo *)addSupplementalItemOfKind:(NSString *)supplementalKind
{
	YoGridLayoutSupplementalItemInfo *supplementalInfo = [[YoGridLayoutSupplementalItemInfo alloc] init];
	NSMutableArray *items = _supplementalItemArraysByKind[supplementalKind];
	if (!items) {
		items = [NSMutableArray array];
		_supplementalItemArraysByKind[supplementalKind] = items;
	}
	[items addObject:supplementalInfo];
	return supplementalInfo;
}

- (void)enumerateArraysOfOtherSupplementalItems:(void(^)(NSString *kind, NSArray *items, BOOL *stop))block
{
	NSParameterAssert(block != nil);
	[_supplementalItemArraysByKind enumerateKeysAndObjectsUsingBlock:^(NSString *kind, NSArray *items, BOOL *stahp) {
		if ([kind isEqual:UICollectionElementKindSectionHeader] || [kind isEqual:UICollectionElementKindSectionFooter]) return;
		block(kind, items, stahp);
	}];
}

- (YoGridLayoutItemInfo *)addItem
{
    YoGridLayoutItemInfo *itemInfo = [[YoGridLayoutItemInfo alloc] init];
    [self.items addObject:itemInfo];
    return itemInfo;
}

- (CGFloat)columnWidth
{
	CGFloat width = self.layoutInfo.size.width;
    UIEdgeInsets margins = self.insets;
    CGFloat columnWidth = (width - margins.left - margins.right);
    return columnWidth;
}

/// Layout all the items in this section and return the total height of the section
- (void)computeLayoutForSection:(NSUInteger)sectionIndex origin:(CGPoint)start measureItem:(CGSize(^)(NSIndexPath *, CGRect))measureItemBlock measureSupplementaryItem:(CGSize(^)(NSString *, NSIndexPath *, CGRect))measureSupplementaryItemBlock
{
	NSIndexPath *(^indexPath)(NSUInteger) = ^(NSUInteger itemIndex){
		if (sectionIndex == YoGlobalSection) {
			return [NSIndexPath indexPathWithIndex:itemIndex];
		}
		return [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
	};
	
	const CGSize size = self.layoutInfo.size;
	const CGFloat availableHeight = size.height - start.y;
	const CGSize sizeForMeasuring = { size.width, UILayoutFittingExpandedSize.height };
	const UIEdgeInsets margins = self.insets;
	const NSUInteger numberOfItems = self.items.count;
	
	__block CGPoint origin = start;
	
	NSArray *headers = _supplementalItemArraysByKind[UICollectionElementKindSectionHeader],
			*footers = _supplementalItemArraysByKind[UICollectionElementKindSectionFooter];
	
	// First lay out headers
	[headers enumerateObjectsUsingBlock:^(YoGridLayoutSupplementalItemInfo *headerInfo, NSUInteger headerIndex, BOOL *stop) {
		// skip headers if there are no items and the header isn't a global header
		if (!numberOfItems && !headerInfo.visibleWhileShowingPlaceholder) { return; }
		
		// skip headers that are hidden
		if (headerInfo.hidden) { return; }
		
		// This header needs to be measured!
		if (!headerInfo.height && measureSupplementaryItemBlock) {
			headerInfo.frame = (CGRect){ origin, sizeForMeasuring };
			headerInfo.height = measureSupplementaryItemBlock(UICollectionElementKindSectionHeader, indexPath(headerIndex), headerInfo.frame).height;
		}
		
		headerInfo.frame = (CGRect){ origin, { size.width, headerInfo.height }};
		origin.y += headerInfo.height;
	}];
	
	YoGridLayoutSupplementalItemInfo *placeholder = self.placeholder;
	if (placeholder) {
		// Height of the placeholder is equal to the height of the collection view minus the height of the headers
		CGFloat height = availableHeight - (origin.y - start.y);
		placeholder.height = height;
		placeholder.frame = (CGRect){ origin, { size.width, height }};
		origin.y += height;
	}

	NSAssert(!placeholder || !numberOfItems, @"Can't have both a placeholder and items");

	// Lay out items, footers, and misc. items only if there actually ARE items.
	if (numberOfItems) {
		CGFloat contentBeginY = origin.y + margins.top;
		__block CGFloat backgroundEndY = contentBeginY;

		[_supplementalItemArraysByKind enumerateKeysAndObjectsUsingBlock:^(NSString *kind, NSArray *obj, BOOL *stopA) {
			if ([kind isEqual:UICollectionElementKindSectionHeader] || [kind isEqual:UICollectionElementKindSectionFooter]) { return; }

			[obj enumerateObjectsUsingBlock:^(YoGridLayoutSupplementalItemInfo *item, NSUInteger itemIndex, BOOL *stopb) {
				// skip hidden supplementary items
				if (item.hidden)
					return;

				// This header needs to be measured!
				if (!item.height && measureSupplementaryItemBlock) {
					item.frame = (CGRect){ origin, sizeForMeasuring };
					item.height = measureSupplementaryItemBlock(kind, indexPath(itemIndex), item.frame).height;
				}

				item.frame = (CGRect){ origin, { size.width, item.height }};
				origin.y += item.height;

				backgroundEndY = MAX(backgroundEndY, origin.y);
			}];

			origin.y = contentBeginY;
		}];

		__block CGPoint itemOrigin = CGPointMake( start.x + margins.left, contentBeginY );
		const CGFloat itemWidth = self.columnWidth;

		[self.items enumerateObjectsUsingBlock:^(YoGridLayoutItemInfo *item, NSUInteger itemIndex, BOOL *stop) {
			CGRect itemFrame = (CGRect){ itemOrigin, { itemWidth, CGRectGetHeight(item.frame) }};
			if (itemFrame.size.height == YoRowHeightRemainder) {
				itemFrame.size.height = size.height - itemFrame.origin.y;
			}

			if (item.needSizeUpdate && measureItemBlock) {
				item.needSizeUpdate = NO;
				item.frame = itemFrame;
				itemFrame.size.height = measureItemBlock(indexPath(itemIndex), itemFrame).height;
				item.frame = itemFrame;
			} else {
				item.frame = itemFrame;
			}

			itemOrigin.y += itemFrame.size.height;
		}];

		origin.y = MAX(backgroundEndY, itemOrigin.y) + margins.bottom;

		// lay out all footers
		for (YoGridLayoutSupplementalItemInfo *footerInfo in footers) {
			// skip hidden footers
			if (footerInfo.hidden)
				continue;
			// When showing the placeholder, we don't show footers
			CGFloat height = footerInfo.height;
			footerInfo.frame = (CGRect){ origin, { size.width, height }};
			origin.y += height;
		}

	}

	self.frame = (CGRect){ start, { size.width, origin.y - start.y }};
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p %@>", NSStringFromClass(self.class), (__bridge void *)self, NSStringFromCGRect(_frame)];
}

#if DEBUG
- (NSString *)recursiveDescription __unused
{
    NSMutableString *result = [NSMutableString string];
    [result appendString:[self description]];

	NSArray *headers = _supplementalItemArraysByKind[UICollectionElementKindSectionHeader];
	NSArray *footers = _supplementalItemArraysByKind[UICollectionElementKindSectionFooter];
	NSUInteger others = _supplementalItemArraysByKind.count - (headers ? 1 : 0) - (footers ? 1 : 0);

	if (headers.count) {
        [result appendString:@"\n    headers = @[\n"];

		for (YoGridLayoutSupplementalItemInfo *header in headers) {
            [result appendFormat:@"        %@\n", header];
        }

		[result appendString:@"    ]"];
    }

    if (_placeholder) {
        [result appendFormat:@"\n    placeholder = %@", _placeholder];
    }

	if (_items.count) {
		[result appendString:@"\n    items = @[\n"];

		for (YoGridLayoutItemInfo *items in _items) {
			[result appendFormat:@"        %@\n", items];
		}

        [result appendString:@"    ]"];
	}

	if (footers.count) {
		[result appendString:@"\n    footers = @[\n"];
		for (YoGridLayoutSupplementalItemInfo *footer in footers) {
			[result appendFormat:@"        %@\n", footer];
		}
		[result appendString:@"     ]"];
	}

	if (others) {
		[result appendString:@"\n    others = @[\n"];

		[self enumerateArraysOfOtherSupplementalItems:^(NSString *kind, NSArray *items, BOOL *stahp) {
			[result appendFormat:@"        %@ = @[\n", kind];

			for (YoGridLayoutSupplementalItemInfo *item in items) {
				[result appendFormat:@"            %@\n", item];
			}

			[result appendString:@"         ]\n"];
		}];

		[result appendString:@"     ]"];
	}

    return result;
}
#endif

@end



@implementation YoGridLayoutInfo

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;
    _sections = [NSMutableDictionary dictionary];
    return self;
}

- (YoGridLayoutSectionInfo *)addSectionWithIndex:(NSInteger)sectionIndex
{
    YoGridLayoutSectionInfo *section = [[YoGridLayoutSectionInfo alloc] init];
    section.layoutInfo = self;
    self.sections[@(sectionIndex)] = section;
    return section;
}

- (void)invalidate
{
    [self.sections removeAllObjects];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p size=%@ contentOffsetY=%g>", NSStringFromClass([self class]), (__bridge void *)self, NSStringFromCGSize(_size), _contentOffsetY];
}

#if DEBUG
- (NSString *)recursiveDescription __unused
{
    NSMutableString *result = [NSMutableString string];
    [result appendString:[self description]];

    if ([_sections count]) {
        [result appendString:@"\n    sections = @[\n"];

        NSArray *descriptions = [_sections valueForKey:@"recursiveDescription"];
        [result appendFormat:@"        %@\n", [descriptions componentsJoinedByString:@"\n        "]];
        [result appendString:@"    ]"];
    }

    return result;
}
#endif

@end

@implementation YoIndexPathKind

- (instancetype)initWithIndexPath:(NSIndexPath *)indexPath kind:(NSString *)kind
{
	self = [super init];
	if (!self) return nil;
	
	_indexPath = [indexPath copy];
	_kind = [kind copy];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (NSUInteger)hash
{
	NSUInteger prime = 31;
	NSUInteger result = 1;
	
	result = prime * result + [_indexPath hash];
	result = prime * result + [_kind hash];
	return result;
}

- (BOOL)isEqual:(id)object
{
	if (self == object)
		return YES;
	
	if (![object isKindOfClass:YoIndexPathKind.class])
		return NO;
	
    YoIndexPathKind *other = object;
	
	if (_indexPath == other->_indexPath && _kind == other->_kind)
		return YES;
	
	if (!_indexPath || ![_indexPath isEqual:other->_indexPath])
		return NO;
	
	return _kind && [_kind isEqualToString:other->_kind];
}

@end
