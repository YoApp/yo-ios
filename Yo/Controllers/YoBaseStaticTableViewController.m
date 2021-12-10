//
//  YoBaseStaticTableViewController.m
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoBaseStaticTableViewController.h"

@interface YoBaseStaticTableViewController ()

@end

@implementation YoBaseStaticTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[YoActivityManager sharedInstance] controllerWillBePresented:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[YoActivityManager sharedInstance] controllerPresented:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[YoActivityManager sharedInstance] controllerDidDisAppear:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return YES;
}

@end
