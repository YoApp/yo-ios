//
//  BaseController.m
//  Yo
//
//  Created by Or Arbel on 3/2/14.
//
//

#import "YoBaseTableViewController.h"
#import "YOCell.h"
#import <AddressBookUI/AddressBookUI.h>
#import <Social/Social.h>
#import "YOShareCell.h"
#import "YOUDID.h"
#import "YOFacebookManager.h"
#import "Yo_Extensions.h"
#import "YoWebBrowserController.h"
#import "YoContactBookController.h"
#import "YoAddressBookParser.h"
#import "YoInbox.h"
#import "YoThemeManager.h"

typedef NS_ENUM(NSUInteger, YoGif) {
    YoGif_HowToYo,
    YoGif_HowToYoLink,
    YoGif_HowToYoLocation,
};

@interface YoBaseTableViewController ()
@property (assign, nonatomic) CGRect originalMainScrollViewFrame;
@end

@implementation YoBaseTableViewController

+ (NSString *)nibNameForScreenSize:(NSString *)nibNameOrNil {
    if ([UIScreen mainScreen].bounds.size.height > 480) {
        NSString *filenameFor5 = [NSString stringWithFormat:@"%@_5", nibNameOrNil];
        NSString *pathAndFileName = [[NSBundle mainBundle] pathForResource:filenameFor5 ofType:@"nib"];
        if (pathAndFileName) {
            nibNameOrNil = filenameFor5;
        }
    }
    return nibNameOrNil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:[YoBaseTableViewController nibNameForScreenSize:nibNameOrNil] bundle:nibBundleOrNil];
    if (self) {
        // setup
        [self setDefaultTextAttributes];
    }
    return self;
}

- (void)setDefaultTextAttributes {
    if (IS_OVER_IOS(8.0)) {
        [[UILabel appearanceWhenContainedIn:[self class], nil] setAdjustsFontSizeToFitWidth:YES];
        [[UILabel appearanceWhenContainedIn:[self class], nil] setMinimumScaleFactor:0.1f];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.tableView.delaysContentTouches = YES;
    self.tableView.directionalLockEnabled = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard

- (void)keyboardDidShowNotification:(NSNotification *)notification {
    // purposely empty
}

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardBounds;
    [keyboardBoundsValue getValue:&keyboardBounds];
    
    if (IS_OVER_IOS(7.0)) {
        UIEdgeInsets e = self.tableView.contentInset;
        e.bottom = keyboardBounds.size.height;
        [[self tableView] setScrollIndicatorInsets:e];
        [[self tableView] setContentInset:e];
    }
    else if ([[YoApp currentSession] isLoggedIn]){ // dont want keyboard shifting during logged out state
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y -= keyboardBounds.size.height;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self.tableView setFrame:tableViewFrame];
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    if (IS_OVER_IOS(7.0)) {
        UIEdgeInsets e = self.tableView.contentInset;
        e.bottom = 0;
        NSNumber *value = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [UIView animateWithDuration:[value doubleValue] animations:^{
            [[self tableView] setScrollIndicatorInsets:e];
            [[self tableView] setContentInset:e];
        }];
    }
    else if ([[YoApp currentSession] isLoggedIn]){ // dont want keyboard shifting during logged out state
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 0.0f;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self.tableView setFrame:tableViewFrame];
        [UIView commitAnimations];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)reloadTableViewCellsColorsInSection:(NSInteger)section{
    if (section < [self.tableView numberOfSections]) {
        //CGFloat relativeCellColorIndex = 0;
        //        for (int sectionIndex = 0; sectionIndex < section; sectionIndex++) {
        //            relativeCellColorIndex += [self.tableView numberOfRowsInSection:sectionIndex];
        //        }
        for (int cellIndex = 0; cellIndex < [self.tableView numberOfRowsInSection:section]; cellIndex++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cellIndex inSection:section];
            YOCell *cell = (YOCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) [self colorCell:cell withIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:section]];
            //relativeCellColorIndex++;
        }
    }
    else
        DDLogWarn(@"Error - Invalid section number for reload colors");
}

- (void)colorCell:(YOCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    NSUInteger rowRelativeToSection = indexPath.row;
    
    if (indexPath.section < [self.tableView numberOfSections]) {
        for (int sectionIndex = 0; sectionIndex < indexPath.section; sectionIndex++) {
            rowRelativeToSection += [self.tableView numberOfRowsInSection:sectionIndex];
        }
    }
    
    cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:rowRelativeToSection];
}

