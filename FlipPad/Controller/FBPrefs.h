//
//  FBPrefs.h
//  FlipPad
//
//  Created by Manton Reece on 6/24/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBPrefs: NSObject

+ (BOOL) boolFor:(NSString *)prefKey;

@end
