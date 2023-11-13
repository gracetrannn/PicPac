//
//  FBEraserController.m
//  FlipPad
//
//  Created by Manton Reece on 2/16/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "FBEraserController.h"

#import "FBConstants.h"

@implementation FBEraserController

- (id) init
{
	self = [super initWithNibName:@"Eraser" bundle:nil];
	if (self) {
		self.preferredContentSize = self.view.bounds.size;
		self.modalPresentationStyle = UIModalPresentationPopover;
		// self.popoverPresentationController.delegate = self;
	}
	
	return self;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	float size = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentEraserWidthPrefKey];
    float hardness = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentEraserHardnessPrefKey];
	self.sizeSlider.value = size;
    self.hardnessSlider.value = hardness;
	[self sizeChanged:self.sizeSlider];
    [self hardnesseChanged:self.hardnessSlider];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}

- (IBAction) sizeChanged:(id)inSender
{
	UISlider* slider = inSender;
	[[NSUserDefaults standardUserDefaults] setFloat:slider.value forKey:kCurrentEraserWidthPrefKey];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUsingEraserToolPrefKey];
	self.sizeField.text = [NSString stringWithFormat:@"%.0f", slider.value];
}

- (IBAction)hardnesseChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                                             forKey:kCurrentEraserHardnessPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kUsingEraserToolPrefKey];
    self.hardnessLabel.text = [NSString stringWithFormat:@"%.0f", sender.value];
}

@end