- (NSData *)dataForGifToShare:(YoGif)shareGif{
    
    NSString *gifTitle = nil;
    
    switch (shareGif) {
        case YoGif_HowToYo:
            gifTitle = @"howToYo";
            break;
            
        case YoGif_HowToYoLink:
            gifTitle = @"howToYoLink";
            break;
            
        case YoGif_HowToYoLocation:
            gifTitle = @"howToYoLocation";
            break;
    }
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:gifTitle withExtension:@"gif"];
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:nil];
    
    return data;
}

- (UIImage *)yoCountImage {
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    view.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 89)];
    label.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
    label.backgroundColor = [UIColor colorWithHexString:TURQUOISE];
    label.textColor = [UIColor whiteColor];
    label.text = [[YoUser me] username];
    label.textAlignment = NSTextAlignmentCenter;
    
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 89, 320, 89)];
    bottomLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:42];
    bottomLabel.backgroundColor = [UIColor colorWithHexString:EMERALD];
    bottomLabel.textColor = [UIColor whiteColor];
    bottomLabel.text = MakeString(@"%ld YO'S", [[YoUser me] yoCount]);
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    
    UILabel *watermark = [[UILabel alloc] initWithFrame:CGRectMake(10, 320 - 10 - 30, 320, 30)];
    watermark.text = @"http://justyo.co";
    watermark.font = [UIFont fontWithName:@"Montserrat-Bold" size:22];
    watermark.backgroundColor = [UIColor clearColor];
    watermark.alpha = 0.8;
    watermark.textColor = [UIColor whiteColor];
    
    [view addSubview:label];
    [view addSubview:bottomLabel];
    [view addSubview:watermark];
    
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/** defaults to tweeting How to Yo gif if no image provided */
- (void)tweetWithImage:(UIImage *)image message:(NSString *)message{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        
        NSString *username = [[YoUser me] username];
        
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        [tweetSheet setInitialText:message];
        
        if (image)
            [tweetSheet addImage:image];
        
        [tweetSheet addURL:[NSURL URLWithString:MakeString(@"http://www.justyo.co/%@/", username)]];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                               desciption:NSLocalizedString(@"Please connect to Twitter in Settings -> Twitter", nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
        if ([[YoiOSAssistant sharedInstance] canOpenYoAppSettings]) {
            [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"open settings", nil).capitalizedString tapBlock:^{
                [[YoiOSAssistant sharedInstance] openYoAppSettings];
            }]];
        }
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
    }
}



- (void)presentBrowserWithURLString:(NSString *)urlString {
    YoWebBrowserController *webBrowser = [[YoWebBrowserController alloc] initWithUrl:[NSURL URLWithString:urlString]];
    [self presentViewController:webBrowser animated:YES completion:nil];
}

- (void)shareOnFacebookWithImage:(UIImage *)image {
    NSString *username = [[YoUser me] username];
    
    //NSString *urlToShow = MakeString(@"justyo.co/%@", username);
    
    NSURL *urlToShare = [NSURL URLWithString:MakeString(@"http://www.justyo.co/%@", username)];
    
    urlToShare = [urlToShare bitlyWraped];
    
    NSString *message = [NSString stringWithFormat:@"%@ %@  %@", NSLocalizedString(@"Yo me", nil), username, @"(Tap Here)"];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
        message = [NSString stringWithFormat:@"%@ %@  (Tap %@)", NSLocalizedString(@"Yo me", nil), username, urlToShare.absoluteString];
    
    if (image)
        message = NSLocalizedString(@"Yo me", nil);
    
    [YOFacebookManager shareURL:urlToShare image:image];
}

- (void)swipeRightDetected:(UISwipeGestureRecognizer *)swipeGr {
    NS_DURING
    YOCell *cell = (YOCell *)swipeGr.view;
    
    self.showShareMenuForIndexPath = nil;
    NSInteger index = [self.tableView indexPathForCell:cell].row;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    NS_HANDLER
    NS_ENDHANDLER
}

- (void)capitalize:(UITextField*)textField {
    textField.text = [textField.text uppercaseString];
}

- (void)shareWithAppleDefaultUIText:(NSString *)text url:(NSURL *)url image:(UIImage *)image data:(NSData *)data{
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    if (!text && !url && !image) return;
    
    if (text) [sharingItems addObject:text];
    
    if (url) [sharingItems addObject:url];
    
    if (image) [sharingItems addObject:image];
    
    if (data) [sharingItems addObject:data];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    
    [activityController setValue:@"Yo" forKey:@"subject"]; // this allows us to set the subject in the email if the user chooses to share by emial
    
    [self presentViewController:activityController animated:YES completion:nil];
}

#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - Utility Methods

- (BOOL)currentDeviceIsIpod{
    NSString *deviceType = [UIDevice currentDevice].model;
    BOOL isIpod = [deviceType.lowercaseString rangeOfString:@"ipod"].location != NSNotFound;
    return isIpod;
}

@end
