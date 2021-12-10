//
//  YoCreateGroupPopupViewController.m
//  Yo
//
//  Created by Peter Reveles on 7/23/15.
//
//

#import "YoCreateGroupPopupViewController.h"

@interface YoCreateGroupPopupViewController () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UIView *bodyView;
@property (nonatomic, strong) IBOutlet YOTextField *textField;
@property (nonatomic, strong) IBOutlet YoLabel *exampleTitleLabel;
@property (nonatomic, strong) IBOutlet YoLabel *exampleMessageLabel;
@property (nonatomic, strong) IBOutlet UIButton *createButton;

@property (nonatomic, strong) NSArray *examples;
@property (nonatomic, assign) NSUInteger currentExampleIndex;
@property (nonatomic, assign) NSTimeInterval timeAllotedPerGroupNameExample;
@property (nonatomic, strong) NSMutableArray *constraints;
@end

@implementation YoCreateGroupPopupViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _groupMembers = nil;
        
        _examples = @[@"( 🍻 )", @"Yo your buddies when you want to grab a beer",
                      @"( 📈 )", @"Yo your team when the meeting starts",
                      @"( 💃 )", @"Yo location to your BFFs when your'e partying",
                      @"( 👨‍👩‍👦‍👦 )", @"Yo location and be a better connected family",
                      @"( 🎮 )", @"Yo for FIFA right now in the office play room",
                      @"( 🏀 )", @"Yo your team when you wanna hit the basketball court"];
        
        _timeAllotedPerGroupNameExample = 3.0;
        
        self.title = NSLocalizedString(@"Name Yo Group", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _textField.placeholder = NSLocalizedString(@"Enter Group Name", nil);
    _textField.delegate = self;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.returnKeyType = UIReturnKeyDone;
    [_textField addTarget:self
                   action:@selector(textFieldDidChange:)
         forControlEvents:UIControlEventEditingChanged];
    
    [_createButton setTitle:NSLocalizedString(@"Create", nil) forState:UIControlStateNormal];
    _createButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_textField becomeFirstResponder];
    [self presentNextGroupNameExample];
    [NSTimer scheduledTimerWithTimeInterval:_timeAllotedPerGroupNameExample
                                     target:self
                                   selector:@selector(presentNextGroupNameExample)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)presentNextGroupNameExample {
    NSString *nextExampleTitle = self.examples[self.currentExampleIndex];
    NSString *nextExampleMessage = self.examples[self.currentExampleIndex + 1];
    
    [UIView animateWithDuration:0.6 animations:^{
        self.exampleTitleLabel.alpha = 0.0;
        self.exampleMessageLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.exampleTitleLabel.text = nextExampleTitle;
        self.exampleMessageLabel.text = nextExampleMessage;
        [UIView animateWithDuration:0.6 animations:^{
            self.exampleTitleLabel.alpha = 1.0;
            self.exampleMessageLabel.alpha = 1.0;
        }];
    }];
    
    self.currentExampleIndex += 2; // Peter: Take a look at how examples are stored to understand this
    self.currentExampleIndex %= self.examples.count;
}

#pragma mark - Actions

- (IBAction)closeWithSender:(id)sender {
    [self.textField resignFirstResponder];
    [self closeWithCompletionBlock:nil];
}

- (IBAction)createGroupWithSender:(id)sender {
    if (self.textField.text.length < 1) {
        return;
    }
    
    [self.textField resignFirstResponder];
    
    NSArray *serializedMemebers = [self serializeGroupMemebers:self.groupMembers];
    
    [MBProgressHUD showHUDAddedTo:self.bodyView animated:YES];
    
    [[YoApp currentSession] createGroupWithName:self.textField.text
                             andMemberUsernames:serializedMemebers
                              completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                                  [MBProgressHUD hideHUDForView:self.bodyView animated:NO];
                                  if (result == YoResultSuccess) {
                                      YoGroup *group = [YoGroup objectFromDictionary:responseObject[@"group"]];
                                      [[[YoUser me] contactsManager] promoteObjectToTop:group];
                                      [self closeWithCompletionBlock:^{
                                          [[APPDELEGATE mainController] animateTopCells:1];
                                      }];
                                  }
                                  else {
                                      YoAlert *alert = [[YoAlert alloc] initWithTitle:@"Failed" desciption:@"Try again later?"];
                                      [alert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
                                      [[YoAlertManager sharedInstance] showAlert:alert];
                                  }
                              }];
}

- (NSArray *)serializeGroupMemebers:(NSArray *)groupMembers {
    NSMutableArray *serializedUsers = [[NSMutableArray alloc] initWithCapacity:groupMembers.count];
    for (YoUser *user in groupMembers) {
        NS_DURING
        NSDictionary *serializedUser = @{@"user_type":@"user",
                                         @"username":user.username};
        [serializedUsers addObject:serializedUser];
        NS_HANDLER
        DDLogError(@"%@", localException);
        NS_ENDHANDLER
    }
    return serializedUsers;
}

#pragma mark Gestures

- (IBAction)didTapToDismissViewWithGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    if (!CGRectContainsPoint(self.containerView.frame, touchPoint)) {
        [self closeWithCompletionBlock:nil];
    }
}

#pragma mark - UITextField

- (void)textFieldDidChange:(UITextField *)textField {
    self.createButton.enabled = textField.text.length > 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
