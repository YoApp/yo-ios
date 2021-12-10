//
//  YoContactBookConstants.h
//  Yo
//
//  Created by Peter Reveles on 12/9/14.
//
//

@protocol YoContactBookDelegate <NSObject>

- (void)yoContactBookDidCloseWithNumberOfFriendsInvited:(NSInteger)numberOfFriendsInvited friendsYod:(NSSet *)friendsYod;

@end
