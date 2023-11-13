//
//  FBPlayerView.m
//  FlipBookPad
//
//  Created by Manton Reece on 5/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBPlayerView.h"

@implementation FBPlayerView

- (id) initWithFrame:(CGRect)inFrame
{
	self = [super initWithFrame:inFrame];
	if (self) {
	}

	return self;
}

+ (Class) layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer *) player
{
	return [(AVPlayerLayer *)[self layer] player];
}

- (void) setPlayer:(AVPlayer *)inPlayer
{
	[(AVPlayerLayer *)[self layer] setPlayer:inPlayer];
}

@end
