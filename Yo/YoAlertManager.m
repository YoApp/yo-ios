//
//  YoAlertView.m
//  Yo
//
//  Created by Peter Reveles on 12/17/14.
//
//

#import "YoAlertManager.h"
#import "YoLabel.h"
#import "YoPopupAlertViewController.h"
#import "YoThemeManager.h"

#define TRANSPARENT_VIEW_COLOR [[UIColor blackColor] colorWithAlphaComponent:0.3f]
#define ALERT_VIEW_WIDTH 300.0f
#define BUTTON_HEIGHT 50.0f
#define MIN_NAVIGATIONBAR_HEIGHT 56.0f
#define NavigationBarHeight BUTTON_HEIGHT
#define PADDING 8.0f

#define MAX_CONTENT_SIZE (CGRectGetHeight([[UIScreen mainScreen] bounds]) - (PADDING * 4) - (BUTTON_HEIGHT * 3)) * 3/4

@interface YoAlertManager () <UIViewControllerTransitioningDelegate>
@property (nonatomic, weak) YoPopupAlertViewController *viewcontroller;

typedef UIView YoAlertView;
@property(nonatomic, weak) YoAlertView *alertView;
@property(nonatomic, strong) NSMutableOrderedSet *alertQueue;

@property(nonatomic, weak) UIView *transperancyViel;
@property(nonatomic, weak) UIImageView *backgroundImageView;
@property(nonatomic, weak) UIScrollView *mainContentScrollView;
@property (strong, nonatomic) NSDictionary *defaultDescriptionTextAttributes;
@property (strong, nonatomic) NSDictionary *defaultTitleTextAttributes;

// gravity
@property (nonatomic, strong) UIDynamicAnimator *animator;
@end

@implementation YoAlertManager

#pragma mark - Lazy Loading

- (NSMutableOrderedSet *)alertQueue {
    if (!_alertQueue) {
        _alertQueue = [NSMutableOrderedSet new];
    }
    return _alertQueue;
} 

#pragma mark - Life

+ (instancetype)sharedInstance {
    static YoAlertManager *sharedInstance = nil;
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [YoAlertManager new];
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // setup
        
    }
    return self;
}

#pragma mark - Internal Utility

