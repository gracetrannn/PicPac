//
//  FBPointsLine.m
//  FlipPad
//
//  Created by Manton Reece on 10/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBPointsLine.h"

#import "FBRelativePoint.h"

@interface FBReadingData : NSObject

@property (strong, nonatomic) NSData* data;
@property (assign, nonatomic) NSUInteger position;

@end

@implementation FBReadingData

- (id) initWithData:(NSData *)inData
{
	self = [super init];
	if (self) {
		self.data = inData;
		self.position = 0;
	}
	
	return self;
}

- (void) readBytes:(void *)outBuffer length:(NSUInteger)inLength
{
	NSRange r = NSMakeRange (self.position, inLength);
	[self.data getBytes:outBuffer range:r];
	self.position += inLength;
}

@end

#pragma mark -

void FBPathApply (void* info, const CGPathElement* element)
{
	FBPointsLine* line = (__bridge FBPointsLine *)info;
	
	NSMutableArray* new_points = [NSMutableArray arrayWithArray:line.points];
	
	if (element->type == kCGPathElementMoveToPoint) {
		FBRelativePoint* pt = [[FBRelativePoint alloc] init];
		pt.point = element->points[0];
		[new_points addObject:pt];
	}
	else if (element->type == kCGPathElementAddLineToPoint) {
		FBRelativePoint* pt = [[FBRelativePoint alloc] init];
		pt.point = element->points[0];
		[new_points addObject:pt];
	}
	else if (element->type == kCGPathElementAddCurveToPoint) {
		FBRelativePoint* c1 = [[FBRelativePoint alloc] init];
		FBRelativePoint* c2 = [[FBRelativePoint alloc] init];
		FBRelativePoint* pt = [[FBRelativePoint alloc] init];

		c1.point = element->points[0];
		c2.point = element->points[1];
		pt.point = element->points[2];

		[new_points addObject:c1];
		[new_points addObject:c2];
		[new_points addObject:pt];
	}
	else if (element->type == kCGPathElementCloseSubpath) {
	}
	
	line.points = new_points;
}

#pragma mark -

@implementation FBPointsLine

- (id) init
{
	self = [super init];
	if (self) {
		self.color = [UIColor blackColor];
		self.points = [NSMutableArray array];
	}
	
	return self;
}

- (id) initWithBezier:(UIBezierPath *)bezierPath
{
	self = [super init];
	if (self) {
		self.color = [UIColor blackColor];
		self.points = [NSMutableArray array];

		CGPathApply (bezierPath.CGPath, (void *)self, FBPathApply);
	}
	
	return self;
}

+ (NSMutableArray *) unarchivedLinesWithData:(NSData *)inData
{
	NSMutableArray* lines = [NSMutableArray array];
	
	if ([inData length] > 0) {
		FBReadingData* d = [[FBReadingData alloc] initWithData:inData];
		
		NSUInteger num_lines = 0;
		[d readBytes:&num_lines length:sizeof(NSUInteger)];
		
		for (NSUInteger line_i = 0; line_i < num_lines; line_i++) {
			CGFloat r, g, b, a;
			[d readBytes:&r length:sizeof(CGFloat)];
			[d readBytes:&g length:sizeof(CGFloat)];
			[d readBytes:&b length:sizeof(CGFloat)];
			[d readBytes:&a length:sizeof(CGFloat)];
			
			FBPointsLine* line = [[FBPointsLine alloc] init];
			line.color = [UIColor colorWithRed:r green:g blue:b alpha:a];
			NSMutableArray* new_points = [[NSMutableArray alloc] init];
			
			NSUInteger num_points = 0;
			[d readBytes:&num_points length:sizeof(NSUInteger)];
			for (NSUInteger pt_i = 0; pt_i < num_points; pt_i++) {
				CGFloat x, y;
				[d readBytes:&x length:sizeof(CGFloat)];
				[d readBytes:&y length:sizeof(CGFloat)];
				FBRelativePoint* pt = [[FBRelativePoint alloc] initWithX:x andY:y];
				[new_points addObject:pt];
			}
			
			line.points = new_points;
			[lines addObject:line];
		}
	}
	
	return lines;
}

+ (NSData *) archivedDataWithLines:(NSArray *)inLines
{
	NSMutableData* d = [NSMutableData data];

	NSUInteger num_lines = [inLines count];
	[d appendBytes:&num_lines length:sizeof(NSUInteger)];
	
	for (FBPointsLine* line in inLines) {
		UIColor* c = line.color;
		CGFloat r, g, b, a;
		[c getRed:&r green:&g blue:&b alpha:&a];
		[d appendBytes:&r length:sizeof(CGFloat)];
		[d appendBytes:&g length:sizeof(CGFloat)];
		[d appendBytes:&b length:sizeof(CGFloat)];
		[d appendBytes:&a length:sizeof(CGFloat)];
		
		NSUInteger num_points = [line.points count];
		[d appendBytes:&num_points length:sizeof(NSUInteger)];
		for (FBRelativePoint* pt in line.points) {
			CGFloat x = pt.point.x;
			CGFloat y = pt.point.y;
			[d appendBytes:&x length:sizeof(CGFloat)];
			[d appendBytes:&y length:sizeof(CGFloat)];
		}
	}
	
	return d;
}

@end
