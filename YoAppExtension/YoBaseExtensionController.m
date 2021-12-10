//
//  YoBaseShareSheet.m
//  Yo
//
//  Created by Peter Reveles on 11/15/14.
//
//

#import "YoBaseExtensionController.h"
#import <SSKeychain/SSKeychain.h>
#import "YoContactManager.h"
#import "YOCell.h"
#import "YOHeaderFooterCell.h"
#import "YOUDID.h"
#include <netdb.h>
#import "YoThemeManager.h"

@interface YoBaseExtensionController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) BOOL isBanned;
@property (weak, nonatomic) IBOutlet UIView *tableviewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableviewContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet UIView *mainContainer;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndidcator;
@property (nonatomic, strong) NSArray *friends;
@end

#define YOALL_ENABLED YES

#define CELL_HEIGHT 80.0f
#define CELL_HEIGHT_TO_WIDTH_RATIO 0.278125f
#define MAX_VISIBLE_CELL_COUNT_iPhone4 4
#define MAX_VISIBLE_CELL_COUNT_iPhone5 5

#define HEADER_CELL_ID @"HEADER_CELL_ID"

@implementation YoBaseExtensionController : UIViewController

- (CGFloat)cellHeight{
    return CELL_HEIGHT;
    //return self.tableView.width * CELL_HEIGHT_TO_WIDTH_RATIO;
}

- (int)maxVisibleCellCount{
    if (CGRectGetHeight(([UIScreen mainScreen].bounds)) <= 480.0f)
        return MAX_VISIBLE_CELL_COUNT_iPhone4;
    else return MAX_VISIBLE_CELL_COUNT_iPhone5;
}


- (NSInteger)minVisibleCellCount {
    NSInteger min = self.friends.count;
    if (min >= MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL) {
        min++;
    }
    return min;
}

#pragma mark - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // this is the init that is called
    }
    return self;
}

- (void)viewDidLoad{
    [[YoApp currentSession] load];
    [self setup];
    
    self.friends = [[YoUser me] list];
    [self layoutTableView];
    
    void (^displayFatalAlert)(NSString *title, NSString *description) = ^(NSString *title, NSString *description) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:description
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self close];
                                                              }];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    };
    
    [self reloadContactsWithCompletionBlock:^(bool success) {
        if (![self.friends count]) {
            displayFatalAlert(NSLocalizedString(@"Please Launch Yo", nil),
                              NSLocalizedString(@"Please launch Yo first to add contacts", nil));
        }
        else {
            [self.activityIndidcator stopAnimating];
        }
    }];
    
    if (![[YoApp currentSession] isLoggedIn]) {
        displayFatalAlert(NSLocalizedString(@"Please Launch Yo", nil),
                          NSLocalizedString(@"Please launch Yo to login.", nil));
    }
    else {
        if (!self.friends.count) {
            [self.activityIndidcator startAnimating];
        }
        else {
            [self.tableView reloadData];
        }
    }
    
    [Flurry startSession:@"HRYV2J2PNZ7FNC3MJWTQ"];
}

- (void)setup{
    // tableview
    [self.tableView registerClass:[YOHeaderFooterCell class] forHeaderFooterViewReuseIdentifier:HEADER_CELL_ID];
    [self.doneButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    [self addActivityIndicatorToView:self.view];
    
    self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.0f];
    self.mainContainer.backgroundColor = [self.mainContainer.backgroundColor colorWithAlphaComponent:0.0f];
    
    self.tableviewContainer.backgroundColor = [[YoThemeManager sharedInstance] backgroundColor];
    self.tableviewContainer.clipsToBounds = YES;
    self.tableviewContainer.layer.cornerRadius = 5.0f;
    
    self.doneButton.layer.cornerRadius = 5.0f;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [[YoThemeManager sharedInstance] backgroundColor];
    self.tableView.delaysContentTouches = YES;
    self.tableView.directionalLockEnabled = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor whiteColor];
}

- (void)addActivityIndicatorToView:(UIView *)view {
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    ai.translatesAutoresizingMaskIntoConstraints = NO;
    ai.hidesWhenStopped = YES;
    [view addSubview:ai];
    
    [view addConstraint:
     [NSLayoutConstraint
      constraintWithItem:ai attribute:NSLayoutAttributeCenterX
      relatedBy:NSLayoutRelationEqual
      toItem:view attribute:NSLayoutAttributeCenterX
      multiplier:1.0f constant:0.0f]];
    
    [view addConstraint:
     [NSLayoutConstraint
      constraintWithItem:ai attribute:NSLayoutAttributeCenterY
      relatedBy:NSLayoutRelationEqual
      toItem:view attribute:NSLayoutAttributeCenterY
      multiplier:1.0f constant:0.0f]];
    
    self.activityIndidcator = ai;
}

