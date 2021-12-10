//
//  YoMapController.m
//  Yo
//
//  Created by Or Arbel on 9/13/14.
//
//

#import "YoMapController.h"
#import "YoManager.h"
#import "YoBannerNotificationPresentationManager.h"
#import "YOLocationManager.h"
#import "YOEnableLocationController.h"
#import "YoNotification.h"
#import "NSDate_Extentions.h"
#import "YoInbox.h"

#define kShadowColor1		[UIColor blackColor]
#define kShadowColor2		[UIColor colorWithWhite:0.0 alpha:0.75]
#define kShadowOffset		CGSizeMake(0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4.0 : 2.0)
#define kShadowBlur			(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 10.0 : 5.0)
#define kInnerShadowOffset	CGSizeMake(0.0, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.0 : 1.0)
#define kInnerShadowBlur	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4.0 : 2.0)

@interface YoMapController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *yoBackActivityIndicator;

@end

@implementation YoMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL shouldDisplayUserLocation = NO;
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        shouldDisplayUserLocation = YES;
    }
    
    self.mapView.showsUserLocation = shouldDisplayUserLocation;
    
    [self.profileImageView setImageWithURL:self.yo.senderObject.photoURL];
    self.fullNameLabel.text = [self.yo.senderObject displayName];
    
    self.usernameLabel.text = [self.yo.creationDate agoString];
    
    self.topLabel.font = [UIFont fontWithName:@"Montserrat-Bold" size:28];
    self.topLabel.shadowColor = kShadowColor1;
    self.topLabel.shadowOffset = kShadowOffset;
    self.topLabel.shadowBlur = kShadowBlur;
    self.topLabel.text = self.yo.text;
    self.topLabel.alpha = self.topLabel.text?1.0f:0.0f;
    
    [self.rightButton setTitle:NSLocalizedString(@"yo back 📍", nil).capitalizedString forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedString(@"MAPS", nil).lowercaseString.capitalizedString  forState:UIControlStateNormal];
    
    if (self.yo.location) {
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.yo.location.coordinate, 800, 800);
        
        [self.mapView setRegion:region];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:self.yo.location.coordinate];
        if (self.yo.isGroupYo) {
            [annotation setTitle:MakeString(@"%@ to %@", self.yo.senderObject.displayName, self.yo.groupName)];
        }
        else {
            [annotation setTitle:MakeString(@"%@", self.yo.senderObject.displayName)];
        }
        [self.mapView addAnnotation:annotation];
        [self.mapView selectAnnotation:annotation animated:YES];
        
        
        /*MKPointAnnotation *meAnnotation = [[MKPointAnnotation alloc] init];
         [meAnnotation setCoordinate:self.yo.location.coordinate];
         [meAnnotation setTitle:@"Me"];
         
         [self.mapView showAnnotations:@[meAnnotation, annotation] animated:YES];*/
    }
    
    [self applyCustomActionsIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.yo) {
        [[YoUser me].yoInbox updateOrAddYo:self.yo withStatus:YoStatusRead];
    }
}

- (UIColor *)transparentBackgroundColor {
    return [UIColor clearColor];
}

- (NSDictionary *)extraParameters {
    CLLocationCoordinate2D coordinate = self.mapView.userLocation.location.coordinate;
    NSDictionary *extraParameters = @{@"location": MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude)};
    return extraParameters;
}

- (IBAction)closeButtonPressed {
    [self closeWithCompletionBlock:nil];
}

- (IBAction)rightButtonPressed:(UIButton *)sender {
    
    if (self.isCustomReplies) {
        [super rightButtonPressed:sender];
    }
    else {
        
        // @or: TODO check if not determined as well not just denied (if user was not asked yet)
        if ([[YoLocationManager sharedInstance] locationServicesDenied]) {
            YOEnableLocationController *vc = [YOEnableLocationController new];
            [self.yoBackActivityIndicator stopAnimating];
            [sender setTitle:NSLocalizedString(@"yo back 📍", nil).capitalizedString forState:UIControlStateNormal];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else {
            // yo back
            
            [self showActivityOnView:sender];
            
            [sender setTitle:@"Sent Yo 📍" forState:UIControlStateNormal];
            [sender.titleLabel removeFromSuperview];
            
            CLLocationCoordinate2D coordinate = self.mapView.userLocation.location.coordinate;
            NSDictionary *extraParameters = @{@"location": MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude), @"reply_to": self.yo.yoID};
            
            [[YoManager sharedInstance] yo:self.yo.senderUsername
                         contextParameters:extraParameters
                         completionHandler:^(YoResult result, NSInteger statusCode, id responseObject) {
                             if (result == YoResultSuccess) {
                                 
                                 [self removeActivityFromView:sender];
                                 [sender addSubview:sender.titleLabel];
                                 
                                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                     [self close];
                                 });
                             }
                             else {
                                 [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed"];
                             }
                         }];
            
            [YoAnalytics logEvent:YoEventSentYoLocation withParameters:@{YoParam_USERNAME:self.yo.senderUsername?:@"no_username"}];
        }
    }
}

- (IBAction)leftButtonPressed:(UIButton *)sender {
    
    if (self.isCustomReplies) {
        [super leftButtonPressed:sender];
    }
    else {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.yo.location.coordinate
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        if (self.yo.isGroupYo) {
            [mapItem setName:MakeString(@"%@ to %@", self.yo.senderObject.displayName, self.yo.groupName)];
        }
        else {
            [mapItem setName:MakeString(@"%@", self.yo.senderObject.displayName)];
        }
        
        
        [self closeWithCompletionBlock:^{
            [mapItem openInMapsWithLaunchOptions:nil];
        }];
        
        [YoAnalytics logEvent:YoEventTappedMapButton withParameters:@{YoParam_USERNAME:self.yo.senderUsername?:@"no_username"}];
    }
}

#pragma mark - YoBaseViewController

- (BOOL)areNotificationAllowed {
    return NO;
}

@end