- (UIViewController *)topViewController NS_EXTENSION_UNAVAILABLE("App extensions do not hace access to [UIApplication sharedApplication]"){
    UIViewController *topViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

#pragma mark - Extern Utitility

- (void)showAlert:(YoAlert *)alert NS_EXTENSION_UNAVAILABLE("App extensions must explicitly provide the presenting viewcontroller")
{
    [self showAlert:alert completionBlock:nil];
}

- (void)showAlert:(YoAlert *)alert completionBlock:(void (^)(bool finished))block NS_EXTENSION_UNAVAILABLE("App extensions must explicitly provide the presenting viewcontroller") {
    [self showAlert:alert animated:YES completionBlock:block];
}

- (void)showAlert:(YoAlert *)alert
         animated:(BOOL)animated
  completionBlock:(void (^)(bool finished))block NS_EXTENSION_UNAVAILABLE("App extensions must explicitly provide the presenting viewcontroller")
{
    [self showAlert:alert onViewController:[self topViewController] animated:animated completionBlock:block];
}

- (void)showAlert:(YoAlert *)alert
 onViewController:(UIViewController *)presentingViewController
  completionBlock:(void (^)(bool finished))block
{
    [self showAlert:alert onViewController:presentingViewController animated:YES completionBlock:block];
}

- (void)showAlert:(YoAlert *)alert onViewController:(UIViewController *)presentingViewController animated:(BOOL)animated completionBlock:(void (^)(bool finished))block {
    
    if ([self.viewcontroller isEqual:presentingViewController]) {
        UIViewController *parentViewController = self.viewcontroller.presentingViewController;
        YoAlert *currentAlert = [self.alertQueue lastObject];
        
        __weak YoAlertManager *weakSelf = self;
        [self dismissWithCompletionHandler:^{
            [weakSelf showAlert:alert onViewController:parentViewController animated:animated completionBlock:block];
            if (currentAlert != nil) {
                [weakSelf.alertQueue insertObject:currentAlert atIndex:([weakSelf.alertQueue count]-1)];
            }
        }];
        return;
    }
    
    YoPopupAlertViewController *viewcontroller = [YoPopupAlertViewController new];
    self.viewcontroller = viewcontroller;
    
    UIImageView *backgroundImageView = nil;
    UIView *transperencyVeil = nil;
    if (IS_OVER_IOS(8.0)) {
        // prep background
        self.viewcontroller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        // prep transperancy veil
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurredView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurredView.frame = viewcontroller.view.frame;
        blurredView.autoresizingMask = viewcontroller.view.autoresizingMask;
        [viewcontroller.view addSubview:blurredView];
        transperencyVeil = blurredView;
    }
    else {
        // prep background
        UIImage *screenShot = [YoApp takeScreenShot];
        backgroundImageView = [[UIImageView alloc] initWithImage:screenShot];
        backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        backgroundImageView.alpha = 0.0f;
        self.backgroundImageView = backgroundImageView;
        [viewcontroller.view addSubview:backgroundImageView];
        
        // prep transperancy veil
        transperencyVeil = [[UIView alloc] initWithFrame:viewcontroller.view.frame];
        transperencyVeil.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    }
    
    if (transperencyVeil) {
        transperencyVeil.alpha = 0.0f;
        self.transperancyViel = transperencyVeil;
        [viewcontroller.view addSubview:transperencyVeil];
    }
    
    
    // the alert
    UIView *yoAlertView = [self getViewForAlert:alert];
    yoAlertView.alpha = 0.0f;
    self.alertView = yoAlertView;
    [self.alertQueue addObject:alert];
    
    // add alert view
    [self.viewcontroller.view addSubview:yoAlertView];
    CGFloat screenOffSet = 1.0f/2.0f;
    if (IS_OVER_IOS(8.0)) {
        screenOffSet = (1.0f/4.0f);
    }
    else if (IS_OVER_IOS(7.0)) {
        screenOffSet = (3.5f/5.0f);
    }
    yoAlertView.center = CGPointMake(CGRectGetWidth([[UIScreen mainScreen] bounds])/2.0f, CGRectGetHeight([[UIScreen mainScreen] bounds])*screenOffSet);
    
    // layout alert view
    
    NSDictionary *metrics = @{@"width":@(yoAlertView.width), @"height":@(yoAlertView.height)};
    
    NSDictionary *views = NSDictionaryOfVariableBindings(yoAlertView);
    
    [self.viewcontroller.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:[yoAlertView(height)]"
      options:0
      metrics:metrics views:views]];
    
    [self.viewcontroller.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:[yoAlertView(width)]"
      options:0
      metrics:metrics views:views]];
    
    // setting alert location on view
    if (animated && IS_OVER_IOS(7.0)) {
        if (IS_OVER_IOS(8.0)) {
            // dynamics
            self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.viewcontroller.view];
            
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[yoAlertView]];
            gravity.gravityDirection = CGVectorMake(1.0,1.0);
            gravity.magnitude = 3.0f;
            [self.animator addBehavior:gravity];
            
            CGPoint centerScreen = CGPointMake(CGRectGetWidth([[UIScreen mainScreen] bounds])/2.0f, CGRectGetHeight([[UIScreen mainScreen] bounds])/2.0f);
            UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:yoAlertView snapToPoint:centerScreen];
            snapBehavior.damping = 0.5f;
            [self.animator addBehavior:snapBehavior];
        }
        else {
            // dynamics
            self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.viewcontroller.view];
            
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[yoAlertView]];
            gravity.gravityDirection = CGVectorMake(0.0,-1.0);
            gravity.magnitude = 3.0f;
            [self.animator addBehavior:gravity];
            
            UIDynamicItemBehavior *behavior = [[UIDynamicItemBehavior alloc] initWithItems:@[yoAlertView]];
            behavior.allowsRotation = NO;
            [self.animator addBehavior:behavior];
            
            CGPoint centerScreen = CGPointMake(CGRectGetWidth([[UIScreen mainScreen] bounds])/2.0f, CGRectGetHeight([[UIScreen mainScreen] bounds])/2.0f);
            UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:yoAlertView snapToPoint:centerScreen];
            snapBehavior.damping = 0.25f;
            [self.animator addBehavior:snapBehavior];
        }
    }
    else {
        // autolayout
        [self.viewcontroller.view addConstraint:
         [NSLayoutConstraint
          constraintWithItem:yoAlertView attribute:NSLayoutAttributeCenterX
          relatedBy:NSLayoutRelationEqual
          toItem:self.viewcontroller.view attribute:NSLayoutAttributeCenterX
          multiplier:1.0f constant:0.0f]];
        
        [self.viewcontroller.view addConstraint:
         [NSLayoutConstraint
          constraintWithItem:yoAlertView attribute:NSLayoutAttributeCenterY
          relatedBy:NSLayoutRelationEqual
          toItem:self.viewcontroller.view attribute:NSLayoutAttributeCenterY
          multiplier:1.0f constant:0.0f]];
    }
    
    // present
    __weak YoAlertManager *weakSelf = self;
    [presentingViewController presentViewController:viewcontroller animated:NO completion:^{
        backgroundImageView.alpha = 1.0f;
        
        if (animated) {
            yoAlertView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
            
            [UIView animateWithDuration:0.3 animations:^{
                transperencyVeil.alpha = 1.0f;
            }];
            
            // present alert
            [UIView animateWithDuration:0.25 delay:0.05 options:0 animations:^{
                yoAlertView.alpha = 1.0f;
                yoAlertView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                if (weakSelf.mainContentScrollView.contentSize.height > MAX_CONTENT_SIZE) {
                    [weakSelf.mainContentScrollView flashScrollIndicators];
                }
                if (block) {
                    block(YES);
                }
            }];
        }
        else {
            transperencyVeil.alpha = 1.0f;
            yoAlertView.alpha = 1.0f;
            if (weakSelf.mainContentScrollView.contentSize.height > MAX_CONTENT_SIZE) {
                [weakSelf.mainContentScrollView flashScrollIndicators];
            }
            if (block) {
                block(YES);
            }
        }
    }];
}

