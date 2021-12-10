//
//  YoMapContext.m
//  Yo
//
//  Created by Or Arbel on 5/16/15.
//
//

#import "YoMapContext.h"
#import "YoLocationManager.h"
#import <MapKit/MapKit.h>
#import "YoPermissionsInstructionView.h"
#import "YOLocationManager.h"
#import "YoNameLocationController.h"

@interface YoMapContext () <MKMapViewDelegate>
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) NSString *placeName;
@end

@implementation YoMapContext

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationServicesAuthorized:) name:YoNotificaitonLocationServicesAuthorizied object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:YoAppDidUpdateUsersLocation
                                                          object:[YoApp currentSession]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note)
         {
             self.mapView.showsUserLocation = YES;
             [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
         }];
        
        CGRect aproxFrame = [[UIScreen mainScreen] bounds];
        self.mapView = [[MKMapView alloc] initWithFrame:aproxFrame];
        self.mapView.delegate = self;
        if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
            self.mapView.showsUserLocation = YES;
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
        }
        self.mapView.scrollEnabled = NO;
        self.mapView.zoomEnabled = NO;
        self.mapView.userInteractionEnabled = NO;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"📍" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0, 0, 50, 50);
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        button.layer.cornerRadius = button.width / 2.0;
        button.layer.masksToBounds = YES;
        button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        button.layer.shadowRadius = 3.0f;
        button.layer.shadowOpacity = 0.5f;
        self.button = button;
        
    }
    return self;
}

- (void)buttonPressed {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    YoNameLocationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YoNameLocationControllerID"];
    [[APPDELEGATE mainController] presentController:vc];
}

- (void)appDidBecomeActive {
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        
        [[YoLocationManager sharedInstance] requestLocationWithDesiredAccuracy:YoLocationAccuracyHouse
                                                                       timeout:60.0
                                                               completionBlock:^(CLLocation *currentLocation, YoLocationAccuracy achievedAccuracy, YoLocationStatus status) {
            
            [self checkForKnownPlace];
            
        }];
    }
    [self checkForKnownPlace];
}

- (NSString *)textForTitleBar {
    return @"Yo Location 📍";
}

- (NSString *)textForStatusBar {
    return @"Tap name to send a Yo location 📍";
}

- (NSString *)textForSentYo {
    return @"Sent Yo 📍";
    
}
- (UIView *)backgroundView {
    return self.mapView;
}

- (UITableViewCellSeparatorStyle)cellSeparatorStyle {
    return UITableViewCellSeparatorStyleSingleLine;
}

- (void)contextDidDisappear {
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone]; // stop following the user
}

- (void)contextDidAppear {
    __weak YoMapContext *weakSelf = self;
    void (^displayUserLocationOnMap)() = ^(){
        weakSelf.mapView.showsUserLocation = YES;
        [weakSelf.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
    };
    
    if ([YoApp currentSession].lastKnownLocation != nil) {
        
    };
    if ([[YoLocationManager sharedInstance] locationServicesAuthorized]) {
        displayUserLocationOnMap();
        //[[YoApp currentSession] updateCurrentLocationWithCompletionBlock:nil];
    }
    else {
#warning TODO Ask app to get users location. Store it. Then show it on the map
    }
    
    [self checkForKnownPlace];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [YoLocationManager sharedInstance].cachedLocation = self.mapView.userLocation.location;
    [self checkForKnownPlace];
}

- (void)checkForKnownPlace {
    NSString *placeName = [[YoLocationManager sharedInstance] checkForKnownPlaceAtLocation:self.mapView.userLocation.location];
    if (placeName.length > 0) {
        NSArray *components = [placeName componentsSeparatedByString:@" "];
        NSString *firstWord = components[0];
        __block NSInteger length = 0;
        [firstWord enumerateSubstringsInRange:NSMakeRange(0, firstWord.length)
                                      options:NSStringEnumerationByComposedCharacterSequences
                                   usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                       length++;
                                   }];
        if ([firstWord length] == 2 && length == 1) { // @or: place name is an emoji
            [self.button setTitle:[firstWord substringToIndex:2] forState:UIControlStateNormal];
        }
        else { // @or: show only first charachter
            [self.button setTitle:[firstWord substringToIndex:1] forState:UIControlStateNormal];
        }
        self.placeName = placeName;
    }
    else {
        [self.button setTitle:@"📍" forState:UIControlStateNormal];
        self.placeName = nil;
    }
}

#pragma mark - Map

- (void)locationServicesAuthorized:(NSNotification *)note {
    //[self updateMapTracking];
}

- (void)prepareContextParametersWithCompletionBlock:(PrepareContextParametersCompletionBlock)block {
    CLLocationCoordinate2D coordinate = self.mapView.userLocation.location.coordinate;
    if (coordinate.longitude == 0.0 && coordinate.latitude == 0.0) {
        [[YoAlertManager sharedInstance] showAlertWithTitle:@"Failed to get your location 😔"];
        return;
    }
    
    
    BOOL alreadySentLocation = [[NSUserDefaults standardUserDefaults] boolForKey:@"already.sent.location.yo"];
    if ( ! alreadySentLocation) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"already.sent.location.yo"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.button.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1.0);
            [UIView animateWithDuration:2.0
                                  delay:0
                 usingSpringWithDamping:0.2
                  initialSpringVelocity:6.0
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.button.layer.transform = CATransform3DIdentity;
                             }
                             completion:nil];
        });
    }
    
    
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionary];
    extraParameters[@"location"] = MakeString(@"%f;%f", coordinate.latitude, coordinate.longitude);
    if (self.placeName.length > 0) {
        extraParameters[@"context"] = self.placeName;
    }
    block(extraParameters, NO);
}

#pragma mark - Permissions

- (BOOL)doesNeedSpecialPermission {
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined;
}

- (NSString *)textForPopupPriorToAskingPermission {
    return NSLocalizedString(@"📍\nShare your location with friends in 1 tap, even from a notification." , nil);
}

- (NSString *)textForPermissionButton {
    return @"Enable Location";
}

- (NSString *)titleForPermissionAlert {
    return @"Yo Location";
}

- (void)askForSpecialPermission {
    __weak YoMapContext *weakSelf = self;
    [[YoApp currentSession] updateCurrentLocationWithCompletionBlock:^(BOOL success) {
        weakSelf.mapView.showsUserLocation = YES;
        [weakSelf.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
    }];
}

- (UIView *)permissionsBanner {
    YoPermissionsInstructionView *permissionsView = LOAD_NIB(@"YoPermissionsInstructionView");
    permissionsView.instructionImageView.image = [UIImage imageNamed:YoInstructionImageLocation];
    BOOL canOpenYoAppSettings = NO;
    if (IS_OVER_IOS(8.0) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        canOpenYoAppSettings = YES;
    }
    NSString *instructionsText = @"Send your location to your friends by granting Yo access to your location in the Settings App.";
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
    BOOL shouldDisplayPermissionsBanner = NO;
    if ([[YoLocationManager sharedInstance] locationServicesDenied]) {
        shouldDisplayPermissionsBanner = YES;
    }
    return shouldDisplayPermissionsBanner;
}

+ (NSString *)contextID
{
    return @"location";
}

- (NSString *)getFirstTimeYoText {
    return @"📍 Yo Location";
}

@end
