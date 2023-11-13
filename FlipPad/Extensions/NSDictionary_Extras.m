//
//  NSMutableDictionary+NSDictionary_Extras.m
//  FlipPad
//
//  Created by Manton Reece on 2/12/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "NSDictionary_Extras.h"

@implementation NSMutableDictionary (Extras)

- (void) rf_setObject:(id)inObject forKey:(id <NSCopying>)inKey
{
	if (inObject) {
		[self setObject:inObject forKey:inKey];
	}
}

@end