- (void)dismissAllPopupsWithCompletionHandler:(void (^)())completionHandler {
    if (self.viewcontroller) {
        if ([self.alertQueue count] > 1) {
            [self.alertQueue removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (self.alertQueue.count - 1))]];
        }
        [self dismissWithCompletionHandler:completionHandler];
    }
    else {
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)dismissWithCompletionHandler:(void (^)())handler{
    YoAlert *alert = [self.alertQueue lastObject];
    [self.alertQueue removeObject:alert];
    
    YoAlert *nextAlert = [self.alertQueue lastObject];
    
    __weak YoAlertManager *weakSelf = self;
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        if (nextAlert) {
            [weakSelf.alertView removeFromSuperview];
            weakSelf.alertView = nil;
            [weakSelf showAlert:nextAlert onViewController:weakSelf.viewcontroller completionBlock:nil];
        }
        else {
            [weakSelf.viewcontroller dismissViewControllerAnimated:NO completion:^{
                weakSelf.viewcontroller = nil;
                [weakSelf.animator removeAllBehaviors];
                if (handler) handler();
            }];
        }
    };
    
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.transperancyViel.alpha = 0.0f;
        weakSelf.alertView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
        weakSelf.alertView.alpha = 0.0f;
    } completion:completionBlock];
}

#pragma mark - Utility

