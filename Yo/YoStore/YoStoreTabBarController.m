//
//  YoStoreTabBarController.m
//  Yo
//
//  Created by Peter Reveles on 4/24/15.
//
//

#import "YoStoreTabBarController.h"
#import "YoStoreDataManager.h"

@interface YoStoreTabBarController ()

@end

@implementation YoStoreTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configureToYoUI];
}

- (void)configureToYoUI {
    self.tabBar.tintColor = [UIColor whiteColor];
    self.tabBar.translucent = YES;
    self.tabBar.backgroundImage = [UIImage new];
    self.tabBar.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
}

@end
