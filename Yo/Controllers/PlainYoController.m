//
//  PlainYoController.m
//  Yo
//
//  Created by Or Arbel on 6/3/15.
//
//

#import "PlainYoController.h"
#import "NSDate_Extentions.h"
#import "YoInbox.h"
#import "YoLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface PlainYoController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewFixedHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelHeightRelativeToScrollViewHeightConstraint;
@end

@implementation PlainYoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fullNameLabel.text = self.yo.senderObject.displayName;
    [self.profileImageView setImageWithURL:self.yo.senderObject.photoURL];
    self.usernameLabel.text = [self.yo.creationDate agoString];
    
    self.label.text = self.yo.body;
    
    CGFloat padding = 10.0f;
    CGFloat width = CGRectGetWidth(self.contentView.frame) - (padding * 2);
    CGSize labelMinSize = [self.label sizeThatFits:CGSizeMake(width,
                                                              0.0f)];
    NS_DURING
    if (labelMinSize.height >= self.scrollViewFixedHeightConstraint.constant) {
        self.scrollViewFixedHeightConstraint.active = YES;
        self.labelHeightRelativeToScrollViewHeightConstraint.active = NO;
    }
    else {
        self.scrollViewFixedHeightConstraint.active = NO;
        self.labelHeightRelativeToScrollViewHeightConstraint.active = YES;
    }
    NS_HANDLER
    NS_ENDHANDLER
    
    if ([self.yo.body isEqualToString:self.yo.senderObject.displayName]) {
        self.label.hidden = YES;
        self.yoIcon.hidden = NO;
    }
    else {
        self.label.hidden = NO;
        self.yoIcon.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.yo) {
        [[YoUser me].yoInbox updateOrAddYo:self.yo withStatus:YoStatusRead];
    }
}

- (IBAction)leftButtonPressed:(UIButton *)sender {
    
    if (self.yo.leftDeepLink) {
        [self close];
        NSURL *url = [NSURL URLWithString:self.yo.leftDeepLink];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        return;
    }
    
    [self showActivityOnView:sender];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"reply_to"] = self.yo.yoID;
    
    if (self.isCustomReplies) {
        params[@"context"] = self.leftButtonTitle;
        [sender setTitle:MakeString(@"Sent %@", self.leftButtonTitle) forState:UIControlStateNormal];
    }
    else {
        [sender setTitle:@"Sent Yo" forState:UIControlStateNormal];
    }
    
    [sender.titleLabel removeFromSuperview];
    
    [[YoManager sharedInstance] yo:self.yo.senderUsername
                 contextParameters:params
                 completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                     if (result != YoResultSuccess) {
                         [sender setTitle:@"Failed" forState:UIControlStateNormal];
                     }
                     BOOL success = (result == YoResultSuccess);
                     NSDictionary *context = @{Yo_USERNAME_KEY:self.yo.senderUsername, @"success":@(success)};
                     [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished object:self userInfo:context];
                     [self removeActivityFromView:sender];
                     [sender addSubview:sender.titleLabel];
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         [self close];
                     });
                 }];
}

- (IBAction)rightButtonPressed:(UIButton *)sender {
    
    if (self.yo.rightDeepLink) {
        [self close];
        NSURL *url = [NSURL URLWithString:self.yo.rightDeepLink];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        return;
    }
    
    [self showActivityOnView:sender];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"reply_to"] = self.yo.yoID;
    
    if (self.isCustomReplies) {
        params[@"context"] = self.rightButtonTitle;
        [sender setTitle:MakeString(@"Sent %@", self.rightButtonTitle) forState:UIControlStateNormal];
        
        [[YoManager sharedInstance] yo:self.yo.senderUsername contextParameters:params completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
            if (result != YoResultSuccess) {
                [sender setTitle:@"Failed" forState:UIControlStateNormal];
            }
            BOOL success = (result==YoResultSuccess)?YES:NO;
            NSDictionary *context = @{Yo_USERNAME_KEY:self.yo.senderUsername, @"success":@(success), @"type": @"location", @"reply_to": self.yo.yoID};
            [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished object:self userInfo:context];
            [self removeActivityFromView:sender];
            [sender addSubview:sender.titleLabel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self close];
            });
        }];
        
    }
    else {
        [sender setTitle:@"Sent Yo 📍" forState:UIControlStateNormal];
        
        [[YoManager sharedInstance] yo:self.yo.senderUsername withCurrentLocation:YES completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
            if (result != YoResultSuccess) {
                [sender setTitle:@"Failed" forState:UIControlStateNormal];
            }
            BOOL success = (result==YoResultSuccess)?YES:NO;
            NSDictionary *context = @{Yo_USERNAME_KEY:self.yo.senderUsername, @"success":@(success), @"type": @"location", @"reply_to": self.yo.yoID};
            [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished object:self userInfo:context];
            [self removeActivityFromView:sender];
            [sender addSubview:sender.titleLabel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self close];
            });
        }];
    }
    
    [sender.titleLabel removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardStarted object:self userInfo:@{Yo_USERNAME_KEY:self.yo.senderUsername}];
}

@end
