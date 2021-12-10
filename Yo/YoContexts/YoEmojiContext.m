//
//  YoEmojiContext.m
//  Yo
//
//  Created by Or Arbel on 6/24/15.
//
//

#import "YoEmojiContext.h"

@interface YoEmojiContext ()

@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSArray *emojis;
@property (nonatomic, strong) NSString *emoji;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) UIView *emojiPickerView;

@end

@implementation YoEmojiContext

- (id)init {
    if (self = [super init]) {
        self.labels = [NSMutableArray array];
        
        self.emoji = @"😁";
        
        self.button = [self createButton];
        [self.button setTitle:self.emoji forState:UIControlStateNormal];
        
        self.emojiPickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width
                                                                        , [UIScreen mainScreen].bounds.size.height)];
        self.emojiPickerView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.emojiPickerView.width, 30)];
        title.text = @"Pick emoji";
        title.font = MonsterratBold(17);
        title.textAlignment = NSTextAlignmentCenter;
        title.textColor = [UIColor whiteColor];
        [self.emojiPickerView addSubview:title];
        
        UIButton *button = [self createButton];
        button.left = 20.0;
        button.bottom = self.emojiPickerView.height - 20;
        [self.emojiPickerView addSubview:button];
        
        self.emojis = @[
                        @[@"😜",@"😂",@"😪",@"😘",@"😁"],
                        @[@"👍",@"👎",@"🌹",@"❤️",@"💔"],
                        @[@"🍻",@"☕️",@"🍷",@"🍔",@"🍕"],
                        @[@"💩",@"⚽️",@"🏀",@"✈️",@"🚬"],
                        @[@"❓",@"❗️",@"💋",@"📞",@"💬"],
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

- (UIButton *)createButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"😁" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(presentEmojiPicker) forControlEvents:UIControlEventTouchUpInside];
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
    return [NSString stringWithFormat:@"Yo Emoji %@", self.emoji];
}

- (NSString *)textForStatusBar {
    return @"Tap the emoji to send it";
}

- (NSString *)textForSentYo {
    return MakeString(@"Sent Emoji %@", self.emoji);
}

- (BOOL)isLabelGlowing {
    return YES;
}

- (void)presentEmojiPicker {
    
    if (self.emojiPickerView.superview) {
        [self.emojiPickerView removeFromSuperview];
    }
    else {
        [[[APPDELEGATE topVC] view] addSubview:self.emojiPickerView];
    }
    
}

- (void)emojiSelected:(UIButton *)button {
    NSString *emoji = [button titleForState:UIControlStateNormal];
    self.emoji = emoji;
    self.labelView.text = emoji;
    [self.button setTitle:emoji forState:UIControlStateNormal];
    [self.emojiPickerView removeFromSuperview];
    
    if ([self.labelView.text isEqualToString:@"📞"] && ! [[NSUserDefaults standardUserDefaults] boolForKey:@"showed.phone.warning"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showed.phone.warning"];
        [UIAlertView showWithTitle:nil
                           message:@"Sending 📞 lets the recipient see your phone number"
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:@[]
                          tapBlock:nil];
    }
}

- (UIView *)backgroundView {
    if ( ! self.labelView) {
        self.labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width
                                                              , [UIScreen mainScreen].bounds.size.height)];
        self.labelView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
        
        self.labelView.text = self.emoji;
        self.labelView.textAlignment = NSTextAlignmentCenter;
        self.labelView.font = [UIFont fontWithName:@"AppleColorEmoji" size:105.0];
        [self.labels addObject:self.labelView];
        
    }
    return self.labelView;
    
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    self.emoji = self.labelView.text;
    NSDictionary *extraParameters = @{@"context": self.emoji};
    block(extraParameters, NO);
}

+ (NSString *)contextID {
    return @"emoji";
}

- (NSString *)getFirstTimeYoText {
    return MakeString(@"%@ Yo", self.emoji);
}

@end
