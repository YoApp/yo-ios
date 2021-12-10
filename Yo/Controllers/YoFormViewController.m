//
//  YoFormViewController.m
//  Yo
//
//  Created by Peter Reveles on 4/15/15.
//
//

#import "YoFormViewController.h"

@interface YoFormViewController ()

@end

@implementation YoFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)viewWillAppear:(BOOL)animated {
//    self.currentSignupStep = YoSignupStepGetPasswordAndUsername;
//    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
//}

//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    self.currentSignupStep = YoSignUpStepUnstarted;
//    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dismissWithCompletionBlock:(void (^)())block {
    __weak YoFormViewController *weakSelf = self;
    void (^notifyDelegate)() = ^() {
        if (weakSelf.delegate) {
            [weakSelf.delegate formControllerDidDismiss:self];
        }
    };
    
    if (self.navigationController != nil &&
        ![self.navigationController.viewControllers.firstObject isEqual:self]) {
        [self.navigationController popViewControllerAnimated:YES completionBlock:^{
            notifyDelegate();
        }];
    }
    else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            notifyDelegate();
        }];
    }
}

@end
