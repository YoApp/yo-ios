//
//  YoGroupMememberDisplayCollectionViewCell.m
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import "YoGroupMememberDisplayCell.h"
#import "YoContact.h"

@interface YoGroupMememberDisplayCell ()
@property (weak, nonatomic) IBOutlet UILabel *label;
@end

@implementation YoGroupMememberDisplayCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _label.text = nil;
}

#pragma mark - Public Utility

- (void)displayContact:(YoContact *)contact {
    _label.text = [self getContactInitials:contact];
}

- (NSString *)getContactInitials:(YoContact *)contact {
    NSString *initials = @"";
    
    NSString *name = contact.fullName.length > 0 ? contact.fullName : contact.username;
    
    NSArray *nameComponents = [name componentsSeparatedByString:@" "];

    if (nameComponents.count > 1) {
        for (NSString *nameComponent in nameComponents) {
            if (nameComponent.length) {
                initials = [initials stringByAppendingString:[nameComponent substringToIndex:1]];
            }
        }
    }
    else {
        for (NSInteger indexInName = 0;
             (indexInName < 2 &&
              indexInName < name.length);
             indexInName++) {
            initials = [initials stringByAppendingString:[name substringToIndex:1]];
        }
    }
    return initials;
}

@end
