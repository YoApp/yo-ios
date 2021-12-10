//
//  YoViewWithTitleAndAction.h
//  Yo
//
//  Created by Peter Reveles on 6/4/15.
//
//

#import <UIKit/UIKit.h>

#define YoInstructionImageContacts @"enable_contacts_instruction"
#define YoInstructionImagePushNotifications @"enable_push_notification_instruction"
#define YoInstructionImageCamera @"enable_camera_instruction"
#define YoInstructionImageLocation @"enable_location_instruction"

@interface YoPermissionsInstructionView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *settingsAppIconImageView;
@property (weak, nonatomic) IBOutlet YoLabel *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *instructionImageView;
@property (weak, nonatomic) IBOutlet YoButton *actionButton;

- (void)updateHeightToFitSubviews;

@end
