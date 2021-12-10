//
//  YoAlertAction.h
//  Yo
//
//  Created by Peter Reveles on 5/26/15.
//
//

#import <Foundation/Foundation.h>

@interface YoAlertAction : NSObject

@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) void (^tapBlock)();

- (instancetype)initWithTitle:(NSString *)title tapBlock:(void (^)())block;

@end
