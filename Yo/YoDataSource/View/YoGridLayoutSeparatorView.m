/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 */

#import "YoGridLayoutSeparatorView.h"
#import "YoCollectionViewGridLayoutAttributes.h"

@implementation YoGridLayoutSeparatorView

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
	if ([layoutAttributes isKindOfClass:YoCollectionViewGridLayoutAttributes.class]) {
		self.backgroundColor = ((YoCollectionViewGridLayoutAttributes *)layoutAttributes).backgroundColor;
	} else {
		self.backgroundColor = nil;
	}
}

@end
