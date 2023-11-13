//
//  UIColor_Extras.h
//  FlipBookPad
//
//  Created by Manton Reece on 4/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extars)

+ (UIColor *) fb_colorFromString:(NSString *)inString;

+ (UIColor *)fb_colorWithHexString:(NSString *)hexString;

- (NSString *) fb_stringValue;
- (BOOL) fb_isClear;

- (BOOL)isSameToColor:(UIColor *)color;
- (BOOL)isSameToColor:(UIColor *)color isIgnoreAlpha:(BOOL)isIgnoreAlpha;

@end