- (void)reloadContactsWithCompletionBlock:(void (^)(bool success))block {
    [[[YoUser me] contactsManager] updateContactsWithCompletionBlock:^(bool success)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.friends = [[YoUser me] list];
            [self layoutTableView];
            [self.tableView reloadData];
            if (block) {
                block(success);
            }
        });
    }];
}

- (void)layoutTableView {
    if (self.tableviewContainerHeightConstraint) {
        [self.mainContainer removeConstraint:self.tableviewContainerHeightConstraint];
    }
    
    CGFloat mult = MAX([self minVisibleCellCount], self.friends.count);
    mult = MIN([self maxVisibleCellCount], mult);
    CGFloat offset = [self cellHeight] - self.doneButton.height;
    
    self.tableviewContainerHeightConstraint = [NSLayoutConstraint
                                               constraintWithItem:self.tableviewContainer attribute:NSLayoutAttributeHeight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.doneButton attribute:NSLayoutAttributeHeight
                                               multiplier:mult constant:offset * mult];
    
    [self.mainContainer addConstraint:self.tableviewContainerHeightConstraint];
}

- (UIColor *)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark - Actions

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    CGFloat bottom = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    
    self.mainContainer.top = bottom;
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
        self.mainContainer.bottom = bottom;
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.30f];;
    } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (![[YoApp currentSession] isLoggedIn]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login Required", nil)
                                                                       message:NSLocalizedString(@"Please launch Yo & login", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil).uppercaseString
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self doneButtonPressed:nil];
                                                              }];
        
        [alert addAction:defaultAction];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (IBAction)doneButtonPressed:(id)sender{
    [self close];
}

- (void)close{
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
        self.mainContainer.bottom = self.mainContainer.bottom + self.mainContainer.height;
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];;
    } completion:^(BOOL finished) {
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
}

- (void)tappedHeader:(UITapGestureRecognizer *)tapGR{
    if (self.isBanned) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedString(@"You can't send Yo's. Please contact us yo@justyo.co", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil).uppercaseString
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    else {
        YOCell *statusCell = (YOCell *)tapGR.view;
        [statusCell startActivityIndicator];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self yoAllWithYoAllStatusCell:statusCell];
        });
    }
}

- (NSString *)sendYoTo:(YoModelObject *)object{
    return [self sendYoTo:object withIndexPath:nil];
}

- (NSString *)standardTextLogEvent:(BOOL)logEvent{
    NSString *confirmationText = @"";
    switch (self.shareType) {
        case YoShareType_IMG:
            confirmationText = NSLocalizedString(@"sent yo photo!", nil).capitalizedString;
            break;
            
        case YoShareType_URL:
            confirmationText = NSLocalizedString(@"sent yo link!", nil).capitalizedString;
            break;
            
        default:
            break;
    }
    return confirmationText;
}

- (NSString *)sendYoTo:(YoModelObject *)object withIndexPath:(NSIndexPath *)indexPath{
    NSString *username = object.username;
    
    YOCell *statusCell = (YOCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    NSString *confirmationText = nil;
    NSString *url = self.urlToShare;
    
    confirmationText = [self standardTextLogEvent:YES];
    
    if (![url length]) {
        if (self.shareType == YoShareType_IMG) {
            if (self.delegate) {
                [self.delegate noImgURLFor:object cellAtIndexPath:indexPath];
            }
            return @"NO IMG URL";
        }
        else {
            confirmationText = NSLocalizedString(@"SENT YO!", nil).lowercaseString.capitalizedString;
        }
    }
    
    __weak YoBaseExtensionController *weakSelf = self;
    void (^YoResponseHandler)(NSString *confirmationText) = ^void(NSString *confirmationText) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (statusCell && [[weakSelf.tableView indexPathForCell:statusCell] isEqual:indexPath]) {
                [statusCell endActivityIndicator];
                statusCell.label.text = confirmationText;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (statusCell && [[weakSelf.tableView indexPathForCell:statusCell] isEqual:indexPath]) {
                        [statusCell.label setText:object.displayName];
                    }
                });
            }
        });
    };
    
    if ([self hasInternet]) {
        [[YoManager sharedInstance] yo:object
                     withContextParameters:@{@"link": url}
                     completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                         if (result == YoResultSuccess) {
                             DDLogWarn(@"Successfully sent Yo to %@", username);
                             YoResponseHandler(confirmationText);
                         }
                         else {
                             DDLogError(@"Failed Yo to %@", username);
                             NS_DURING
                             NSString *errorText = responseObject[@"error"][@"message"];
                             if (statusCode == 404)
                                 errorText = NSLocalizedString(@"No Such User", nil);
                             NSString *failedDescription = MakeString(@"%@%@",errorText?@"\n":@"", errorText?:@"");
                             YoResponseHandler(MakeString(NSLocalizedString(@"Failed Yo%@", nil), failedDescription));
                             NS_HANDLER
                             YoResponseHandler(NSLocalizedString(@"Failed Yo", nil));
                             NS_ENDHANDLER
                         }
                         
                     }];
    }
    else {
        confirmationText = NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", @"Failed to send Yo").lowercaseString.capitalizedString;
        YoResponseHandler(confirmationText);
    }
    
    return confirmationText;
}

