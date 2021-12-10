//
//  YoTableViewActionSheet.m
//  Yo
//
//  Created by Peter Reveles on 11/18/14.
//
//

#import "YoThisExtensionController.h"

@interface YoTableViewAction ()

@property(nonatomic, strong) NSString *title;

@property(nonatomic, strong) void (^tapBlock)();

@end

@implementation YoTableViewAction

- (instancetype)initWithTitle:(NSString *)title tapBlock:(void (^)())block{
    self = [super init];
    if (self) {
        _title = title;
        _tapBlock = block;
    }
    return self;
}

@end

@interface YoThisExtensionController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) NSMutableArray *actions;
@end

@implementation YoThisExtensionController

#pragma mark - Lazy Loading

- (NSMutableArray *)actions{
    if (!_actions) {
        _actions = [NSMutableArray new];
    }
    return _actions;
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)showOnView:(UIView *)view{
    //NSAssert([self.actions count] != 0, @"No Actions. Add Actions then show. -(void)addAction");
    [super presentShareSheetOnView:view];
}

- (void)addAction:(YoTableViewAction *)action{
    if (action && action.title && action.tapBlock) {
        [self.actions addObject:action];
        [self updateDataSource:self.actions];
    }
    else
        DDLogWarn(@"Action not added to share sheet. Missing title or tapBlock");
}

#pragma mark - YoTableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    YoTableViewAction *action = (YoTableViewAction *)self.actions[indexPath.row];
    action.tapBlock();
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.actions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YOCell *cell = nil;
    
    // Show list of usernames
    cell = [tableView dequeueReusableCellWithIdentifier:@"YOCell"];
    if (cell == nil) {
        cell = [YoTableViewSheetController createCell];
    }
    
    cell.shouldShowActivityWhenTapped = NO;
    
    NSString *title = [self.actions[indexPath.row] title];
    cell.label.text = title;
    //cell.lastYoDate = self.lastYoDates[username];
    cell.shouldShowActivityWhenTapped = YES;
    
    [self colorCell:cell withIndexPath:indexPath];
    cell.label.numberOfLines = 0;
    return cell;
}

@end
