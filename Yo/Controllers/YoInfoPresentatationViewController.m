//
//  YoInfoPresentatationViewController.m
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import "YoInfoPresentatationViewController.h"

@interface YoInfoPresentatationViewController ()

@end

@implementation YoInfoPresentatationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - External Utility

- (void)playYoSound {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"yo" ofType:@"mp3"];
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!error) [audioPlayer play];
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
