//
//  YoTableViewSheetController.m
//  Yo
//
//  Created by Peter Reveles on 10/24/14.
//
//

#import "YoTableViewSheetController.h"
#import "YoMainController.h"

@interface YoTableViewSheetController ()
@property (nonatomic, strong) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UIView *tableviewContainer;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableviewContainerHeightConstraint;
@property (nonatomic, weak) UIView *shadeView;

@end

#define CELL_HEIGHT_TO_WIDTH_RATIO 0.278125f

@implementation YoTableViewSheetController

- (int)maxVisibleCellCount{
    if (CGRectGetHeight(([UIScreen mainScreen].bounds)) <= 480.0f)
        return MAX_VISIBLE_CELL_COUNT_iPhone4;
    else return MAX_VISIBLE_CELL_COUNT_iPhone5;
}

- (NSInteger)minVisibleCellCount {
    return 0;
}

#pragma mark - Life Cycle

- (NSArray *)dataSource{
    if (!_dataSource) {
        _dataSource = [NSMutableArray new];
    }
    return _dataSource;
}

- (instancetype)init{
    self = [super initWithNibName:@"YoTableViewSheetController" bundle:nil];
    if (self) {
        [self setupShareController];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.doneButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    
    [self.tableView reloadData];
}

- (void)setupShareController{
    self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:0.0f];
    
    self.tableviewContainer.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    self.tableviewContainer.clipsToBounds = YES;
    self.tableviewContainer.layer.cornerRadius = 5.0f;
    
    self.doneButton.layer.cornerRadius = 5.0f;
    
    self.tableView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor whiteColor];
}

- (void)updateDataSource:(NSArray *)dataSource{
    self.dataSource = dataSource;
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    if (self.tableviewContainerHeightConstraint)
        [self.view removeConstraint:self.tableviewContainerHeightConstraint];
    
    CGFloat mult = MAX([self minVisibleCellCount], [self.dataSource count]);
    mult = MIN([self maxVisibleCellCount], mult);
    CGFloat offset = CELL_HEIGHT - self.doneButton.height;
    
    self.tableviewContainerHeightConstraint = [NSLayoutConstraint
                                               constraintWithItem:self.tableviewContainer attribute:NSLayoutAttributeHeight
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.doneButton attribute:NSLayoutAttributeHeight
                                               multiplier:mult constant:offset * mult];
    
    [self.view addConstraint:self.tableviewContainerHeightConstraint];
}

#pragma mark - Actions

- (void)presentShareSheetOnView:(UIView *)view{
    self.view.frame = view.frame;
    self.view.top = view.bottom;
    
    UIView *shadeView = [UIView new];
    shadeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35f];
    shadeView.alpha = 0.0f;
    shadeView.frame = view.frame;
    
    [view addSubview:shadeView];
    [view addSubview:self.view];
    self.shadeView = shadeView;
    
    if (IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.view.bottom = view.bottom;
            self.shadeView.alpha = 1.0;
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.view.bottom = view.bottom;
            self.shadeView.alpha = 1.0;
        } completion:nil];
    }
    
}

- (void)dissmiss{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(yoTableViewSheetWillDissmiss)]) {
            [self.delegate yoTableViewSheetWillDissmiss];
        }
    }
    [self doneButtonPressed:nil];
}

- (IBAction)doneButtonPressed:(id)sender{
    
    if (self.view.superview == nil) return;
    
    void (^closeBlock)(BOOL finished) = ^void(BOOL finished) {
        [self.view removeFromSuperview];
        [self.shadeView removeFromSuperview];
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(yoTableViewSheetDidDissmiss)]) {
                [self.delegate yoTableViewSheetDidDissmiss];
            }
        }
    };
    
    if (IS_OVER_IOS(7.0)) {
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.view.bottom = self.view.bottom + self.view.height;
            self.shadeView.alpha = 0.0f;
        } completion:closeBlock];
    }
    else {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.view.bottom = self.view.bottom + self.view.height;
            self.shadeView.alpha = 0.0f;
        } completion:closeBlock];
    }
}

#pragma mark - Extern Utility

+ (YOCell *)createCell {
    YOCell *cell = LOAD_NIB(@"YOCell");
    cell.label.text = nil;
    cell.label.font = [UIFont fontWithName:@"Montserrat-Bold" size:38];
    return cell;
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
