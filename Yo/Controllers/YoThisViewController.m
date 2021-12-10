//
//  YoThisControllerViewController.m
//  Yo
//
//  Created by Peter Reveles on 11/18/14.
//
//

#import "YoThisViewController.h"
#import "YoMainController.h"
#import "YoManager.h"
#import "YoContactManager.h"
#import "YOHeaderFooterCell.h"
#import "Yo.h"

#define HEADER_CELL_ID @"HEADER_CELL_ID"

@interface YoThisViewController () <UITableViewDelegate, UITableViewDataSource, YoTableViewSheetDelegate>
@property(nonatomic, assign) BOOL isBanned;
@property(nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) Yo *yoToForward;

@end

@implementation YoThisViewController

#pragma mark - Vitual Methods

//- (int)maxVisibleCellCount {
//    int count = MAX_VISIBLE_CELL_COUNT_iPhone5;
//    if (CGRectGetHeight(([UIScreen mainScreen].bounds)) <= 480.0f) {
//        return MAX_VISIBLE_CELL_COUNT_iPhone4;
//    }
//    if ([self.friends count] >= MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL) {
//        count++;
//    }
//    return count;
//}

- (NSInteger)minVisibleCellCount {
    NSInteger min = self.friends.count;
    if (min >= MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL) {
        min++;
    }
    return min;
}

#pragma mark - Life

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    
    self.friends = [[[YoUser me] contactsManager] list];
    [self updateDataSource:self.friends];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerClass:[YOHeaderFooterCell class] forHeaderFooterViewReuseIdentifier:HEADER_CELL_ID];
}

- (void)presentShareSheetOnView:(UIView *)view toForwardYo:(Yo *)yo {
    if ( ! [self.friends count]) {
        [self displayNoContactsAlert];
        return;
    }
    self.yoToForward = yo;
    self.url = nil;
    [super presentShareSheetOnView:view];
}

- (void)presentShareSheetOnView:(UIView *)view toShare:(NSURL *)url {
    if ( ! [self.friends count]) {
        [self displayNoContactsAlert];
        return;
    }
    self.url = url.absoluteString;
    self.yoToForward = nil;
    [super presentShareSheetOnView:view];
}

- (void)displayNoContactsAlert {
    [[YoAlertManager sharedInstance] showAlertWithTitle:NSLocalizedString(@"No Contacts!", nil) text:NSLocalizedString(@"No contacts were found.", nil)];
}

#pragma mark - Actions

- (void)tappedHeader:(UITapGestureRecognizer *)tapGR{
    
    YOCell *statusCell = (YOCell *)tapGR.view;
    
    NSString *confirmationText = NSLocalizedString(@"Sent Yo All!", nil).capitalizedString;
    
    if (statusCell.shouldShowActivityWhenTapped) {
        statusCell.label.hidden = YES;
        [statusCell.aiView startAnimating];
        statusCell.aiView.hidden = NO;
        statusCell.progressView.hidden = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [statusCell.aiView stopAnimating];
            statusCell.label.hidden = NO;
            statusCell.label.text = confirmationText;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                statusCell.label.text = MakeString(@"%@!", NSLocalizedString(@"YO ALL", nil).capitalizedString);
            });
        });
    }
}

