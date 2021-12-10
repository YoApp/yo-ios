//
//  YoMenuCellTableViewCell.m
//  Yo
//
//  Created by Or Arbel on 5/15/15.
//
//

#import "YoMenuCell.h"

@interface YoMenuCell ()
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai;
@end

@implementation YoMenuCell


#pragma mark Setters

- (void)setMenuTitle:(NSString *)menuTitle {
    _menuTitle = menuTitle;
    self.titleLabel.text = menuTitle;
}

#pragma mark External

- (void)startActivityIndicator {
    [self.ai startAnimating];
}

- (void)endActivityIndicator {
    [self.ai stopAnimating];
}

@end
