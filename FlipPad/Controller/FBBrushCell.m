//
//  FBBrushCell.m
//  FlipPad
//
//  Created by Manton Reece on 1/18/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import "FBBrushCell.h"
#import "Header-Swift.h"


@implementation FBBrushCell

- (void) setupWithBrush:(FBBrush *)brush
{
	self.nameField.text = brush.name;
	self.previewImageView.image = [UIImage imageNamed:brush.previewName];
}

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	if (selected) {
		self.backgroundColor = [UIColor colorWithWhite:0.927 alpha:1.000];
	}
	else {
		self.backgroundColor = [UIColor whiteColor];
	}
}

@end
