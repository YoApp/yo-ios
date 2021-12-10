//
//  YoModelObjectCollectionViewCell.h
//  Yo
//
//  Created by Peter Reveles on 6/16/15.
//
//

#import "YoCollectionViewCell.h"

/**
 Intended for subclassing
 */
@interface YoModelObjectCollectionViewCell : YoCollectionViewCell

@property (strong, nonatomic) YoModelObject *object;

/**
 Called when object changes and when it's set. Use this to update UI.
 */
- (void)objectDidChange;

@end
