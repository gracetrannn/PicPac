//
//  FBResolutionCell.m
//  FlipPad
//
//  Created by Manton Reece on 10/9/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBResolutionCell.h"

@implementation FBResolutionCell

- (void) setSelected:(BOOL)inSelected
{
	[super setSelected:inSelected];
	
	if (inSelected) {
		self.backgroundColor = [UIColor lightGrayColor];
	}
	else {
		self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	}
}

@end
