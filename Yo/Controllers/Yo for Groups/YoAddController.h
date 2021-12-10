//
//  YoAddMembersController.h
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import "YoContactsController.h"
#import "YoGroup.h"

typedef enum {
    YoAddControllerAddToRecentsList,
    YoAddControllerCreateGroup,
    YoAddControllerAddToGroup
} YoAddControllerMode;

@interface YoAddController : YoContactsController

@property (nonatomic, strong) YoGroup *group;

@property (nonatomic, assign) YoAddControllerMode mode;

@end
