//
//  FBStepperControl.m
//  FlipBookPad
//
//  Created by Manton Reece on 5/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBStepperControl.h"

#import <UIKit/NSText.h>
#import <UIKit/NSParagraphStyle.h>

@implementation FBStepperControl

- (id) initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (self) {
		self.minimumValue = 1;
        self.maximumValue = 10;
	}
	
	return self;
}

- (void) drawRect:(CGRect)inVisRect
{
	CGRect r = self.bounds;
	
	UIImage* img;
	if (self.topHighlighted) {
		if (self.value == self.minimumValue) {
			img = [UIImage imageNamed:@"stepper_pressup_1"];
		}
		else {
			img = [UIImage imageNamed:@"stepper_pressup_N"];
		}
	}
	else if (self.bottomHighlighted) {
		img = [UIImage imageNamed:@"stepper_pressdown"];
	}
	else if (self.value == self.minimumValue) {
		img = [UIImage imageNamed:@"stepper_uponly"];
	}
	else {
		img = [UIImage imageNamed:@"stepper_updown"];
	}
	[img drawInRect:r];
	
	NSString* s = [NSString stringWithFormat:@"%ld", (long)self.value];
	r.origin.y += 8;
	r.size.width -= 15;

	NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	style.alignment = NSTextAlignmentCenter;
	style.lineBreakMode = NSLineBreakByTruncatingMiddle;
	NSDictionary* attrs = @{
		NSFontAttributeName: [UIFont systemFontOfSize:48],
		NSParagraphStyleAttributeName: style
	};
	[s drawInRect:r withAttributes:attrs];
}

- (BOOL) beginTrackingWithTouch:(UITouch *)inTouch withEvent:(UIEvent *)inEvent
{
    if (self.value == self.maximumValue || self.value == self.minimumValue) {
        self.topHighlighted = NO;
        self.bottomHighlighted = NO;
    }else if ([self touchInTopHalf:inTouch]) {
        self.topHighlighted = YES;
        self.bottomHighlighted = NO;
    } else {
        self.topHighlighted = NO;
        self.bottomHighlighted = YES;
	}
    [self setNeedsDisplay];
	
	return YES;
}

- (void) endTrackingWithTouch:(UITouch *)inTouch withEvent:(UIEvent *)inEvent
{
	self.topHighlighted = NO;
	self.bottomHighlighted = NO;
	
	if ([self isTouchInside]) {
		NSInteger old_value = self.value;

		if ([self touchInTopHalf:inTouch] && self.maximumValue > self.value) {
			self.value++;
		} else if ([self touchInBottomHalf:inTouch] && self.value > self.minimumValue) {
            self.value--;
		}

		if (self.value != old_value) {
			[self sendActionsForControlEvents:UIControlEventValueChanged];
			[self setNeedsDisplay];
		}
	}
	
	[self setNeedsDisplay];
}

- (BOOL) touchInTopHalf:(UITouch *)inTouch
{
	CGPoint pt = [inTouch locationInView:self];
	
	CGRect r = self.bounds;
	CGRect top_r = r;
	top_r.size.height = r.size.height / 2.0;
	
	return CGRectContainsPoint (top_r, pt);
}

- (BOOL) touchInBottomHalf:(UITouch *)inTouch
{
    CGPoint pt = [inTouch locationInView:self];
    
    CGRect r = self.bounds;
    CGRect top_r = r;
    top_r.size.height = r.size.height / 2.0;
    CGRect bottom_r = CGRectMake(0, top_r.size.height, top_r.size.width, top_r.size.height);
    
    return CGRectContainsPoint (bottom_r, pt);
}

@end
