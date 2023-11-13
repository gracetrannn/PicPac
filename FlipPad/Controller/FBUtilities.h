//
//  FBUtilities.h
//  FlipPad
//
//  Created by Manton Reece on 7/10/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBUtilities : NSObject

+ (void) performBlock:(dispatch_block_t)inBlock afterDelay:(float)inSeconds;

@end
