//
//  FBRelativePoint.m
//  FlipPad
//
//  Created by Manton Reece on 10/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBRelativePoint.h"

#import "FBPointsLine.h"

@implementation FBRelativePoint

- (id) initWithX:(CGFloat)inX andY:(CGFloat)inY
{
	self = [super init];
	if (self) {
		self.point = CGPointMake (inX, inY);
	}
	
	return self;
}

- (NSString *) description
{
	return NSStringFromCGPoint (self.point);
}

@end
