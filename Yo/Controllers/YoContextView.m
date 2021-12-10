//
//  YoContextView.m
//  Yo
//
//  Created by Peter Reveles on 7/28/15.
//
//

#import "YoContextView.h"

@interface YoContextView ()
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@property (nonatomic, strong, readwrite) UIButton *utilityButton;
@property (nonatomic, strong) NSMutableArray *constraints;
@property (nonatomic, assign) BOOL needsSetup;
@end

@implementation YoContextView

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tableView = [[UITableView alloc] init];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        _tableView.rowHeight = 89;
        [self addSubview:_tableView];
    }
    return self;
}

- (void)setContext:(YoContextObject *)context {
    if (_context != context) {
        _context = context;
        self.needsSetup = YES;
    }
}

- (void)setupForContextIfNeeded {
    if (self.needsSetup) {
        self.needsSetup = NO;
        
        YoContextObject *context = self.context;
        [self.backgroundView removeFromSuperview];
        [self.utilityButton removeFromSuperview];
        
        if (context != nil) {
            [self reloadConfiguration];
            
            // background view
            _backgroundView = [context backgroundView];
            if (_backgroundView != nil) {
                _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
                [self insertSubview:_backgroundView belowSubview:_tableView];
            }
            
            // button
            _utilityButton = [context button];
            if (_utilityButton != nil) {
                CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]) * 65.0f/320.0f;
                _utilityButton.frame = CGRectMake(0.0f, 0.0f, width, width);
                _utilityButton.layer.cornerRadius = width/2.0f;
                _utilityButton.left = 20.0f;
                _utilityButton.bottom = CGRectGetHeight([[UIScreen mainScreen] bounds]) - 20.0f;
#warning ToFix - An assumption is being made here about what this context view's frame will be.
                [self addSubview:_utilityButton];
            }
        }
        
        [self invalidateConstraints];
    }
}

- (void)reloadConfiguration {
    UITableViewCellSeparatorStyle cellSeparatorStyle = (self.context != nil)?[self.context cellSeparatorStyle]:UITableViewCellSeparatorStyleNone;
    self.tableView.separatorStyle = cellSeparatorStyle;
}

- (void)invalidateConstraints {
    if (_constraints.count > 0) {
        [_constraints removeAllObjects];
    }
    _constraints = nil;
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    if (_constraints) {
        [super updateConstraints];
        return;
    }
    
    _constraints = [[NSMutableArray alloc] init];
    
    if (self.tableView) {
        NSDictionary *view = NSDictionaryOfVariableBindings(_tableView);
        
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[_tableView]|"
          options:0 metrics:nil views:view]];
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[_tableView]|"
          options:0 metrics:nil views:view]];
    }
    
    if (self.backgroundView) {
        NSDictionary *view = NSDictionaryOfVariableBindings(_backgroundView);
        
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[_backgroundView]|"
          options:0 metrics:nil views:view]];
        [_constraints addObjectsFromArray:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[_backgroundView]|"
          options:0 metrics:nil views:view]];
    }
    
    [self addConstraints:_constraints];
    [super updateConstraints];
}

@end
