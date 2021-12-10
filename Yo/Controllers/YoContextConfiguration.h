//
//  YoConfigurationManager.h
//  Yo
//
//  Created by Peter Reveles on 7/9/15.
//
//

#import <Foundation/Foundation.h>

@interface YoContextConfiguration : NSObject <NSCoding>

+ (instancetype)sharedInstance;

- (void)load;
- (void)updateWithCompletionHandler:(void (^)(BOOL didUpdate))handler;

@property (readonly, nonatomic) NSArray *contextIDs;
@property (readonly, nonatomic) NSString *defaultContextID;

@end