/** if username is nil will attempt to pull name from cell. Returns appropriate confirmation text. */
- (NSString *)sendYoTo:(YoModelObject *)object {
    
    NSString *confirmationText = NSLocalizedString(@"sent yo link!", nil).capitalizedString;
    
    if ([APPDELEGATE hasInternet]) {
        if (self.yoToForward.originYoID) {
            [[YoManager sharedInstance] yo:object
                         withContextParameters:@{@"yo_id": self.yoToForward.originYoID}
                         completionHandler:nil];
        }
        else if ([self.url length]) {
            [[YoManager sharedInstance] yo:object
                         withContextParameters:@{@"link": self.url}
                         completionHandler:nil];
        }
        else {
            confirmationText = NSLocalizedString(@"SENT YO!", nil).lowercaseString.capitalizedString;
            [[YoManager sharedInstance] yo:object
                                       withContextParameters:@{}
                                       completionHandler:nil];
        }
        
        if (self.yoToForward.payload) {
            [YoAnalytics logEvent:YoEventForwardedYo withParameters:@{YoParam_Yo_PAYLOAD:self.yoToForward.payload}];
        }
        else {
//            [YoAnalytics logEvent:YoEventSentYo withParameters:@{YoParam_LINK:self.url?:@"no_url", YoParam_USERNAME:username?:@"no_username"}];
        }
    }
    else
        confirmationText = NSLocalizedString(@"FAILED! DO YOU HAVE INTERNET?", @"Failed to send Yo").lowercaseString.capitalizedString;
    
    return confirmationText;
}

#pragma mark - YoTableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return CELL_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (!YOALL_ENABLED) return nil;
    
    YOCell *cell =  [YoTableViewSheetController createCell];
    
    cell.label.text = MakeString(@"%@!", NSLocalizedString(@"YO ALL", nil).lowercaseString.capitalizedString);
    //cell.lastYoDate = self.lastYoDates[username];
    cell.shouldShowActivityWhenTapped = YES;
    
    cell.backgroundColor = [UIColor colorWithHexString:AMETHYST];
    cell.label.numberOfLines = 0;
    
    UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedHeader:)];
    [cell addGestureRecognizer:tapGr];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    YOCell *cell = (YOCell *)[tableView cellForRowAtIndexPath:indexPath];

    YoUser *user = self.friends[indexPath.row];
    
    if (![cell.label.text length] || [cell.label.text isEqualToString:NSLocalizedString(@"sent yo link!", nil).lowercaseString.capitalizedString]) return;
    
    if (self.isBanned) {
        YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:@"Yo"
                                               desciption:NSLocalizedString(@"You can't send Yo's. Please contact us yo@justyo.co", nil)];
        [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"OK", nil).uppercaseString tapBlock:nil]];
        [[YoAlertManager sharedInstance] showAlert:yoAlert];
        return;
    }
    
    
    __weak YoThisViewController *_weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *confirmationText = [_weakSelf sendYoTo:user];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cell.shouldShowActivityWhenTapped) {
                cell.label.hidden = YES;
                [cell.aiView startAnimating];
                cell.aiView.hidden = NO;
                cell.progressView.hidden = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (cell && [[_weakSelf.tableView indexPathForCell:cell] isEqual:indexPath]) {
                        [cell.aiView stopAnimating];
                        cell.label.hidden = NO;
                        cell.label.text = confirmationText;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (cell && [[_weakSelf.tableView indexPathForCell:cell] isEqual:indexPath]) {
                                cell.label.text = user.displayName;
                            }
                        });
                    }
                });
            }
        });
    });
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YOCell *cell = nil;
    
    // Show list of usernames
    cell = [tableView dequeueReusableCellWithIdentifier:@"YOCell"];
    if (cell == nil) {
        cell = [YoTableViewSheetController createCell];
    }
    
    cell.shouldShowActivityWhenTapped = NO;
    
    YoUser *user = self.friends[indexPath.row];
    cell.label.text = [user displayName];
    //cell.lastYoDate = self.lastYoDates[username];
    cell.shouldShowActivityWhenTapped = YES;
    
    [self colorCell:cell withIndexPath:indexPath];
    cell.label.numberOfLines = 0;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (YOALL_ENABLED && ([self.friends count] >= MINMUM_NUMBER_OF_FRIENDS_REQUIRED_TO_DIPLAY_YO_ALL)) {
        return CELL_HEIGHT;
    }
    return 0.0f;
}

#define YoTableViewSheetDelegate

- (void)yoTableViewSheetWillDissmiss {
    self.url = nil;
    self.yoToForward = nil;
}

@end