- (UIView *)getViewForAlert:(YoAlert *)yoAlert {
    UIView *alertView = [UIView new];
    alertView.translatesAutoresizingMaskIntoConstraints = NO;
    alertView.backgroundColor = [UIColor colorWithHexString:BGCOLOR];
    alertView.layer.cornerRadius = 10.0f;
    alertView.layer.masksToBounds = YES;
    
    // create views
    UIView *navigationComponent = [self getNavigationComponentForAlert:yoAlert];
    navigationComponent.frame = CGRectMake(0.0f,
                                           0.0f,
                                           ALERT_VIEW_WIDTH,
                                           navigationComponent.height);
    
    UIView *messageComponent = [self getContentComponentForAlert:yoAlert];
    messageComponent.frame = CGRectMake(0.0f,
                                        CGRectGetMaxY(navigationComponent.frame),
                                        messageComponent.width,
                                        messageComponent.height);
    
    UIView *actionsComponent = [self getActionsComponentForAlert:yoAlert];
    actionsComponent.frame = CGRectMake(0.0f,
                                        CGRectGetMaxY(messageComponent.frame),
                                        actionsComponent.width,
                                        actionsComponent.height);
    
    CGFloat totalHeightOfContents = navigationComponent.height + messageComponent.height + actionsComponent.height;
    
    alertView.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, totalHeightOfContents);
    
    [alertView addSubview:navigationComponent];
    [alertView addSubview:messageComponent];
    [alertView addSubview:actionsComponent];
    
    return alertView;
}

- (void)dissmissButtonTapped {
    [self dismissWithCompletionHandler:nil];
}

- (UIView *)getNavigationComponentForAlert:(YoAlert *)alert {
    UIView *navigationView = [UIView new];
    navigationView.backgroundColor = [UIColor clearColor];
    
    YoLabel *titleLabel = [YoLabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:22];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.edgeInsets = UIEdgeInsetsMake(0.0f, PADDING, 0.0f, PADDING);
    titleLabel.text = alert.title;
    
    [navigationView addSubview:titleLabel];
    
    UIButton *dissmissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dissmissButton.translatesAutoresizingMaskIntoConstraints = NO;
    [dissmissButton addTarget:self action:@selector(dissmissButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [dissmissButton setImage:[UIImage imageNamed:@"dismiss_image"] forState:UIControlStateNormal];
    [dissmissButton setBackgroundColor:[UIColor clearColor]];
    dissmissButton.showsTouchWhenHighlighted = YES;
    [dissmissButton setImageEdgeInsets:UIEdgeInsetsMake(12.0f, 12.0f, 12.0f, 12.0f)];
    
    [navigationView addSubview:dissmissButton];
    
    if (alert.userActionRequired) {
        dissmissButton.hidden = YES;
    }
    
    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, dissmissButton);
    
    // title label
    [navigationView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[titleLabel]|"
      options:0 metrics:nil views:views]];
    
    [navigationView addConstraint:
     [NSLayoutConstraint
      constraintWithItem:titleLabel attribute:NSLayoutAttributeCenterX
      relatedBy:NSLayoutRelationEqual
      toItem:navigationView attribute:NSLayoutAttributeCenterX
      multiplier:1.0f constant:0.0f]];
    
    // dismiss button
    [navigationView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|-(8)-[dissmissButton(40)]"
      options:0 metrics:nil views:views]];
    
    [navigationView addConstraint:
     [NSLayoutConstraint
      constraintWithItem:dissmissButton attribute:NSLayoutAttributeWidth
      relatedBy:NSLayoutRelationEqual
      toItem:dissmissButton attribute:NSLayoutAttributeHeight
      multiplier:1.0f constant:0.0f]];
    
    // All
    [navigationView addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:[titleLabel]-(>=8)-[dissmissButton]-(5)-|"
      options:0 metrics:nil views:views]];
    
    NSUInteger titleRequiredLines = [self getNumberOfLinesRequiredToDisplayText:alert.title
                                                                 withAttributes:self.defaultTitleTextAttributes
                                                                        inWidth:ALERT_VIEW_WIDTH];
    CGFloat heightPerLine = 22.0f;
    CGFloat titleLabelMinHieghtRequired = titleRequiredLines * heightPerLine + PADDING * 2;
    titleLabelMinHieghtRequired = MAX(titleLabelMinHieghtRequired, MIN_NAVIGATIONBAR_HEIGHT);
    
    navigationView.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, titleLabelMinHieghtRequired);
    
    return navigationView;
}

