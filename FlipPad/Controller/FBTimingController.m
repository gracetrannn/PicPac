    //
//  FBTimingController.m
//  FlipBookPad
//
//  Created by Manton Reece on 4/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBTimingController.h"

#import "FBStepperControl.h"
#import "FBConstants.h"

@implementation FBTimingController

@synthesize holdFrames = fHoldFrames;

- (id) initWithFrameCount:(NSInteger)inNumFrames
{
	self = [super initWithNibName:@"Timing" bundle:nil];
	if (self) {
		fDefaultFrameCount = inNumFrames;
		self.preferredContentSize = self.view.bounds.size;
		self.modalPresentationStyle = UIModalPresentationPopover;
		self.popoverPresentationController.delegate = self;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[fHoldFrames setValue:fDefaultFrameCount];
	[fHoldFrames setNeedsDisplay];
	
	[self.holdFrames addTarget:self action:@selector(holdFramesChanged:) forControlEvents:UIControlEventValueChanged];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}

- (IBAction) holdFramesChanged:(id)inSender
{
	NSInteger frames = [(FBStepperControl *)inSender value];
	
    [self.delegate timingController:self didChangeFrameHoldCountTo:frames];
}

@end
