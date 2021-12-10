//
//  YoContextFactory.h
//  Yo
//
//  Created by Peter Reveles on 7/9/15.
//
//

#import <Foundation/Foundation.h>

@interface YoContextFactory : NSObject

+ (YoContextObject *)newContextOfIdentifier:(NSString *)contextID;

@end
