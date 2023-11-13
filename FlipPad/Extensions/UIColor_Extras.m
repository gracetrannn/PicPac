//
//  UIColor_Extras.m
//  FlipBookPad
//
//  Created by Manton Reece on 4/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "UIColor_Extras.h"

#import "NSString_Extras.h"

@implementation UIColor (Extars)

+ (UIColor *) fb_colorFromString:(NSString *)inString
{
	if ([inString containsSubstring:@" "]) {
		NSArray* pieces = [inString componentsSeparatedByString:@" "];
		float red = [[pieces objectAtIndex:0] floatValue];
		float green = [[pieces objectAtIndex:1] floatValue];
		float blue = [[pieces objectAtIndex:2] floatValue];
		
		return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
	}
	else {
		return [self fb_colorWithHexString:inString];
	}
}

- (NSString *) fb_stringValue
{
	NSString* s = @"";
	
	size_t num = CGColorGetNumberOfComponents ([self CGColor]);
	const CGFloat* components = CGColorGetComponents ([self CGColor]);
	if (num == 2) {
		s = [NSString stringWithFormat:@"%f %f %f", components[0], components[0], components[0]];
	}
	else if (num == 4) {
		s = [NSString stringWithFormat:@"%f %f %f", components[0], components[1], components[2]];
	}
	
	return s;
}

+ (UIColor *) fb_colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self fb_colorComponentFrom: colorString start: 0 length: 1];
            green = [self fb_colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self fb_colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self fb_colorComponentFrom: colorString start: 0 length: 1];
            red   = [self fb_colorComponentFrom: colorString start: 1 length: 1];
            green = [self fb_colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self fb_colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self fb_colorComponentFrom: colorString start: 0 length: 2];
            green = [self fb_colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self fb_colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self fb_colorComponentFrom: colorString start: 0 length: 2];
            red   = [self fb_colorComponentFrom: colorString start: 2 length: 2];
            green = [self fb_colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self fb_colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat) fb_colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

- (BOOL) fb_isClear
{
	CGFloat w, r, g, b, a;
	if (![self getWhite:&w alpha:&a]) {
		[self getRed:&r green:&g blue:&b alpha:&a];
	}
	return (a == 0.0);
}

- (BOOL)isSameToColor:(UIColor *)color {
    return [self isSameToColor:color isIgnoreAlpha:NO];
}

- (BOOL)isSameToColor:(UIColor *)color isIgnoreAlpha:(BOOL)isIgnoreAlpha {
    CGFloat a;
    CGFloat w;
    if ([self getWhite:&w alpha:&a]) {
        return w == w && (isIgnoreAlpha ? YES : a == a);
    }
    CGFloat r;
    CGFloat g;
    CGFloat b;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return r == r && g == g && b == b && (isIgnoreAlpha ? YES : a == a);
    }
    return NO;
}

@end