- (NSString *)shortURLForLongURL:(NSString *)longURL{
    
    if (!longURL) return nil;
    
    NSString *bitlyUsername = @"orarbel";
    NSString *apiKey = @"R_2d8f8096e1f59c06e22b38c5e4a973fc";
    
    NSString *shortURL = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt", bitlyUsername, apiKey, longURL]] encoding:NSUTF8StringEncoding error:nil];
    // urls with # need to be encoded http://dev.bitly.com/links.html
    if (!shortURL || [longURL rangeOfString:@"#"].location != NSNotFound) {
        /*
         NSDictionary *shortURLDictionary = [NSJSONSerialization JSONObjectWithData:[shortURL dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
         if (shortURLDictionary) {
         NSString *hiddenURL = shortURLDictionary[@"data"][@"url"];
         params[@"link"] = hiddenURL;
         }
         else
         */
        shortURL = longURL;
    }
    return shortURL;
}

- (BOOL)hasInternet{
    @autoreleasepool {
        char *hostname;
        struct hostent *hostinfo;
        hostname = "google.com";
        hostinfo = gethostbyname (hostname);
        if (hostinfo == NULL){
            return NO;
        } else {
            return YES;
        }
    }
}

//- (void)presentLocalNotificationWithText:(NSString *)text {
//    UILocalNotification *localNotification = [UILocalNotification new];
//    localNotification.fireDate = [NSDate date];
//    localNotification.timeZone = [NSTimeZone defaultTimeZone];
//    localNotification.alertBody = text;
//    localNotification.userInfo = @{@"action" : @"com.example.yo.YO_FAILED",
//                                   @"aps" :     @{
//                                           @"alert" : text,
//                                           @"sound" : @"yo.mp3",
//                                           },
//                                   @"header" : text,
//                                   };
//    localNotification.soundName = UILocalNotificationDefaultSoundName;
//    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//}

#pragma mark - UITableViewDataSource

- (YOCell *)createCell {
    YOCell *cell = LOAD_NIB(@"YOCell");
    cell.label.text = nil;
    cell.label.font = [UIFont fontWithName:@"Montserrat-Bold" size:38];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YOCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YOCell"];
    if (cell == nil) {
        cell = LOAD_NIB(@"YOCell");
    }
    NSInteger recentsCount = self.friends.count;
    if (recentsCount > 0) {
        cell.yoObject = self.friends[indexPath.row];
    }
    

    cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    cell.label.layer.shadowOffset = CGSizeMake(0, 0.0);
    
    return cell;
}

- (void)colorCell:(YOCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    cell.contentView.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (YOALL_ENABLED && ([self.friends count] >= MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL)) {
        return [self cellHeight];
    }
    return 0.0f;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (!YOALL_ENABLED) return nil;
    
    YOCell *cell =  [self createCell];
    
    cell.label.text = MakeString(@"%@!", NSLocalizedString(@"YO ALL", nil).lowercaseString.capitalizedString);
    //cell.lastYoDate = self.lastYoDates[username];
    cell.shouldShowActivityWhenTapped = YES;
    
    cell.backgroundColor = [UIColor colorWithHexString:AMETHYST];
    cell.label.numberOfLines = 0;
    
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedHeader:)];
    [cell addGestureRecognizer:tapGr];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YOCell *cell = (YOCell *)[tableView cellForRowAtIndexPath:indexPath];
    YoModelObject *object = cell.yoObject;
    if (![cell.label.text length] ||
        [cell.label.text isEqualToString:NSLocalizedString(@"sent yo link!", nil).capitalizedString] ||
        [cell.label.text isEqualToString:NSLocalizedString(@"sent yo photo!", nil).capitalizedString]) return;
    
    if (self.isBanned) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedString(@"You can't send Yo's. Please contact us yo@justyo.co", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil).uppercaseString
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    else {
        [cell startActivityIndicator];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self sendYoTo:object withIndexPath:indexPath];
        });
    }
}

@end
