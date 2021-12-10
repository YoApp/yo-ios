//
//  YoContextPlusEmoji.m
//  Yo
//
//  Created by Peter Reveles on 8/13/15.
//
//

#import "YoContextPlusEmoji.h"
#import "YoPermissionsInstructionView.h"

#define JustYoEmojiSignifier @"Yo"

@interface YoContextPlusEmoji ()
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSArray *emojis;
@property (nonatomic, strong) NSString *selectedEmoji;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) UIView *emojiPickerView;
@property (nonatomic, strong) NSString *lastPreparedYoEmoji;
@end

@implementation YoContextPlusEmoji

- (instancetype)init {
    if (self = [super init]) {
        self.labels = [[NSMutableArray alloc] init];
        
        self.selectedEmoji = JustYoEmojiSignifier;
        
        self.button = [self newButton];
        [self.button addTarget:self action:@selector(toggleEmojiPickerViewIsPresent) forControlEvents:UIControlEventTouchUpInside];
        [self.button setTitle:self.selectedEmoji forState:UIControlStateNormal];
        
        self.emojiPickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width
                                                                        , [UIScreen mainScreen].bounds.size.height)];
        self.emojiPickerView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.emojiPickerView.width, 30)];
        title.text = @"Pick";
        title.font = MonsterratBold(22);
        title.textAlignment = NSTextAlignmentCenter;
        title.textColor = [UIColor whiteColor];
        [self.emojiPickerView addSubview:title];
        
        UIButton *button = [self newButton];
        [button addTarget:self action:@selector(toggleEmojiPickerViewIsPresent) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        button.titleLabel.font = MonsterratBold(19);
        button.width = button.height * 2;
        button.bottom = self.emojiPickerView.height - 20;
        button.center = CGPointMake(self.emojiPickerView.center.x, button.center.y);
        [self.emojiPickerView addSubview:button];
        
        self.emojis = @[
                        @[@"Yo",@"😜",@"😂",@"😪",@"😁"],
                        @[@"😘",@"🌹",@"❤️",@"💔",@"💋"],
                        @[@"👍",@"👎",@"💩",@"⚽️",@"🏀"],
                        @[@"🍻",@"☕️",@"🍷",@"🍔",@"🍕"],
                        @[@"❓",@"🚬",@"❗️",@"📞",@"💬"],
                        ];
        
        NSInteger numOfRows = [self.emojis count];
        NSInteger numOfCols = [self.emojis[0] count];
        CGFloat rowHeight = (self.emojiPickerView.height - 70 - 50) / numOfRows;
        CGFloat colWidth = self.emojiPickerView.width / numOfCols;
        
        CGFloat yOffset = 50.0;
        for (int i = 0 ; i < numOfRows ; i++) {
            for (int j = 0; j < numOfCols ; j++) {
                UIButton *label = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, colWidth, rowHeight)];
                label.left = colWidth * j;
                label.top = (rowHeight * i) + yOffset;
                [label setTitle:self.emojis[i][j] forState:UIControlStateNormal];
                label.titleLabel.textAlignment = NSTextAlignmentCenter;
                label.titleLabel.font = [UIFont fontWithName:@"AppleColorEmoji" size:55.0];
                label.showsTouchWhenHighlighted = YES;
                [label addTarget:self action:@selector(emojiSelected:) forControlEvents:UIControlEventTouchUpInside];
                [self.emojiPickerView addSubview:label];
                [self.labels addObject:label];
            }
        }
        
    }
    return self;
}

- (UIButton *)newButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 65, 65);
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    button.layer.cornerRadius = button.width / 2.0;
    button.layer.masksToBounds = YES;
    button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    button.layer.shadowRadius = 3.0f;
    button.layer.shadowOpacity = 0.5f;
    return button;
}

- (NSString *)textForTitleBar {
    return self.selectedEmoji;
}

- (NSString *)textForStatusBar {
    return @"Tap name to send a Yo";
}

- (NSString *)textForSentYo {
    return MakeString(@"Sent %@!", self.lastPreparedYoEmoji);
}

