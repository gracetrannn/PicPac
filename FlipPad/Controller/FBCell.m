//
//  FBCell.m
//  FlipBookPad
//
//  Created by Manton Reece on 4/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBCell.h"

#import "UIImage_Extras.h"
#import "Header-Swift.h"

struct FBPixel {
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
};

@implementation FBCell

- (id) copyWithZone:(NSZone *)zone
{
    FBCell* copy = [[[self class] allocWithZone:zone] init];

    copy.pencilImage = self.pencilImage;
    copy.paintImage = self.paintImage;
    copy.structureImage = self.structureImage;
    copy.backgroundImage = self.backgroundImage;
    copy.isLoaded = self.isLoaded;
    
    return copy;
}

+ (FBCell *) emptyCel
{
    FBCell* cel = [[FBCell alloc] init];
    cel.isLoaded = YES;
    return cel;
}

+ (FBCell *) clearCel
{
    FBCell* cel = [[FBCell alloc] init];
    cel.pencilImage = [[FBImage alloc] initWithPremultipliedImage:[UIImage rf_imageWithSize:CGSizeMake (1, 1) fillColor:nil]];
    cel.isLoaded = YES;
    return cel;
}

+ (BOOL) looksCompletelyTransparentImage:(UIImage *)inImage
{
    BOOL result = YES;

    CGImageRef image = inImage.CGImage;
    CGRect r = CGRectMake (0, 0, CGImageGetWidth (image), CGImageGetHeight (image));
    
    if ((image == NULL) || (r.size.width == 0) || (r.size.height == 0)) {
        return NO;
    }
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context1 = CGBitmapContextCreate (NULL,
                                                   r.size.width,
                                                   r.size.height,
                                                   8,
                                                   4 * r.size.width,
                                                   colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage (context1, r, image);

    struct FBPixel *pixels1 = (struct FBPixel *) CGBitmapContextGetData (context1);
    if (pixels1) {
        // rough pass through pixels
        for (int i = 0; i < (r.size.width * r.size.height); i++) {
            struct FBPixel first_color = pixels1[i];
            if (first_color.a != 0) {
                result = NO;
                break;
            }
        }
    }
    
    CGContextRelease (context1);
    CGColorSpaceRelease (colorspace);
    
    return result;
}

- (BOOL) isEmpty
{
    return (self.pencilImage == nil) && (self.paintImage == nil) && (self.backgroundImage == nil);
}

- (BOOL) isBackground
{
    return (self.backgroundImage != nil);
}

- (BOOL) isClear
{
    if (self.pencilImage) {
        return [[self class] looksCompletelyTransparentImage:self.pencilImage.previewUiImage];
    }
    else {
        return NO;
    }
}

- (NSString *) description
{
    if ([self isEmpty]) {
        return @"hold";
    }
    else if ([self isClear]) {
        return @"blank";
    }
    else {
        return [self.pencilImage description];
    }
}

@end

#pragma mark - Old Cell

@implementation FBOldCell

- (id) copyWithZone:(NSZone *)zone
{
	FBOldCell* copy = [[[self class] allocWithZone:zone] init];

	copy.pencilImage = self.pencilImage;
	copy.paintImage = self.paintImage;
	copy.structureImage = self.structureImage;
	copy.isLoaded = self.isLoaded;
	
	return copy;
}

+ (FBOldCell *) emptyCel
{
    FBOldCell* cel = [[FBOldCell alloc] init];
	cel.isLoaded = YES;
	return cel;
}

+ (FBOldCell *) clearCel
{
    FBOldCell* cel = [[FBOldCell alloc] init];
	cel.pencilImage = [UIImage rf_imageWithSize:CGSizeMake (1, 1) fillColor:nil];
	cel.isLoaded = YES;
	return cel;
}

+ (BOOL) looksCompletelyTransparentImage:(UIImage *)inImage
{
	BOOL result = YES;

	CGImageRef image = inImage.CGImage;
	CGRect r = CGRectMake (0, 0, CGImageGetWidth (image), CGImageGetHeight (image));
	
	if ((image == NULL) || (r.size.width == 0) || (r.size.height == 0)) {
		return NO;
	}
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context1 = CGBitmapContextCreate (NULL,
												   r.size.width,
												   r.size.height,
												   8,
												   4 * r.size.width,
												   colorspace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	CGContextDrawImage (context1, r, image);

	struct FBPixel *pixels1 = (struct FBPixel *) CGBitmapContextGetData (context1);
	if (pixels1) {
		// rough pass through pixels
		for (int i = 0; i < (r.size.width * r.size.height); i++) {
			struct FBPixel first_color = pixels1[i];
			if (first_color.a != 0) {
				result = NO;
				break;
			}
		}
	}
	
	CGContextRelease (context1);
	CGColorSpaceRelease (colorspace);
	
	return result;
}

- (BOOL) isEmpty
{
	return (self.pencilImage == nil) && (self.paintImage == nil);
}

- (BOOL) isClear
{
	if (self.pencilImage) {
		return [[self class] looksCompletelyTransparentImage:self.pencilImage];
	}
	else {
		return NO;
	}
}

- (NSString *) description
{
	if ([self isEmpty]) {
		return @"hold";
	}
	else if ([self isClear]) {
		return @"blank";
	}
	else {
		return [self.pencilImage description];
	}
}

@end
