//
//  YoWelcomeController.m
//  Yo
//
//  Created by Or Arbel on 6/7/15.
//
//

#import "YoWelcomeController.h"

@implementation YoWelcomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)setupSlides {
    
    [self.scrollView removeAllSubviews];
    
    NSArray *slideImageNames = @[
                                 @"welcome1",
                                 @"welcome2",
                                 @"welcome3"];
    
    self.pageControl.numberOfPages = slideImageNames.count + 1;
    
    CGFloat xOffset = 0.0;
    
    for (NSString *imageName in slideImageNames) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.frame = self.scrollView.bounds;
        imageView.left = xOffset + self.scrollView.width;
        [self.scrollView addSubview:imageView];
        xOffset += self.scrollView.width;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.width * (slideImageNames.count+1), self.scrollView.height);
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.signupButton.backgroundColor = [UIColor colorWithHexString:EMERALD];
    
    [self setupSlides];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.descriptionView.alpha = MAX(0.0,1.0 -  (scrollView.contentOffset.x/200));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControl.currentPage = scrollView.contentOffset.x / scrollView.width;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.pageControl.currentPage = scrollView.contentOffset.x / scrollView.width;
}

@end
