//
//  YoSearchDelegate.h
//  Yo
//
//  Created by Peter Reveles on 11/26/14.
//
//

#import <Foundation/Foundation.h>

@protocol YoSearchObjectDelegate <NSObject>
@optional
- (void)dataWasUpdated;

@end

@interface YoSearchObject : NSObject <UISearchBarDelegate>

- (instancetype)initWithData:(NSArray *)data;

// ** If YoDataSource is set as a search delegate, data will be updated accordingly. */
- (void)setData:(NSArray *)data;
- (void)clearFilteredData;

@property (nonatomic, readonly) NSArray *filteredData;
@property (nonatomic, readonly) NSArray *originalData;
@property (nonatomic, weak) id <YoSearchObjectDelegate> delegate;

@property (nonatomic, strong) NSString *propertyToFilterBy;

@end
