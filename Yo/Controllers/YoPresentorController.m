//
//  YoPresentorController.m
//  Yo
//
//  Created by Or Arbel on 7/16/15.
//
//

#import "YoPresentorController.h"

@implementation YoPresentorController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftButton.titleLabel.font = MonsterratBold(19.0);
    self.leftButton.titleLabel.minimumScaleFactor = 0.1;
    self.leftButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    self.rightButton.titleLabel.font = MonsterratBold(19.0);
    self.rightButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.rightButton.titleLabel.minimumScaleFactor = 0.1;
    
    [self applyCustomActionsIfNeeded];
}

- (void)applyCustomActionsIfNeeded {
    NSRange range = [self.yo.category rangeOfString:@"."];
    BOOL categoryTextContainsPeriod = (range.location != NSNotFound);
    if (categoryTextContainsPeriod) {
        NS_DURING
        
        NSArray *components = [self.yo.category componentsSeparatedByString:@"."];
        self.leftButtonTitle = components[0];
        self.rightButtonTitle = components[1];
        
        [self.leftButton setTitle:self.leftButtonTitle forState:UIControlStateNormal];
        [self.rightButton setTitle:self.rightButtonTitle forState:UIControlStateNormal];
        
        self.isCustomReplies = YES;
        
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
}

- (NSDictionary *)extraParameters {
    return @{};
}

- (IBAction)leftButtonPressed:(UIButton *)sender {
    [self customActionButtonPressed:sender
                    withCustomTitle:self.leftButtonTitle
                        andDeepLink:self.yo.leftDeepLink];
}

- (IBAction)rightButtonPressed:(UIButton *)sender {
    [self customActionButtonPressed:sender
                    withCustomTitle:self.rightButtonTitle
                        andDeepLink:self.yo.rightDeepLink];
}

- (void)customActionButtonPressed:(UIButton *)button
                  withCustomTitle:(NSString *)title
                      andDeepLink:(NSString *)urlString {
    if (urlString) {
        [self close];
        NSURL *url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        return;
    }
    
    [self showActivityOnView:button];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"reply_to"] = self.yo.yoID;
    
    if (self.isCustomReplies) {
        params[@"context"] = title;
        [button setTitle:MakeString(@"Sent %@", title) forState:UIControlStateNormal];
    }
    else {
        [button setTitle:@"Sent Yo" forState:UIControlStateNormal];
    }
    
    [button.titleLabel removeFromSuperview];
    
    [[YoManager sharedInstance] yo:self.yo.senderUsername
                 contextParameters:params
                 completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                     BOOL success = (result == YoResultSuccess);
                     if ( ! success) {
                         [button setTitle:@"Failed" forState:UIControlStateNormal];
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [button setTitle:title forState:UIControlStateNormal];
                         });
                     }
                     else {
                         NSDictionary *context = @{Yo_USERNAME_KEY:self.yo.senderUsername, @"success":@(success)};
                         [[NSNotificationCenter defaultCenter] postNotificationName:YoUserYoBackFromYoCardFinished object:self userInfo:context];
                         [self removeActivityFromView:button];
                         [button addSubview:button.titleLabel];
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [self close];
                         });
                     }
                 }];
}

@end
