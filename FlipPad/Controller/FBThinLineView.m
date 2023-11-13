//
//  FBThinLineView.m
//  FlipPad
//
//  Created by Manton Reece on 7/5/15.
//  Copyright (c) 2015 DigiCel, Inc. All rights reserved.
//

#import "FBThinLineView.h"

@implementation FBThinLineView

- (id) initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (self) {
		[self setupOffsetFromTop];
		[self setupLineColor];
	}
	
	return self;
}

- (id) initWithFrame:(CGRect)inFrame
{
	self = [super initWithFrame:inFrame];
	if (self) {
		[self setupLineColor];
	}
	
	return self;
}

- (void) setupOffsetFromTop
{
	self.offset = 0.0;
}

- (void) setupLineColor
{
	self.lineColor = self.backgroundColor;
	self.backgroundColor = [UIColor clearColor];
}

- (void) drawRect:(CGRect)visRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect r = self.bounds;

	[[UIColor clearColor] set];
	CGContextFillRect (context, r);

	r.size.height = 0.5;
	r.origin.y += self.offset;
	
	[self.lineColor set];
	CGContextFillRect (context, r);
}

@end

#pragma mark -

@implementation FBBottomLineView

- (void) setupOffsetFromTop
{
	self.offset = 0.5;
}

@end

#pragma mark -

@implementation FBVerticalLineView

- (void) drawRect:(CGRect)visRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect r = self.bounds;

	[[UIColor clearColor] set];
	CGContextFillRect (context, r);

	r.size.width = 0.5;
	r.origin.x += self.offset;
	
	[self.lineColor set];
	CGContextFillRect (context, r);
}

@end