//
//  NSMutableDictionary+NSDictionary_Extras.h
//  FlipPad
//
//  Created by Manton Reece on 2/12/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Extras)

- (void) rf_setObject:(id)inObject forKey:(id <NSCopying>)inKey;

@end
