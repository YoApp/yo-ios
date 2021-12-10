//
//  YoNameLocationController.m
//  Yo
//
//  Created by Or Arbel on 7/14/15.
//
//

#import "YoNameLocationController.h"
#import "YoObjectCell.h"
#import <Foundation/Foundation.h>
#import "YOLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface YoNameLocationController () <UITextFieldDelegate>

@property(nonatomic, strong) IBOutlet YoLabel *titleLabel;
@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) IBOutlet YoButton *saveButton;
@property(nonatomic, strong) IBOutlet YOTextField *textField;

@property(nonatomic, strong) NSArray *suggestions;

@end

@implementation YoNameLocationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *placeName = [[YoLocationManager sharedInstance] checkForKnownPlaceAtCurrentLocation];
    if (placeName) {
        self.textField.text = placeName;
    }
    
    self.containerView.layer.cornerRadius = 10.0;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    
    self.saveButton.disableRoundedCorners = YES;
    
    self.tableView.separatorColor = [UIColor colorWithHexString:DarkPurple];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor = [UIColor colorWithHexString:DarkPurple];
    self.tableView.layer.masksToBounds = YES;
    
    self.suggestions = @[
                         @"🏠 Home",
                         @"💼 Work",
                         @"💪 Gym",
                         @"📚 School",
                         ];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)saveButtonPressed {
    [[YoLocationManager sharedInstance] savePlaceName:self.textField.text];
    [self close];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - UITableViewDataSource

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 69.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.suggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YoObjectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YoObjectCell"];
    if ( ! cell) {
        cell = LOAD_NIB(@"YoObjectCell");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        cell.iconImageView.image = [UIImage imageNamed:@"inbox_location_icon"];
        cell.timeLabel.hidden = YES;
        cell.label.hidden = YES;
        cell.singleLabel.hidden = NO;
    }
    
    cell.singleLabel.text = self.suggestions[indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.textField.text = self.suggestions[indexPath.row];
    
}

@end
