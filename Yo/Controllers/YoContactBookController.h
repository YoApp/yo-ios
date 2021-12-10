//
//  YoContactBookController.h
//  Yo
//
//  Created by Peter Reveles on 11/30/14.
//
//

#import "YOUsernamesPickerController.h"
#import "YoContactBookConstants.h"
@class YoContacts;

@interface YoContactBookController : YOUsernamesPickerController

- (instancetype)initWithContactsOnYo:(YoContacts *)contactsOnYo contactsNotOnYo:(YoContacts *)contactsNotOnYo;

- (instancetype)initWithShareText:(NSString *)text;

@property (nonatomic, weak) id <YoContactBookDelegate> delegate;

@property (nonatomic, strong) NSString *dissmissButtonTitle;

@end
