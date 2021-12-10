//
//  YoObjectProvider.h
//  Yo
//
//  Created by Peter Reveles on 8/4/15.
//
//

#import <Foundation/Foundation.h>

@interface YoObjectProvider : NSObject

- (instancetype)initWithObjects:(NSArray *)objects;

@property (nonatomic, readonly) NSArray *objects;

- (id)objectAtIndex:(NSInteger)index;

- (void)removeObjectAtIndex:(NSInteger)index;

@end
