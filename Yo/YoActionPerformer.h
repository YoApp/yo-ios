//
//  YoExectuableAction.h
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import <Foundation/Foundation.h>

#define YoActionOpenYoStore @"YoActionOpenYoStore"
#define YoActionAddContact @"YoActionAddContact"

@interface YoActionPerformer : NSObject

+ (void)performAction:(NSString *)action withParameters:(id)params;

@end
