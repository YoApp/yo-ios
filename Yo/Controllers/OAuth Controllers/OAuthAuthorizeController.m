//
//  OAuthAuthorizeController.m
//  Yo
//
//  Created by Or Arbel on 7/20/15.
//
//

#import "OAuthAuthorizeController.h"
#import "YoApp.h"

@interface OAuthAuthorizeController ()

@property(nonatomic, weak) IBOutlet UILabel *appNameLabel;
@property(nonatomic, weak) IBOutlet UILabel *appDescriptionLabel;
@property(nonatomic, weak) IBOutlet UILabel *bottomLabel;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *aiView;

@end

@implementation OAuthAuthorizeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appNameLabel.hidden = YES;
    self.appDescriptionLabel.hidden = YES;
    self.bottomLabel.hidden = YES;
    
    self.aiView.hidesWhenStopped = YES;
    [self.aiView startAnimating];
    
    NS_DURING
    [[[YoApp currentSession] yoAPIClient] GET:@"clients"
                                   parameters:@{@"client_id": self.clientId}
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          
                                          self.appNameLabel.text = responseObject[@"app"][@"name"];
                                          self.appDescriptionLabel.text = responseObject[@"app"][@"description"];
                                          [self.aiView stopAnimating];
                                          
                                          self.appNameLabel.hidden = NO;
                                          self.appDescriptionLabel.hidden = NO;
                                          self.bottomLabel.hidden = NO;
                                          
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           
                                          [self closeWithCompletionBlock:^{
                                              NSString *urlToOpen = MakeString(@"yo%@://justyo.co?error=%@&errorCode=501", self.appId, @"Failed");
                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                                          }];
                                      }];
    NS_HANDLER
    [self closeWithCompletionBlock:^{
        NSString *urlToOpen = MakeString(@"yo%@://justyo.co?error=%@&errorCode=504", self.appId, @"Failed");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
    }];
    NS_ENDHANDLER
}

- (IBAction)denyButtonPressed:(id)sender {
    [self closeWithCompletionBlock:^{
        NSString *urlToOpen = MakeString(@"yo%@://justyo.co?errorMessage=%@&errorCode=401", self.appId, @"UserDenied");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
    }];
}

- (IBAction)approveButtonPressed:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[[YoApp currentSession] yoAPIClient] GET:@"access_token"
                                   parameters:@{@"client_id": self.clientId}
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                                          [self closeWithCompletionBlock:^{
                                              NSString *accessToken = responseObject[@"access_token"];
                                              NSString *urlToOpen = MakeString(@"yo%@://justyo.co?access_token=%@", self.appId, accessToken);
                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                                          }];
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                                          [self closeWithCompletionBlock:^{
                                              NSString *urlToOpen = MakeString(@"yo%@://justyo.co?error=%@&errorCode=502", self.appId, @"Failed");
                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                                          }];
                                      }];
}

@end
