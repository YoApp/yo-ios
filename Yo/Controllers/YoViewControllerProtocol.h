//
//  YoViewControllerProtocol.h
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#ifndef Yo_YoViewControllerProtocol_h
#define Yo_YoViewControllerProtocol_h

@protocol YoViewControllerProtocol <NSObject>

/**
 Override as needed. This method is used when deciding when to present notifications.
 Defaults to YES.
 */
- (BOOL)areNotificationAllowed;

@end

#endif
