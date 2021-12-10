//
//  YoMapController.h
//  Yo
//
//  Created by Or Arbel on 9/13/14.
//
//
#import <MapKit/MapKit.h>
#import "YoPresentorController.h"
#import <THLabel/THLabel.h>
#import "Yo.h"

@interface YoMapController : YoPresentorController

@property(nonatomic, weak) IBOutlet MKMapView *mapView;
@property(nonatomic, weak) IBOutlet UIButton *closeButton;
@property(nonatomic, weak) IBOutlet THLabel *topLabel;

@end
