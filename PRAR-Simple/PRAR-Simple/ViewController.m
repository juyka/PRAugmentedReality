//
//  ViewController.m
//  PRAR-Simple
//
//  Created by Geoffroy Lesage on 3/27/14.
//  Copyright (c) 2014 Promet Solutions Inc,. All rights reserved.
//

#import "ViewController.h"
#include <stdlib.h>

#import "PRARManager.h"

#import "AROverlayView.h"

#define NUMBER_OF_POINTS    20

@interface ViewController() <PRARManagerDelegate>

@property (nonatomic) PRARManager *prARManager;
@property (nonatomic, weak) IBOutlet UIView *loadingView;

@end


@implementation ViewController


- (void)alert:(NSString*)title withDetails:(NSString*)details {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:details
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize the manager so it wakes up (can do this anywhere you want)
    self.prARManager = [[PRARManager alloc] initWithSize:self.view.frame.size
                                                delegate:self
                                       shouldCreateRadar:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.prARManager startARWithData:[self getDummyData] forLocation:CLLocationCoordinate2DMake(55.851740, 37.492774)];
}


#pragma mark - Dummy AR Data

// Creates data for `NUMBER_OF_POINTS` AR Objects
-(NSArray*)getDummyData {
    
    NSArray *arData = @[@{
                            @"id": @(0),
                            @"title": @"Цирк",
                            @"lat": @(55.853147),
                            @"lon": @(37.491674)
                            },
                        @{
                            @"id": @(1),
                            @"title": @"Столовка",
                            @"lat": @(55.850959),
                            @"lon": @(37.494989)
                            },
                        @{
                            @"id": @(2),
                            @"title": @"Магаз",
                            @"lat": @(55.850604),
                            @"lon": @(37.492006)
                            },
                        @{
                            @"id": @(3),
                            @"title": @"Соседний офес",
                            @"lat": @(55.852073),
                            @"lon": @(37.493713)
                            }
                        ];
    
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:NUMBER_OF_POINTS];
    
    srand48(time(0));
    for (int i=0; i<arData.count; i++) {
        CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake([arData[i][@"lat"] doubleValue], [arData[i][@"lon"] doubleValue]);
        [points addObject:[self createPointAtLocation:coordinates]];
    }
    
    return [NSArray arrayWithArray:points];
}

// Returns a random location
-(CLLocationCoordinate2D)getRandomLocation
{
    double latRand = drand48() * 90.0;
    double lonRand = drand48() * 180.0;
    double latSign = drand48();
    double lonSign = drand48();
    
    CLLocationCoordinate2D locCoordinates = CLLocationCoordinate2DMake(latSign > 0.5 ? latRand : -latRand,
                                                                       lonSign > 0.5 ? lonRand*2 : -lonRand*2);
    return locCoordinates;
}

// Creates the Data for an AR Object at a given location
-(AROverlayView*)createPointAtLocation:(CLLocationCoordinate2D)locCoordinates
{
    static int i = 0;
    
    AROverlayView *overlay = [[AROverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    overlay.backgroundColor = [UIColor blueColor];
    overlay.coordinates = locCoordinates;
    
    UIButton *button = [[UIButton alloc] initWithFrame:overlay.bounds];
    [button addTarget:self action:@selector(overlayTouchedUpInside:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = i;
    button.titleLabel.numberOfLines = 0;
    [button setTitle:[NSString stringWithFormat:@"%.f meters", [overlay distanceFromLocation:CLLocationCoordinate2DMake(55.851740, 37.492774)]] forState:UIControlStateNormal];
    [overlay addSubview:button];
    
    i++;
    
    return overlay;
}

- (void)overlayTouchedUpInside:(UIButton*)button {
    NSLog(@"Button %i pressed", button.tag);
}

#pragma mark - PRARManager Delegate

- (void)augmentedRealityManagerDidSetup:(PRARManager *)arManager {
    NSLog(@"Finished displaying ARObjects");
    
    [self.view.layer addSublayer:(CALayer*)arManager.cameraLayer];
    [self.view addSubview:arManager.arOverlaysContainerView];
    
    if (arManager.radarView) {
        [self.view addSubview:(UIView*)arManager.radarView];
    }
    
    [self.loadingView setHidden:YES];
}

- (void)augmentedRealityManager:(PRARManager *)arManager didUpdateARFrame:(CGRect)frame {
    [arManager.arOverlaysContainerView setFrame:frame];
}

- (void)augmentedRealityManager:(PRARManager *)arManager didReportError:(NSError *)error {
    [self.loadingView setHidden:YES];
    [self alert:@"Error" withDetails:[error localizedDescription]];
}

@end
