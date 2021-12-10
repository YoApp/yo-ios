//
//  YoServiceCell.m
//  Yo
//
//  Created by Or Arbel on 8/30/14.
//
//

#import "YoServiceCell.h"

@implementation YoServiceCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.nameLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:25];
    self.descriptionLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
}

- (void)setService:(NSDictionary *)service {
    _service = service;
    NSString *serviceName = @"";
    if ([[service objectForKey:@"username"] length])
        serviceName = [service objectForKey:@"username"];
    else
        serviceName = [service objectForKey:@"name"];
    self.nameLabel.text = serviceName;
    self.descriptionLabel.text = service[@"sends_yo_when"];
}

- (IBAction)toggleButtonTapped {
    if (self.toggleTappedBlock) {
        self.toggleTappedBlock();
    }
}

- (IBAction)openButtonTapped {
    if (self.openTappedBlock) {
        self.openTappedBlock();
    }
}

- (void)setType:(YoServiceCellType)type{
    switch (type) {
        case YoServiceCellTypeSubcategory:
            [self.toggleSubscribtionButton setImage:[UIImage imageNamed:@"button_newwindow_normal"] forState:UIControlStateNormal];
            [self.toggleSubscribtionButton setImage:[UIImage imageNamed:@"button_newwindow_selected"] forState:UIControlStateSelected];
            break;
            
        case YoServiceCellTypeYoable:
            [self.toggleSubscribtionButton setImage:[UIImage imageNamed:@"button_plus_normal"] forState:UIControlStateNormal];
            [self.toggleSubscribtionButton setImage:[UIImage imageNamed:@"button_plus_active"] forState:UIControlStateSelected];
            break;
            
        default:
            break;
    }
}

@end
