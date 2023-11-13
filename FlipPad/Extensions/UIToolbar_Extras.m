//
//  UIToolbar_Extras.m
//  FlipPad
//
//  Created by Manton Reece on 7/1/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "UIToolbar_Extras.h"

@implementation UIToolbar (Extras)

- (void) rf_setButtonsEnabled:(BOOL)inEnable withTags:(NSArray *)inTags
{
	NSArray* buttons = [[self items] mutableCopy];
	for (UIBarButtonItem* button in buttons) {
		[button setEnabled:!inEnable];
		NSNumber* found_tag = [NSNumber numberWithInteger:button.tag];
		for (NSNumber* set_tag in inTags) {
			if ([found_tag isEqualToNumber:set_tag]) {
				[button setEnabled:inEnable];
			}
		}
	}
	
	[self setItems:buttons];
}

- (void) rf_enableAllButtons
{
	[self rf_disableButtonsWithTags:@[ ]];
}

- (void) rf_disableAllButtons
{
	[self rf_enableButtonsWithTags:@[ ]];
}

- (void) rf_enableButtonsWithTags:(NSArray *)inTags
{
	[self rf_setButtonsEnabled:YES withTags:inTags];
}

- (void) rf_disableButtonsWithTags:(NSArray *)inTags
{
	[self rf_setButtonsEnabled:NO withTags:inTags];
}

@end
