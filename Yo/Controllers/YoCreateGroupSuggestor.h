//
//  YoCreateGroupSuggestor.h
//  Yo
//
//  Created by Peter Reveles on 7/23/15.
//
//

#import <Foundation/Foundation.h>
@class YoCreateGroupSuggestor;

@protocol YoCreateGroupSuggestorDelegate <NSObject>

- (void)suggestor:(YoCreateGroupSuggestor *)suggestor suggestsUserCreateGroupWithUsers:(NSSet *)users;

@end

@interface YoCreateGroupSuggestor : NSObject

@property (nonatomic, weak) id <YoCreateGroupSuggestorDelegate> delegate;

@property (nonatomic, assign) NSTimeInterval timeProximityForGroupSuggestion;

@property (nonatomic, assign) BOOL canRepeatSuggestions;

- (void)didYoUser:(YoUser *)user;

@end