- (UIView *)getContentComponentForAlert:(YoAlert *)yoAlert {
    
    UIView *contentCompenent = [UIView new];
    contentCompenent.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.14f];
    
    CGFloat heightPerLine = 22.0f;
    
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.scrollEnabled = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = nil;
    CGFloat imagePadding = (PADDING * 8);
    CGFloat imageViewWidth = ALERT_VIEW_WIDTH - imagePadding;
    CGFloat imageViewPerferedHeight = 0.0f;
    if (yoAlert.image) {
        // handle laying out an image image & possibly a desciption
        imageView = [[UIImageView alloc] initWithImage:yoAlert.image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageViewPerferedHeight = imageView.image.size.height * (imageViewWidth / imageView.image.size.width);
        imageViewPerferedHeight += imagePadding/2.0f; // 8 is padding
        [scrollView addSubview:imageView];
    }
    
    YoLabel *descriptionLabel = nil;
    NSAttributedString *attributedDescriptionText = yoAlert.descriptionText;
    if (attributedDescriptionText.length) {
        NSDictionary *currentAttributes = [yoAlert.descriptionText attributesAtIndex:0 effectiveRange:nil];
        if (!currentAttributes.count) {
            NSMutableAttributedString *mutableAttributedDescription = [yoAlert.descriptionText mutableCopy];
            NSRange entireTextRange = NSMakeRange(0, yoAlert.descriptionText.length);
            [mutableAttributedDescription addAttributes:self.defaultDescriptionTextAttributes
                                                  range:entireTextRange];
            attributedDescriptionText = [mutableAttributedDescription copy];
        }
        
        descriptionLabel = [YoLabel new];
        descriptionLabel.attributedText = attributedDescriptionText;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        [descriptionLabel sizeToFit];
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.edgeInsets = UIEdgeInsetsMake(0.0f, PADDING, 0.0f, PADDING);
        [scrollView addSubview:descriptionLabel];
    }
    
    NSDictionary *descriptionAttributes = [attributedDescriptionText attributesAtIndex:0 effectiveRange:nil];
    NSUInteger descriptionRequiredLines = [self getNumberOfLinesRequiredToDisplayText:attributedDescriptionText.string
                                                                       withAttributes:descriptionAttributes
                                                                              inWidth:ALERT_VIEW_WIDTH - (PADDING * 2)];
    
    if (descriptionRequiredLines == 1) descriptionRequiredLines++;
    
    imageView.frame = CGRectMake((imagePadding/2.0f), 0.0f, imageViewWidth, imageViewPerferedHeight);
    
    CGFloat descriptionPadding = PADDING;
    if (IS_OVER_IOS(7.0)) descriptionPadding*=3;
    
    descriptionLabel.frame = CGRectMake(0.0f, imageView.size.height, ALERT_VIEW_WIDTH, descriptionRequiredLines?((descriptionRequiredLines * heightPerLine)+ descriptionPadding):0);
    
    CGFloat mainContentTotalHeight = imageView.height + descriptionLabel.height;
    
    scrollView.contentSize = CGSizeMake(ALERT_VIEW_WIDTH, mainContentTotalHeight);
    
    if (mainContentTotalHeight > MAX_CONTENT_SIZE) {
        scrollView.scrollEnabled = YES;
        scrollView.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, MAX_CONTENT_SIZE);
    }
    else
        scrollView.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, mainContentTotalHeight);
    
    [contentCompenent addSubview:scrollView];
    self.mainContentScrollView = scrollView;
    
    CGFloat totalHeightOfContents =  scrollView.height;
    
    contentCompenent.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, totalHeightOfContents);
    
    return contentCompenent;
}

