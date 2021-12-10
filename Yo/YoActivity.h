//
//  YoActivity.h
//  Yo
//
//  Created by Peter Reveles on 2/18/15.
//
//

#import <Foundation/Foundation.h>

@interface YoActivity : NSObject

- (instancetype)initWithName:(NSString *)name;

- (void)started;

- (void)ended;

- (NSTimeInterval) timeElapsed;

@property(nonatomic, readonly) NSString *name;

@property(nonatomic, readonly) NSDictionary *info;

@end
