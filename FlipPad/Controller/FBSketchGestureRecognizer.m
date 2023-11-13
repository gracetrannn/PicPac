//
//  FBSketchGestureRecognizer.m
//  FlipPad
//
//  Created by Manton Reece on 7/21/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "FBSketchGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation FBSketchGestureRecognizer

- (id) initWithTarget:(id)inTarget action:(SEL)inAction
{
	self = [super initWithTarget:inTarget action:inAction];
	if (self) {
		self.trackedTouches = [NSMutableArray array];
	}
	
	return self;
}

- (void) touchesBegan:(NSSet *)inTouches withEvent:(UIEvent *)inEvent
{
	[self.trackedTouches addObjectsFromArray:[inTouches allObjects]];
	[super touchesBegan:inTouches withEvent:inEvent];
}

- (NSArray *) trackedTouchesFromArray:(NSArray *)inTouches
{
	NSMutableArray* result = [NSMutableArray array];

	for (UITouch* touch in inTouches) {
		if ([self.trackedTouches containsObject:touch]) {
			[result addObject:touch];
		}
	}
		
	return result;
}

@end
