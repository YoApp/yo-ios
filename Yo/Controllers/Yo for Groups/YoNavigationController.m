//
//  YoNavigationController.m
//  Yo
//
//  Created by Peter Reveles on 5/18/15.
//
//

#import "YoNavigationController.h"
#import <FXBlurView/FXBlurView.h>

@interface YoNavigationController () <UINavigationControllerDelegate>
@end

@implementation YoNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    
    [self configureUI];
}

- (void)configureUI {
    
    self.view.layer.cornerRadius = 10.0;
    self.view.layer.masksToBounds = YES;
    
    NSDictionary *barButtonAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"Montserrat-Bold" size:16.0f]};
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:barButtonAttributes
                                                                                            forState:UIControlStateNormal];
    
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.translucent = YES;
    
    NSDictionary *titleAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"Montserrat-Bold" size:20.0f],
                                      NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.navigationBar setTitleTextAttributes:titleAttributes];
    
    [self.navigationBar setBackgroundImage:[UIImage new]
                            forBarPosition:UIBarPositionAny
                                barMetrics:UIBarMetricsDefault];
    
    [self.navigationBar setShadowImage:[UIImage new]];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ( ! self.allowCustomBarColor && ! [viewController.view.backgroundColor isEqual:[UIColor whiteColor]]) {
        self.navigationBar.backgroundColor = viewController.view.backgroundColor;
    }
}

- (IBAction)close {
    [self hideBlurredBackground];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentBlurredBackgroundAndController:(YoBaseViewController *)viewControllerToPresent {
    [self showBlurredBackgroundWithViewController:viewControllerToPresent];
    [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)showBlurredBackgroundWithViewController:(YoBaseViewController *)viewController {
    UIImage *image = [YoApp takeScreenShot];
    UIImage *blurredImage = [image blurredImageWithRadius:13.0 iterations:5 tintColor:[UIColor blackColor]];
    
    viewController.blurredBackgrounImageView = [[UIImageView alloc] initWithImage:blurredImage];
    viewController.blurredBackgrounImageView.frame = self.view.bounds;
    viewController.blurredBackgrounImageView.alpha = 0.0;
    [self.view addSubview:viewController.blurredBackgrounImageView];
    [UIView animateWithDuration:0.2 animations:^{
        viewController.blurredBackgrounImageView.alpha = 1.0;
    }];
}

- (void)hideBlurredBackground {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.blurredBackgrounImageView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.blurredBackgrounImageView removeFromSuperview];
                         self.blurredBackgrounImageView = nil;
                     }];
}

@end
