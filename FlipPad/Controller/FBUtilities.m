//
//  FBUtilities.m
//  FlipPad
//
//  Created by Manton Reece on 7/10/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBUtilities.h"

@implementation FBUtilities

+ (void) performBlock:(dispatch_block_t)inBlock afterDelay:(float)inSeconds
{
	dispatch_time_t pop_time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(inSeconds * NSEC_PER_SEC));
	dispatch_after (pop_time, dispatch_get_main_queue(), inBlock);
}

@end
