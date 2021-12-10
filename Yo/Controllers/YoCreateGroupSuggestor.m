//
//  YoCreateGroupSuggestor.m
//  Yo
//
//  Created by Peter Reveles on 7/23/15.
//
//

#import "YoCreateGroupSuggestor.h"

@interface YoCreateGroupSuggestor ()
@property (nonatomic, strong) NSMutableSet *recentlyYodUserPool;
@property (nonatomic, strong) NSTimer *suggestionTimer;
@property (nonatomic, strong) NSMutableArray *suggestionsAlreadyMade;
@property (nonatomic, assign) NSUInteger minimumGroupSize;
@end

@implementation YoCreateGroupSuggestor

- (instancetype)init {
    self = [super init];
    if (self) {
        _recentlyYodUserPool = [[NSMutableSet alloc] init];
        _suggestionsAlreadyMade = [[NSMutableArray alloc] init];
        _timeProximityForGroupSuggestion = 4.0;
        _minimumGroupSize = 2;
    }
    return self;
}

- (void)didYoUser:(YoUser *)user {
    if (user == nil) {
        return;
    }
    [_recentlyYodUserPool addObject:user];
    [self resetSuggestionTimer];
}

- (void)resetSuggestionTimer {
    [_suggestionTimer invalidate];
    _suggestionTimer = [NSTimer scheduledTimerWithTimeInterval:_timeProximityForGroupSuggestion
                                                        target:self
                                                      selector:@selector(suggestionTimerDidExpire)
                                                      userInfo:nil
                                                       repeats:NO];
}

- (void)suggestionTimerDidExpire {
    if (_recentlyYodUserPool.count >= _minimumGroupSize &&
        self.delegate) {
        if (_canRepeatSuggestions ||
            [_suggestionsAlreadyMade containsObject:[_recentlyYodUserPool allObjects]] == NO) {
            [self.delegate suggestor:self suggestsUserCreateGroupWithUsers:_recentlyYodUserPool];
            [_suggestionsAlreadyMade addObject:[_recentlyYodUserPool allObjects]];
        }
    }
    _suggestionTimer = nil;
    [_recentlyYodUserPool removeAllObjects];
}

@end
