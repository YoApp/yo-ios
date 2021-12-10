//
//  YOTextField.m
//  Yo
//
//  Created by Or Arbel on 6/12/14.
//
//

#import "YOTextField.h"

#define BlankUIColor [[UIColor whiteColor] colorWithAlphaComponent:0.14]
#define NotBlankUIColor [UIColor whiteColor]

@implementation YOTextField

- (instancetype)init {
    self = [super init];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self performInitialSetup];
    }
    return self;
}

- (void)performInitialSetup {
    self.tintColor = [UIColor colorWithHexString:WISTERIA];
    self.layer.cornerRadius = 3.0f;
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
}

#pragma mark - UITextField

- (NSString *)text {
    return self.attributedText.string;
}

- (void)setText:(NSString *)text {
    if (!text.length) {
        self.attributedText = nil;
    }
    else {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(-1.3)
                                 range:NSMakeRange(0, [text length])];
        
        self.attributedText = attributedString;
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    if (placeholder == nil) {
        self.attributedPlaceholder = nil;
    }
    else {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:placeholder];
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(-1.3)
                                 range:NSMakeRange(0, [placeholder length])];
        
        self.attributedPlaceholder = attributedString;
    }
}

- (NSString *)placeholder {
    return self.attributedPlaceholder.string;
}

@end
