//
//  FBPrefs.m
//  FlipPad
//
//  Created by Manton Reece on 6/24/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import "FBPrefs.h"

@implementation FBPrefs

+ (BOOL) boolFor:(NSString *)prefKey
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:prefKey];
}

@end
