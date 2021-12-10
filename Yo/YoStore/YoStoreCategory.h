//
//  YoStoreCategory.h
//  Yo
//
//  Created by Peter Reveles on 4/28/15.
//
//

#import <Foundation/Foundation.h>

/*
 -- SAMPLE PAYLOAD --
 "_id" = 551ee9123ae74089340126ae;
 category = Travel;
 created = 1428089106749094;
 rank = 10;
 region = World;
 updated = 1429489702192511;
*/

@interface YoStoreCategory : NSObject

- (instancetype)initWithCategoryData:(id)categoryData;

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *itemID;

@property (nonatomic, readonly) NSInteger rank;

@property (nonatomic, readonly) NSTimeInterval creationTime;

@property (nonatomic, readonly) NSTimeInterval lastUpdateTime;

@property (nonatomic, readonly) BOOL isFeatured;

#pragma mark - Utility

- (BOOL)isEqualToCategory:(YoStoreCategory *)otherCategory;

@end
