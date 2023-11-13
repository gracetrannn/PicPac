//
//  FBPointsLine.h
//  FlipPad
//
//  Created by Manton Reece on 10/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBPointsLine : NSObject

@property (copy, nonatomic) UIColor* color;
@property (copy, nonatomic) NSArray* points; // FBRelativePoint

// archived data is binary: number of lines, color components, number of points, then points (repeat)
// as of version 1.2: stored as a bezier; first 2 points are start, rest are 3-point groups for control poing A, B, and x/y point

- (id) initWithBezier:(UIBezierPath *)bezierPath;
+ (NSMutableArray *) unarchivedLinesWithData:(NSData *)inData;
+ (NSData *) archivedDataWithLines:(NSArray *)inLines;

@end
