//
//  YoAlert.m
//  Yo
//
//  Created by Peter Reveles on 2/3/15.
//
//

#import "YoAlert.h"

#define MAX_ALLOWED_ACTIONS 4

@interface YoAlert ()
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSAttributedString *descriptionText;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSMutableArray *actions;
@end

@implementation YoAlert

#pragma mark - Lazy Loading

- (NSMutableArray *)actions{
    if (!_actions) {
        _actions = [[NSMutableArray alloc] initWithCapacity:MAX_ALLOWED_ACTIONS];
    }
    return _actions;
}

#pragma mark - Life

- (instancetype)initWithTitle:(NSString *)title
         attributedDesciption:(NSAttributedString *)attributedDesciption
{
    self = [super init];
    if (self) {
        _title = title;
        _descriptionText = attributedDesciption;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                   desciption:(NSString *)description
{
    if (description == nil) {
        description = title;
        title = @"Yo";
    }
    NSAttributedString *attributedDescription = [[NSAttributedString alloc]
                                                 initWithString:description
                                                 attributes:nil];
    self = [self initWithTitle:title attributedDesciption:attributedDescription];
    if (self) {
        // nop
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                        image:(UIImage *)image
                   desciption:(NSString *)description
{
    self = [self initWithTitle:title desciption:description];
    if (self) {
        _image = image;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                        image:(UIImage *)image
         attributedDesciption:(NSAttributedString *)attributedDesciption
{
    self = [self initWithTitle:title attributedDesciption:attributedDesciption];
    if (self) {
        _image = image;
    }
    return self;
}

- (void)addAction:(YoAlertAction *)action
{
    if (action && action.title) {
        if ([self.actions count] < MAX_ALLOWED_ACTIONS) {
            [self.actions addObject:action];
        }
        else
            DDLogWarn(@"Exceed MAX Allowed number of actions per alert view");
        
    }
    else
        DDLogWarn(@"Action not added to share sheet.");
}

@end
