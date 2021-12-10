//
//  YoCreateGroupController.m
//  Yo
//
//  Created by Or Arbel on 5/12/15.
//
//

#import "YoCreateGroupController.h"
#import "YoAddController.h"
#import "YoApp.h"

@interface YoCreateGroupController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet YOTextField *textField;

@property (nonatomic, strong) IBOutlet YoLabel *inspirationLabel;
@property (nonatomic, strong) IBOutlet YoLabel *exampleLabel;
@property (nonatomic, strong) IBOutlet YoLabel *descriptionLabel;

@property (nonatomic, strong) UIBarButtonItem *nextButton;

@property (nonatomic, strong) NSArray *examples;
@property (nonatomic, assign) NSInteger currentExampleIndex;

@end

@implementation YoCreateGroupController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textField.layer.cornerRadius = 5;
    self.textField.layer.masksToBounds = YES;
    self.textField.backgroundColor = [UIColor colorWithHexString:@"8842A8"];
    self.textField.tintColor = [UIColor whiteColor];
    self.textField.delegate = self;
    
    [self.textField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    [self.textField becomeFirstResponder];
    
    UIBarButtonItem *fixedWidth = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedWidth.width = 5.0f;
    
    NSString *title = nil;
    if ([self isModal]) {
        title = NSLocalizedString(@"Cancel", nil);
    }
    else {
        title = NSLocalizedString(@"Back", nil);
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:title.capitalizedString style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.nextButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil).capitalizedString style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed)];
    self.nextButton.enabled = NO;
    self.navigationItem.rightBarButtonItems = @[fixedWidth, self.nextButton];
    self.navigationItem.title = NSLocalizedString(@"Name Yo Group", nil);
    
    self.examples = @[
                      @"( 🍻 )", @"Yo your buddies when you want to grab a beer",
                      @"( 📈 )", @"Yo your team when the meeting starts",
                      @"( 💃 )", @"Yo location to your BFFs when your'e partying",
                      @"( 👨‍👩‍👦‍👦 )", @"Yo location and be a better connected family",
                      @"( 🎮 )", @"Yo for FIFA right now in the office play room",
                      @"( 🏀 )", @"Yo your team when you wanna hit the basketball court"
                      ];
    
    self.descriptionLabel.makeYoOccurancesBold = YES;
    
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(animateNextExample) userInfo:nil repeats:YES];
    
    self.inspirationLabel.alpha = 0.0;
    self.exampleLabel.alpha = 0.0;
    self.descriptionLabel.alpha = 0.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.inspirationLabel.alpha = 1.0;
    }];
    
    [self animateNextExample];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)textFieldDidChange:(UITextField *)textField {
    self.nextButton.enabled = textField.text.length > 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self nextButtonPressed];
    return YES;
}

- (void)cancelButtonPressed {
    [self.textField resignFirstResponder];
    if ([self isModal]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)nextButtonPressed {
    [self.textField resignFirstResponder];
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:YoMainStoryboard bundle:nil];
    YoAddController *addMembersVC = [mainStoryBoard instantiateViewControllerWithIdentifier:YoAddControllerID];
    YoGroup *group = [YoGroup new];
    group.name = self.textField.text;
    addMembersVC.group = group;
    addMembersVC.mode = YoAddControllerCreateGroup;
    [self.navigationController pushViewController:addMembersVC animated:YES];
}

- (void)animateNextExample {
    
    if (self.currentExampleIndex >= self.examples.count) {
        self.currentExampleIndex = 0;
    }
    
    NSString *currentExample = self.examples[self.currentExampleIndex];
    NSString *currentDescription = self.examples[self.currentExampleIndex + 1];
    
    
    [UIView animateWithDuration:0.6 animations:^{
        
        self.exampleLabel.alpha = 0.0;
        self.descriptionLabel.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        self.exampleLabel.text = currentExample;
        self.descriptionLabel.text = currentDescription;
        
        [UIView animateWithDuration:0.6 animations:^{
            
            self.exampleLabel.alpha = 1.0;
            self.descriptionLabel.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    self.currentExampleIndex = self.currentExampleIndex + 2;
}

#pragma mark - Navigaiton

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:YoSegueToAddGroupMemembers]) {
        YoAddController *addMembersVC = segue.destinationViewController;
        addMembersVC.navigationItem.title = self.textField.text;
        YoGroup *group = [YoGroup new];
        group.name = self.textField.text;
        addMembersVC.group = group;
    }
}

@end
