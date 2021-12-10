//
//  YoGroupMemberDisplayView.h
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import <UIKit/UIKit.h>
@class YoContact;
@class YoGroupMemberDisplayView;

@protocol YoGroupMemberDisplayViewDelegate <NSObject>

- (void)yoGroupMemberDisplayView:(YoGroupMemberDisplayView *)view
                 didSelectMember:(YoContact *)member;

@end

@interface YoGroupMemberDisplayView : UIView

@property (readonly, nonatomic) NSOrderedSet *groupMembers;
@property (weak, nonatomic) id <YoGroupMemberDisplayViewDelegate> delegate;

- (void)addMember:(YoContact *)member;
- (void)removeMember:(YoContact *)member;

@end
