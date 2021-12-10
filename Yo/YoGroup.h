//
//  YoGroup.h
//  Yo
//
//  Created by Or Arbel on 5/13/15.
//
//

#import "YoModelObject.h"

@interface YoGroup : YoModelObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *groupId;

@property (nonatomic, strong) NSMutableArray *members;
@property (nonatomic, strong) NSMutableArray *admins;

@property (assign, nonatomic) BOOL isMuted;

- (BOOL)amIAdmin;

@end
