//
//  YoWelcomeController.h
//  Yo
//
//  Created by Or Arbel on 6/7/15.
//
//

#import "YoLoggedOutViewController.h"

@interface YoWelcomeController : YoLoggedOutViewController <UIScrollViewDelegate>

@property(nonatomic, weak) IBOutlet UIButton *loginButton;
@property(nonatomic, weak) IBOutlet UIButton *facebookButton;
@property(nonatomic, weak) IBOutlet UIButton *signupButton;
@property(nonatomic, weak) IBOutlet UIView *descriptionView;
@property(nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property(nonatomic, weak) IBOutlet UIPageControl *pageControl;

@end
