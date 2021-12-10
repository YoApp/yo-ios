//
//  YoContextPickerController.m
//  Yo
//
//  Created by Or Arbel on 9/30/15.
//
//

#import "YoContextPickerController.h"

@interface YoContextPickerController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray *contexts;
@property(nonatomic, strong) NSMutableArray *selectedContexts;
@end

@implementation YoContextPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedContexts = [NSMutableArray array];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Change Order" style:UIBarButtonItemStylePlain target:self action:@selector(reorderTapped:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneTapped:)];
    
    self.contexts = @[
                      @"location",
                      @"just_yo",
                      @"emoji",
                      @"gif",
                      @"camera"];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}

- (void)reorderTapped:(UIBarButtonItem *)sender {
    [self.tableView setEditing:YES animated:YES];
    sender.title = nil;
}

- (void)doneTapped:(UIBarButtonItem *)sender {
    if (self.tableView.isEditing) {
        self.navigationItem.leftBarButtonItem.title = @"Change Order";
        [self.tableView setEditing:NO animated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contexts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if ( ! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.contexts[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *contextId = [self.contexts objectAtIndex:indexPath.row];
    if ([self.selectedContexts containsObject:contextId]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedContexts removeObject:self.contexts[indexPath.row]];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedContexts addObject:self.contexts[indexPath.row]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

@end
