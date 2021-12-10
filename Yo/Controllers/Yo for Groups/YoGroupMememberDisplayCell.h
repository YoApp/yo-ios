//
//  YoGroupMememberDisplayCollectionViewCell.h
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import <UIKit/UIKit.h>
@class YoContact;

@interface YoGroupMememberDisplayCell : UICollectionViewCell
- (void)displayContact:(YoContact *)contact;
@end
