//
//  YOUDID.m
//  Yo
//
//  Created by Or Arbel on 3/29/14.
//
//

#import "YOUDID.h"

@implementation YOUDID

+ (NSString *)value {
#ifdef BRAND
    return MakeString(@"#ifdef BRAND-%@", [super value]);
#else
    return [super value];
#endif
}

@end
