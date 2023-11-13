//
//  FBPlayerView.h
//  FlipBookPad
//
//  Created by Manton Reece on 5/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FBPlayerView : UIView
{
	AVPlayer* fPlayer;
}

@property (retain, nonatomic) AVPlayer* player;

@end
