//
//  YoNotificationObjectProtocol.h
//  Yo
//
//  Created by Peter Reveles on 3/12/15.
//
//

#ifndef Yo_YoNotificationObjectProtocol_h
#define Yo_YoNotificationObjectProtocol_h

@protocol YoNotificationObjectProtocal <NSObject>

@optional
- (NSString *)presentationSound;
- (NSString *)dismissalSound;

@end

#endif
