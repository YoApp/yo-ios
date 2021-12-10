//
//  NotificationViewController.m
//  Notification Content Extension
//
//  Created by mac on 10/6/16.
//
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UIWebView *webView;

@end

@implementation NotificationViewController

- (void)didReceiveNotification:(UNNotification *)notification {
    NSString *str = [notification request].content.userInfo[@"attachment-url"];
    NSURLRequest *r = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    [self.webView loadRequest:r];
}

@end
