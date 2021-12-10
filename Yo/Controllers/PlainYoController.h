//
//  PlainYoController.h
//  Yo
//
//  Created by Or Arbel on 6/3/15.
//
//

#import "YoBaseViewController.h"
#import "Yo.h"
#import "YoPresentorController.h"

@interface PlainYoController : YoPresentorController

@property(nonatomic, strong) IBOutlet UILabel *label;
@property(nonatomic, strong) IBOutlet UIImageView *yoIcon;

@end