- (NSUInteger)getNumberOfLinesRequiredToDisplayText:(NSString *)text
                                     withAttributes:(NSDictionary *)attributes
                                            inWidth:(CGFloat)maxWidth
{
    CGSize textDisplaySize = CGSizeZero;
    
    if (!text.length || !maxWidth) {
        return 0.0;
    }
    
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    textDisplaySize = rect.size;
    
    NSUInteger linesRequiredBasedOfTextSize = ceil(textDisplaySize.height/22);
    
    NSUInteger linesRequired = linesRequiredBasedOfTextSize;
    
    return linesRequired;
}

- (NSUInteger)occurencesOfSubStringString:(NSString *)subString inString:(NSString *)string{
    NSUInteger occurences = 0, length = [string length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound)
    {
        range = [string rangeOfString:subString options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            occurences++;
        }
    }
    return occurences;
}

- (UIView *)getActionsComponentForAlert:(YoAlert *)yoAlert {
    UIView *buttonContainer = [UIView new];
    buttonContainer.backgroundColor = [UIColor clearColor];
    
    // CASE 0 - 1 BUTTON
    if ([yoAlert.actions count] == 1) {
        NSInteger buttonIndex = 0;
        UIButton *button = [self createButtonForIndex:buttonIndex];
        button.tag = buttonIndex;
        button.backgroundColor = [UIColor colorWithHexString:EMERALD];
        YoAlertAction *action = yoAlert.actions[buttonIndex];
        [button setTitle:action.title forState:UIControlStateNormal];
        
        [button addTarget:self action:@selector(actionHandlerForButton:) forControlEvents:UIControlEventTouchUpInside];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(button);
        
        [buttonContainer addSubview:button];
        
        [buttonContainer addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[button]|"
          options:0
          metrics:nil views:views]];
        
        [buttonContainer addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[button]|"
          options:0
          metrics:nil views:views]];
    }
    
    // CASE 1 - 2 BUTTONS
    else if ([yoAlert.actions count] == 2) {
        NSInteger buttonIndex = 0;
        UIButton *leftButton = [self createButtonForIndex:buttonIndex];
        leftButton.tag = buttonIndex;
        YoAlertAction *leftAction = yoAlert.actions[buttonIndex];
        [leftButton setTitle:leftAction.title forState:UIControlStateNormal];
        [leftButton addTarget:self action:@selector(actionHandlerForButton:) forControlEvents:UIControlEventTouchUpInside];
        
        buttonIndex++;
        UIButton *rightButton = [self createButtonForIndex:buttonIndex];
        rightButton.tag = buttonIndex;
        YoAlertAction *rightAction = yoAlert.actions[buttonIndex];
        [rightButton setTitle:rightAction.title forState:UIControlStateNormal];
        [rightButton addTarget:self action:@selector(actionHandlerForButton:) forControlEvents:UIControlEventTouchUpInside];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(leftButton, rightButton);
        
        [buttonContainer addSubview:leftButton];
        [buttonContainer addSubview:rightButton];
        
        [buttonContainer addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[leftButton]|"
          options:0
          metrics:nil views:views]];
        
        [buttonContainer addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"H:|[leftButton][rightButton(leftButton)]|"
          options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom
          metrics:nil views:views]];
        
    }
    
    // CASE 2 - N BUTTONS
    else {
        int indexOfAction = 0;
        
        UIView *viewAbove = nil;
        
        for (YoAlertAction *action in yoAlert.actions) {
            UIButton *button = [self createButtonForIndex:indexOfAction];
            button.tag = indexOfAction;
            [button setTitle:action.title forState:UIControlStateNormal];
            [button addTarget:self action:@selector(actionHandlerForButton:) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonContainer addSubview:button];
            
            NSDictionary *views = nil;
            
            if (viewAbove)
                views = NSDictionaryOfVariableBindings(button, viewAbove);
            else
                views = NSDictionaryOfVariableBindings(button);
            
            if (!indexOfAction) {
                // first object
                [buttonContainer addConstraints:
                 [NSLayoutConstraint
                  constraintsWithVisualFormat:@"V:|[button]"
                  options:0
                  metrics:nil views:views]];
            }
            else if (indexOfAction == ([yoAlert.actions count] - 1)) {
                // last object
                [buttonContainer addConstraints:
                 [NSLayoutConstraint
                  constraintsWithVisualFormat:@"V:[viewAbove][button(viewAbove)]|"
                  options:0
                  metrics:nil views:views]];
                
            }
            else {
                // Nth onbect
                [buttonContainer addConstraints:
                 [NSLayoutConstraint
                  constraintsWithVisualFormat:@"V:[viewAbove][button(viewAbove)]"
                  options:0
                  metrics:nil views:views]];
            }
            
            [buttonContainer addConstraints:
             [NSLayoutConstraint
              constraintsWithVisualFormat:@"H:|[button]|"
              options:0
              metrics:nil views:views]];
            
            viewAbove = button;
            
            indexOfAction++;
        }
    }
    
    CGFloat totalButtonHeight = ([yoAlert.actions count] * BUTTON_HEIGHT);
    
    // two buttons display on 1 line
    if ([yoAlert.actions count] == 2)
        totalButtonHeight = BUTTON_HEIGHT;
    
    buttonContainer.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, totalButtonHeight);
    
    return buttonContainer;
}

