//
//  YoAddPickerController.m
//  Yo
//
//  Created by Or Arbel on 5/20/15.
//
//

#import "YoAddPickerController.h"
#import "YoCreateGroupController.h"
#import "YoAddFriendController.h"
#import "YoMainNavigationController.h"
#import "YoAddController.h"

@interface YoAddPickerController ()

@property (nonatomic, strong) NSArray *friendsExamples;
@property (nonatomic, assign) NSInteger currentFriendExampleIndex;

@property (nonatomic, strong) NSArray *groupsExamples;
@property (nonatomic, assign) NSInteger currentGroupExampleIndex;

@property (nonatomic, strong) NSArray *subscribeExamples;
@property (nonatomic, assign) NSInteger currentSubscribeExampleIndex;

@property (nonatomic, assign) BOOL currentlyShowingFriendsTip;

@end

@implementation YoAddPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.text = [self.currentContextObject textForTitleBar];
    
    self.backgroundView.layer.cornerRadius = 10.0;
    self.backgroundView.layer.masksToBounds = YES;
    
    self.yofriendButton.layer.cornerRadius = 3.0;
    self.yofriendButton.layer.masksToBounds = YES;
    [self.yofriendButton setTitle:NSLocalizedString(@"Add a Friend", nil)
                         forState:UIControlStateNormal];
    
    self.createGroupButton.layer.cornerRadius = 3.0;
    self.createGroupButton.layer.masksToBounds = YES;
    [self.createGroupButton setTitle:NSLocalizedString(@"Create Group", nil)
                         forState:UIControlStateNormal];
    
    self.subscribeButton.layer.cornerRadius = 3.0;
    self.subscribeButton.layer.masksToBounds = YES;
    [self.subscribeButton setTitle:NSLocalizedString(@"Subscribe", nil)
                         forState:UIControlStateNormal];
    
    self.friendTipLabel.makeYoOccurancesBold = YES;
    self.groupTipLabel.makeYoOccurancesBold = YES;
    self.subscribeTipLabel.makeYoOccurancesBold = YES;
    
    self.friendTipLabel.verticalAlignment = YoLabelVerticalAlignmentBottom;
    self.groupTipLabel.verticalAlignment = YoLabelVerticalAlignmentBottom;
    self.subscribeTipLabel.verticalAlignment = YoLabelVerticalAlignmentBottom;
    
    self.createGroupButton.backgroundColor = [UIColor colorWithHexString:@"285F95"];
    
    self.friendsExamples = @[
                             @"😛\nYo your best friend when you wanna talk",
                             @"👪\nYo mom when you arrive from school",
                             @"🚗\nYo your location to your wife when you're commuting home",
                             @"💏\nYo your husband when you think about him",
                             @"🙋\nYo your location to your friend when you arrived",
                             @"😉\nYo your closest person - only you will know what it means"
                             ];
    
    self.groupsExamples = @[
                            @"🍻\nYo your beer buddies when you want to grab a beer",
                            @"📈\nYo your team when the meeting starts",
                            @"💃\nYo your location to your BFFs when your'e partying",
                            @"👨‍👩‍👦‍👦\nYo your location and be a better connected family",
                            @"🎮\nYo for FIFA right now in the office play room",
                            @"🏀\nYo your team when you wanna hit the court"
                            ];
   
    self.subscribeExamples = @[
                               @"📷\nGet a Yo when your favorite Instagrammer posts a pic",
                               @"⚽️\nGet a Yo when your soccer team score a goal",
                               @"📰\nGet a Yo when a news story is going viral",
                               @"😂\nGet a Yo when Funny or Die post an awesome video",
                               @"🎵\nGet a Yo when a surprise track is released on Spotify",
                               @"📺\nGet a Yo when your favorite TV show releases a new trailer"
                               ];
    
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(animateNextExample) userInfo:nil repeats:YES];
    
    // self.friendTipView.alpha = 0.0;
    //self.groupTipView.alpha = 0.0;
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [self animateNextExample];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
}

- (void)animateNextExample {
    
    if (self.currentFriendExampleIndex >= self.friendsExamples.count) {
        self.currentFriendExampleIndex = 0;
    }
    
    if (self.currentGroupExampleIndex >= self.groupsExamples.count) {
        self.currentGroupExampleIndex = 0;
    }
    
    if (self.currentSubscribeExampleIndex >= self.subscribeExamples.count) {
        self.currentSubscribeExampleIndex = 0;
    }
    
    NSString *currentFriendExample = self.friendsExamples[self.currentFriendExampleIndex];
    NSString *currentGroupExample = self.groupsExamples[self.currentGroupExampleIndex];
    NSString *subscribeExample = self.subscribeExamples[self.currentSubscribeExampleIndex];
    
    [UIView animateWithDuration:0.6 animations:^{
        
        self.friendTipLabel.alpha = 0.0;
        self.groupTipLabel.alpha = 0.0;
        self.subscribeTipLabel.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        self.friendTipLabel.text = currentFriendExample;
        self.groupTipLabel.text = currentGroupExample;
        self.subscribeTipLabel.text = subscribeExample;
        
        [UIView animateWithDuration:0.6 animations:^{
            
            self.friendTipLabel.alpha = 1.0;
            self.groupTipLabel.alpha = 1.0;
            self.subscribeTipLabel.alpha = 1.0;
            
        }];
    }];
    
    self.currentFriendExampleIndex = self.currentFriendExampleIndex + 1;
    self.currentGroupExampleIndex = self.currentGroupExampleIndex + 1;
    self.currentSubscribeExampleIndex = self.currentSubscribeExampleIndex + 1;
}

#pragma mark - Actions

- (IBAction)addFriendPressed:(id)sender {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    YoAddController *addFriendVC = [mainStoryBoard instantiateViewControllerWithIdentifier:YoAddControllerID];
    addFriendVC.currentContextObject = self.currentContextObject;
    addFriendVC.mode = YoAddControllerAddToRecentsList;
    [self.navigationController pushViewController:addFriendVC animated:YES];
    [YoAnalytics logEvent:@"TappedAddFriend" withParameters:nil];
}


- (IBAction)createGroupPressed:(id)sender {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    YoCreateGroupController *createGroupVC = [mainStoryBoard instantiateViewControllerWithIdentifier:YoCreateGroupControllerID];
    [self.navigationController pushViewController:createGroupVC animated:YES];
    [YoAnalytics logEvent:@"TappedCreateGroup" withParameters:nil];
}

- (IBAction)subscribePressed:(id)sender {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoStoreStoryboard bundle:nil];
    UIViewController *storeController = [mainStoryBoard instantiateInitialViewController];
    [self.navigationController pushViewController:storeController animated:YES];
    [YoAnalytics logEvent:@"TappedSubscribe" withParameters:nil];
}

@end
