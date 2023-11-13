//
//  FBTimingController.h
//  FlipBookPad
//
//  Created by Manton Reece on 4/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBStepperControl;
@class FBTimingController;

@protocol FBTimingControllerDelegate <NSObject>

- (void)timingController:(FBTimingController*)timingController didChangeFrameHoldCountTo:(NSInteger)holdCount;

@end

@interface FBTimingController : UIViewController <UIPopoverPresentationControllerDelegate>
{
	FBStepperControl* fHoldFrames;
	
	NSInteger fDefaultFrameCount;
}

@property (weak, nonatomic) id<FBTimingControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet FBStepperControl* holdFrames;

- (id) initWithFrameCount:(NSInteger)inNumFrames;

- (IBAction) holdFramesChanged:(id)inSender;

@end
