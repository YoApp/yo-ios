//
//  YoBanner.h
//  Yo
//
//  Created by Peter Reveles on 7/8/15.
//
//

#import <Foundation/Foundation.h>

@interface YoBanner : NSObject <NSCoding>

@property (readonly, nonatomic) NSString *link;
@property (readonly, nonatomic) NSString *message;
@property (readonly, nonatomic) NSString *ID;

/**
 If YES user should be able to dismiss the banner.
 **/
@property (readonly, nonatomic) BOOL canDismiss;

/**
 Defines how long this banner should apear for.
 **/
@property (readonly, nonatomic) NSTimeInterval *lifeSpan;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly, nonatomic) NSDictionary *dictionaryRepresentation;

- (BOOL)isEqualToBanner:(YoBanner *)banner;

+ (NSDictionary *)serverToClientKeyMapping;
+ (NSDictionary *)clientToServerKeyMapping;

@end