- (UIView *)backgroundView {
    if (self.labelView == nil) {
        self.labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width
                                                                   , [UIScreen mainScreen].bounds.size.height)];
        self.labelView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        self.labelView.textAlignment = NSTextAlignmentCenter;
        self.labelView.font = [UIFont fontWithName:@"AppleColorEmoji" size:105.0];
        [self.labels addObject:self.labelView];
        [self updateBackgroundView];
        
    }
    return self.labelView;
    
}

- (void)updateEmojiSepecificViews {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBackgroundView];
        [self updateButton];
        [[NSNotificationCenter defaultCenter] postNotificationName:YoNotificationContextDidUpdateConfiguration object:self];
    });
}

- (void)updateBackgroundView {
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier]) {
        self.labelView.text = nil;
    }
    else {
        self.labelView.text = self.selectedEmoji;
    }
}

- (void)updateButton {
    [self.button setTitle:self.selectedEmoji forState:UIControlStateNormal];
}

- (BOOL)isTableViewTransparent {
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier]) {
        return NO;
    }
    return YES;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier]) {
        return UITableViewCellSeparatorStyleNone;
    }
    return UITableViewCellSeparatorStyleSingleLine;
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    self.lastPreparedYoEmoji = self.selectedEmoji;
    NSDictionary *parameters = @{};
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier] == NO) {
        parameters = @{@"context": self.selectedEmoji};
    }
    block(parameters, NO);
}

- (UIView *)permissionsBanner {
    YoPermissionsInstructionView *permissionsView = LOAD_NIB(@"YoPermissionsInstructionView");
    permissionsView.instructionImageView.image = [UIImage imageNamed:YoInstructionImagePushNotifications];
    BOOL canOpenYoAppSettings = NO;
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        canOpenYoAppSettings = YES;
    }
    NSString *instructionsText = @"Receive Yos from your friends by enabling push notification in the Settings App.";
    if (canOpenYoAppSettings) {
        [permissionsView.actionButton setTitle:NSLocalizedString(@"Tap to Open Settings", nil)
                                      forState:UIControlStateNormal];
        [permissionsView.actionButton addTarget:self action:@selector(didTapPermissionsBanner:)
                               forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [permissionsView.actionButton removeFromSuperview];
    }
    permissionsView.textLabel.text = instructionsText;
    [permissionsView.textLabel sizeToFit];
    CGFloat padding = 24.0f + 10.0f + (14.0f * 2);
    if (CGRectGetHeight([[UIScreen mainScreen] bounds]) < 667.0f) {
        padding+=24.0f;
    }
    CGFloat shouldBeHeight = permissionsView.textLabel.height + permissionsView.settingsAppIconImageView.height + permissionsView.instructionImageView.height + padding;
    if (canOpenYoAppSettings) {
        shouldBeHeight += permissionsView.actionButton.height + 14.0f;
    }
    permissionsView.height = shouldBeHeight;
    return permissionsView;
}

- (void)didTapPermissionsBanner:(id)sender {
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else {
        DDLogWarn(@"Error: Attempted to open settings when opening settings is unavailble");
    }
}

- (BOOL)shouldShowPermissionsBanner {
    return NO; // @or: app can work without push, using the inbox
}

+ (NSString *)contextID
{
    return @"yo_plus_emoji";
}

- (NSString *)getFirstTimeYoText {
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier]) {
        return @"Yo";
    }
    
    return MakeString(@"%@ Yo", self.selectedEmoji);
}

- (BOOL)isLabelGlowing {
    if ([self.selectedEmoji isEqualToString:JustYoEmojiSignifier]) {
        return NO;
    }
    return YES;
}

- (void)toggleEmojiPickerViewIsPresent {
    if (self.emojiPickerView.superview) {
        [self.emojiPickerView removeFromSuperview];
    }
    else {
        [[[APPDELEGATE topVC] view] addSubview:self.emojiPickerView];
    }
}

- (void)emojiSelected:(UIButton *)button {
    NSString *emoji = [button titleForState:UIControlStateNormal];
    
    self.selectedEmoji = emoji;
    
    [self updateEmojiSepecificViews];
    
    [self.emojiPickerView removeFromSuperview];
    
    if ([emoji isEqualToString:@"📞"] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:@"showed.phone.warning"] == NO) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showed.phone.warning"];
        [UIAlertView showWithTitle:nil
                           message:@"Sending 📞 lets the recipient see your phone number"
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:@[]
                          tapBlock:nil];
    }
}

@end