- (UIButton *)createButtonForIndex:(NSUInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.frame = CGRectMake(0.0f, 0.0f, ALERT_VIEW_WIDTH, BUTTON_HEIGHT);
    button.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:index];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:20];
    button.titleLabel.minimumScaleFactor = 0.1;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 5.0f, 0.0f, 5.0f);
    button.showsTouchWhenHighlighted = YES;
    return button;
}

- (void)actionHandlerForButton:(UIButton *)button{
    YoAlert *alert = [self.alertQueue lastObject];
    YoAlertAction *action = [alert.actions objectAtIndex:button.tag];
    [self dismissWithCompletionHandler:action.tapBlock];
}

#pragma mark - Abstraction

- (void)showAlertWithTitle:(NSString *)title
                      text:(NSString *)text
            yesButtonTitle:(NSString *)yesButtonTitle
             noButtonTitle:(NSString *)noButtonTitle
                  yesBlock:(void (^)(void))yesBlock
{
    YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:title
                                                image:nil
                                           desciption:text];
    
    [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:noButtonTitle
                                                   tapBlock:nil]];
    [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:yesButtonTitle
                                                   tapBlock:yesBlock]];
    
    [[YoAlertManager sharedInstance] showAlert:yoAlert];
}

- (void)showAlertWithTitle:(NSString *)title
{
    [self showAlertWithTitle:title text:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                      text:(NSString *)text
{
    YoAlert *yoAlert = [[YoAlert alloc] initWithTitle:title image:nil desciption:text];
    [yoAlert addAction:[[YoAlertAction alloc] initWithTitle:NSLocalizedString(@"Ok", nil).uppercaseString tapBlock:nil]];
    [[YoAlertManager sharedInstance] showAlert:yoAlert];
}

#pragma mark - Getters

- (NSDictionary *)defaultTitleTextAttributes {
    if (!_defaultTitleTextAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        paragraphStyle.lineSpacing = 1.0;
        NSDictionary *defaultAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Bold" size:22],
                                            NSForegroundColorAttributeName:[UIColor whiteColor],
                                            NSParagraphStyleAttributeName:paragraphStyle};
        _defaultTitleTextAttributes = defaultAttributes;
    }
    return _defaultTitleTextAttributes;
}

- (NSDictionary *)defaultDescriptionTextAttributes {
    if (!_defaultDescriptionTextAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *defaultAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Regular" size:18],
                                            NSForegroundColorAttributeName:[UIColor whiteColor],
                                            NSParagraphStyleAttributeName:paragraphStyle};
        _defaultDescriptionTextAttributes = defaultAttributes;
    }
    return _defaultDescriptionTextAttributes;
}

@end
