//
//  FBSketchGestureRecognizer.h
//  FlipPad
//
//  Created by Manton Reece on 7/21/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBSketchGestureRecognizer : UIPanGestureRecognizer

@property (retain, nonatomic) NSMutableArray* trackedTouches;

- (NSArray *) trackedTouchesFromArray:(NSArray *)inTouches;

@end
