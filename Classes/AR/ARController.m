//
//  ARController.m
//  PrometAR
//
// Created by Geoffroy Lesage on 4/24/13.
// Copyright (c) 2013 Promet Solutions Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "ARController.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

#import "LocationMath.h"
#import "ARSettings.h"

#import "AROverlayView.h"

@interface ARController ()

@end

@implementation ARController

- (id)init {
    self = [super init];
    if (self) {
        self.locationMath = [[LocationMath alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.locationMath stopTracking];
}

#pragma mark - AR builders

- (NSArray*)radarSpots {
    NSMutableArray *spots = [NSMutableArray arrayWithCapacity:self.overlayViews.count];
    
    for (AROverlayView *overlayView in self.overlayViews) {
        NSDictionary *spot = @{@"angle": @([self.locationMath getARObjectXPosition:overlayView]/HORIZ_SENS),
                               @"distance": @([overlayView distanceFromLocation:self.userCoordinate])};
        [spots addObject:spot];
    }
    return [spots copy];
}

- (void)reloadData {
    [self setVerticalPosWithDistance];
    [self checkForVerticalPosClashes];
    [self checkAllVerticalPos];
    
    [self setFramesForOverlays];
}

-(void)warpView:(AROverlayView*)overlayView {
    float shrinkLevel = powf(0.7, overlayView.verticalAlignment);
    overlayView.alpha = shrinkLevel;
    overlayView.transform = CGAffineTransformMakeScale(shrinkLevel, shrinkLevel);
}

-(int)setYPosForView:(AROverlayView*)arView {
    int pos = Y_CENTER-(int)(arView.frame.size.height*arView.verticalAlignment);
    pos -= (powf(arView.verticalAlignment, 2)*4);
    
    return pos-(arView.frame.size.height/2);
}

-(void)setVerticalPosWithDistance {
    for (AROverlayView *overlayView in self.overlayViews) {
        
        double distance = [overlayView distanceFromLocation:self.userCoordinate];
        
        if (distance < 20) {
            overlayView.verticalAlignment = 0;
        } else if (distance < 50) {
            overlayView.verticalAlignment = 1;
        } else if (distance < 100) {
            overlayView.verticalAlignment = 2;
        } else if (distance < 200) {
            overlayView.verticalAlignment = 3;
        } else if (distance < 300) {
            overlayView.verticalAlignment = 4;
        } else {
            overlayView.verticalAlignment = 5;
        }
    }
}

-(void)checkForVerticalPosClashes {
    BOOL gotConflict = YES;
    
    while (gotConflict) {
        gotConflict = NO;
        
        for (AROverlayView *overlayView in self.overlayViews) {
            for (AROverlayView *anotherOverlayView in self.overlayViews) {
                
                if (overlayView == anotherOverlayView) continue;
                
                if (overlayView.verticalAlignment != anotherOverlayView.verticalAlignment) continue;
                
                int diff = abs([self.locationMath getARObjectXPosition:overlayView] - [self.locationMath getARObjectXPosition:anotherOverlayView]);
                
                if (diff > overlayView.bounds.size.width) continue;
                
                gotConflict = YES;
                
                if (diff < overlayView.bounds.size.width &&
                    [anotherOverlayView distanceFromLocation:self.userCoordinate] < [overlayView distanceFromLocation:self.userCoordinate]) {
                    overlayView.verticalAlignment++;
                } else if (diff < overlayView.bounds.size.width) {
                    anotherOverlayView.verticalAlignment++;
                }
            }
        }
    }
}

-(void)checkAllVerticalPos {
    for (AROverlayView *overlayView in self.overlayViews) {
        if (overlayView.verticalAlignment == 0) {
            return;
        }
    }
    for (AROverlayView *overlayView in self.overlayViews) {
        overlayView.verticalAlignment--;
    }
    [self checkAllVerticalPos];
}

-(void)setFramesForOverlays {
    for (AROverlayView *overlayView in self.overlayViews) {
        [overlayView setFrame:CGRectMake([self.locationMath getARObjectXPosition:overlayView],
                                           [self setYPosForView:overlayView],
                                           overlayView.bounds.size.width,
                                           overlayView.bounds.size.height)];
        [self warpView:overlayView];
    }
}

@end
