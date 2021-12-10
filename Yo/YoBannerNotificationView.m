//
//  YoTapNotificationView.m
//  Yo
//
//  Created by Peter Reveles on 1/30/15.
//
//

#import "YoBannerNotificationView.h"
#import "YoNotification.h"

@interface YoBannerNotificationView ()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) YoNotification *notificaiton;
@end

@implementation YoBannerNotificationView

#pragma mark - Life

- (instancetype)initWithNotification:(YoNotification *)notification {
    self = [[[NSBundle mainBundle] loadNibNamed:@"YoBannerNotificationView" owner:self options:nil] objectAtIndex:0];
    if (self) {
        // setup
        _notificaiton = notification;
        [self setupForNotification:notification];
    }
    return self;
}

- (void)setupForNotification:(YoNotification *)notification {
    [self.messageLabel setText:notification.message];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithHexString:PETER];
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapBannerWithTapGR:)];
    [self addGestureRecognizer:tapGR];
    
    self.layer.shadowRadius = 5.0f;
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowColor = [[UIColor colorWithHexString:ASPHALT] CGColor];
}

- (void)userDidTapBannerWithTapGR:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state == UIGestureRecognizerStateEnded) {
        if (self.delegate) {
            [self.delegate userDidTapBannerNotificaitonView:self];
        }
    }
}

- (IBAction)dismissButtonTapped:(UIButton *)sender {
    if (self.delegate) {
        [self.delegate userDidTapDismissButtonForBannerNotificaitonView:self];
    }
}

@end
