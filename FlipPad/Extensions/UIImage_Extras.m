//
//  UIImage_Extras.m
//  FlipBook
//
//  Created by Manton Reece on 5/16/10.
//  Copyright 2010 DigiCel. All rights reserved.
//

#import "UIImage_Extras.h"
#import <objc/runtime.h>
#import "CGRestAspectFit.h"

struct FBPixel { uint8_t r, g, b, a; };

static char FB_ASSOCIATED_OBJECT_1_KEY = 0;

@implementation UIImage (Extras)

- (UIImage *) roundedWithInset:(float)inInset cornerRadius:(float)inCornerRadius
{
	return self;
}

- (UIImage *) imageByScalingToSize:(CGSize)inTargetSize
{
    CGSize imageSize = [self size];
    float width = imageSize.width;
    float height = imageSize.height;

    // scaleFactor will be the fraction that we'll
    // use to adjust the size. For example, if we shrink
    // an image by half, scaleFactor will be 0.5. the
    // scaledWidth and scaledHeight will be the original,
    // multiplied by the scaleFactor.
    //
    // IMPORTANT: the "targetHeight" is the size of the space
    // we're drawing into. The "scaledHeight" is the height that
    // the image actually is drawn at, once we take into
    // account the ideal of maintaining proportions

    float scaleFactor = 0.0; 
    float scaledWidth = inTargetSize.width;
    float scaledHeight = inTargetSize.height;

    CGPoint thumbnailPoint = CGPointMake(0,0);

    // since not all images are square, we want to scale
    // proportionately. To do this, we find the longest
    // edge and use that as a guide.

    if ( CGSizeEqualToSize(imageSize, inTargetSize) == NO )
    { 
        // use the longeset edge as a guide. if the
        // image is wider than tall, we'll figure out
        // the scale factor by dividing it by the
        // intended width. Otherwise, we'll use the
        // height.

        float widthFactor = inTargetSize.width / width;
        float heightFactor = inTargetSize.height / height;

        if ( widthFactor < heightFactor )
                scaleFactor = widthFactor;
        else
                scaleFactor = heightFactor;

        // ex: 500 * 0.5 = 250 (newWidth)

        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the thumbnail in the frame. if
        // wider than tall, we need to adjust the
        // vertical drawing point (y axis)

        if ( widthFactor < heightFactor )
                thumbnailPoint.y = (inTargetSize.height - scaledHeight) * 0.5;

        else if ( widthFactor > heightFactor )
                thumbnailPoint.x = (inTargetSize.width - scaledWidth) * 0.5;
    }


    CGContextRef mainViewContentContext;
    CGColorSpaceRef colorSpace;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    // create a bitmap graphics context the size of the image
    mainViewContentContext = CGBitmapContextCreate (NULL, inTargetSize.width, inTargetSize.height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

    // free the rgb colorspace
    CGColorSpaceRelease(colorSpace);    

    if (mainViewContentContext==NULL)
        return NULL;

    //CGContextSetFillColorWithColor(mainViewContentContext, [[UIColor whiteColor] CGColor]);
    //CGContextFillRect(mainViewContentContext, CGRectMake(0, 0, targetSize.width, targetSize.height));

    CGContextDrawImage(mainViewContentContext, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), self.CGImage);

    // Create CGImageRef of the main view bitmap content, and then
    // release that bitmap context
    CGImageRef cg_img = CGBitmapContextCreateImage(mainViewContentContext);

	CGContextRelease(mainViewContentContext);

    // convert the finished resized image to a UIImage 
    UIImage* new_img = [UIImage imageWithCGImage:cg_img];
	
	CGImageRelease (cg_img);

    return new_img;
}

- (UIImage *) rf_imageByChangingAlpha:(CGFloat)inAlpha
{
	CGRect r = CGRectMake (0, 0, [self size].width, [self size].height);
    UIGraphicsBeginImageContextWithOptions(r.size, NO, 1);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState (context);
	CGContextTranslateCTM (context, 0, r.size.height);
	CGContextScaleCTM (context, 1.0, -1.0);
	CGContextSetAlpha (context, inAlpha);
	CGContextDrawImage (context, r, self.CGImage);
	CGContextRestoreGState (context);
	
	UIImage* new_img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return new_img;
}

- (UIImage *)rf_imageByAddingImage:(UIImage*)image atRect:(CGRect)rect
{
    CGRect first_r = CGRectMake (0, 0, self.size.width, self.size.height);
    
    UIGraphicsBeginImageContextWithOptions(first_r.size, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    
    [self drawInRect:first_r];
    [image drawInRect:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return img;
}

- (UIImage *)rf_imageByAddingImage:(UIImage*)image atRect:(CGRect)rect angle:(CGFloat)angle
{
    UIImage* rotatedImage = [image rotatedByAngle:angle];
//    CGImageRef cgimg = [rotatedImage CGImage];
    
    CGRect first_r = CGRectMake (0, 0, self.size.width, self.size.height);
    
    UIGraphicsBeginImageContextWithOptions(first_r.size, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    
    [self drawInRect:first_r];
    [rotatedImage drawInRect:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return img;
}

- (UIImage *)rotatedByAngle:(CGFloat)angle
{
    CGSize newSize = CGRectApplyAffineTransform(CGRectMake(0.0, 0.0, self.size.width, self.size.height), CGAffineTransformRotate(CGAffineTransformIdentity, angle)).size;
    // Trim off the extremely small float value to prevent core graphics from rounding it up
    newSize.width = floor(newSize.width);
    newSize.height = floor(newSize.height);
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Move origin to middle
    CGContextTranslateCTM(context, newSize.width / 2, newSize.height / 2);
    // Rotate around middle
    CGContextRotateCTM(context, angle);
    // Draw the image at its center
    [self drawInRect:CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage *)flippedVertically
{
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0.0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Draw the image at its center
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage *)flippedHorizontally
{
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, self.size.width, 0.0);
    CGContextScaleCTM(context, -1.0, 1.0);
    
    // Draw the image at its center
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

+ (UIImage *) rf_imageByResizingImage:(UIImage *)inImage size:(CGSize)size ratioMode:(FBImageRatioMode)ratioMode
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGRect imageRect = CGRectMake(0, 0, inImage.size.width, inImage.size.height);
    CGRect frameRect = CGRectMake(0, 0, size.width, size.height);
    
    switch (ratioMode) {
        case FBImageRatioModeScaleToFill: {
            [inImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
            break;
        }
        case FBImageRatioModeAspectFit: {
            CGRect fitRect = AspectFitRectInRect(imageRect, frameRect);
            [inImage drawInRect:fitRect];
            break;
        }
        case FBImageRatioModeAspectFill: {
            CGRect fillRect = AspectFitRectAroundRect(imageRect, frameRect);
            [inImage drawInRect:fillRect];
            break;
        }
    }
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *) rf_imageByResizingImageAndApplyingPencilEffect:(UIImage *)inImage size:(CGSize)size ratioMode:(FBImageRatioMode)ratioMode threshold:(CGFloat)threshold
{
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, CGColorSpaceCreateDeviceRGB(), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGRect imageRect = CGRectMake(0, 0, inImage.size.width, inImage.size.height);
    CGRect frameRect = CGRectMake(0, 0, size.width, size.height);
    
    switch (ratioMode) {
        case FBImageRatioModeScaleToFill: {
            CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), inImage.CGImage);
            break;
        }
        case FBImageRatioModeAspectFit: {
            CGRect fitRect = AspectFitRectInRect(imageRect, frameRect);
            CGContextDrawImage(context, fitRect, inImage.CGImage);
            break;
        }
        case FBImageRatioModeAspectFill: {
            CGRect fillRect = AspectFitRectAroundRect(imageRect, frameRect);
            CGContextDrawImage(context, fillRect, inImage.CGImage);
            break;
        }
    }
        
    struct FBPixel *pixels = (struct FBPixel *) CGBitmapContextGetData (context);
    struct FBPixel* color = pixels;
    
    uint8_t thresholdAlpha = (uint8_t)(threshold * (CGFloat)UINT8_MAX);
    
    if (pixels) {
        // rough pass through pixels
        for (size_t i = 0; i < (size.width * size.height); i++)
        {
//            CGFloat brighness = ( (CGFloat)color->r + (CGFloat)color->g + (CGFloat)color->b ) / (3.0 * (CGFloat)UINT8_MAX);
            
//            NSLog(@"%i %i %i %i\n", color->r, color->g, color->b, color->a);
            
            if (color->a < thresholdAlpha) {
                // Clear
                color->r = 0;
                color->g = 0;
                color->b = 0;
                color->a = 0;
            } else {
                // Black
                color->r = 0;
                color->g = 0;
                color->b = 0;
                color->a = 255;
            }
            
            color++;
        }
    }
    
    UIImage* img = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
    CGContextRelease(context);
    
    return img;
}

+ (UIImage *) rf_imageByCompositingImages:(NSArray *)inImages backgroundColor:(UIColor *)inColor
{
	if ([inImages count] == 0) {
		return nil;
	}
	
	CGImageRef first_img = ((UIImage *)[inImages objectAtIndex:0]).CGImage;
	if (first_img == nil) {
		return nil;
	}
	
	CGRect first_r = CGRectMake (0, 0, CGImageGetWidth(first_img), CGImageGetHeight(first_img));

    UIGraphicsBeginImageContextWithOptions(first_r.size, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    
	if (inColor) {
        UIImage* colorImage = [UIImage rf_imageWithSize:first_r.size fillColor:inColor];
        [colorImage drawInRect:first_r];
	}
    
	for (UIImage* img in inImages) {
		CGFloat use_alpha = [img fb_associatedAlpha];
		if (use_alpha == 0.0) {
            [img drawInRect:first_r];
		} else {
            [img drawInRect:first_r blendMode:kCGBlendModeNormal alpha:use_alpha];
		}
	}
	
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
	return img;
}

+ (UIImage *) rf_imageWithCGImage:(CGImageRef)inImage allowReturningNil:(BOOL)inReturnNil
{
	if ((inImage == NULL) && inReturnNil) {
		return nil;
	}
	else {
		return [self imageWithCGImage:inImage];
	}
}

+ (UIImage *) rf_imageWithSize:(CGSize)inSize fillColor:(UIColor *)inColor
{
	CGRect r = CGRectMake (0, 0, inSize.width, inSize.height);
    UIGraphicsBeginImageContextWithOptions(inSize, NO, 1);
    
	if (inColor) {
		[inColor setFill];
		UIRectFill (r);
	}

    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    
	UIGraphicsEndImageContext();
	return img;
}

- (void) fb_setAssociatedAlpha:(CGFloat)inAlpha
{
	NSNumber* val = [NSNumber numberWithFloat:inAlpha];
	objc_setAssociatedObject (self, &FB_ASSOCIATED_OBJECT_1_KEY, val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat) fb_associatedAlpha
{
	NSNumber* val = objc_getAssociatedObject (self, &FB_ASSOCIATED_OBJECT_1_KEY);
	return [val floatValue];
}

- (UIImage *)imageByTintColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [color set];
    UIRectFill(rect);
    [self drawAtPoint:CGPointMake(0, 0) blendMode:kCGBlendModeDestinationIn alpha:1];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (instancetype)initFromPixelBytes:(unsigned char *)bytes width:(NSInteger)width height:(NSInteger)height bitDepth:(NSInteger)bitDepth
{
    NSInteger bytesPerPixel = 4;
    NSInteger pixelCount = width * height;
    NSInteger dataCapacity = bytesPerPixel * pixelCount;
    
    NSMutableData* newData = [NSMutableData dataWithCapacity:dataCapacity];
    
    for (int i = 0; i < pixelCount; i++) {
        uint8_t pixel[4];
        pixel[0] = 0; // R
        pixel[1] = 0; // G
        pixel[2] = 0; // B
        pixel[3] = bytes[i * 2]; // A
        [newData appendBytes:(void*)&pixel length:4];
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, newData.bytes, dataCapacity, nil);
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        8,
                                        8 * 4,
                                        width * bytesPerPixel,
                                        CGColorSpaceCreateDeviceRGB(),
                                        kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                        provider,
                                        nil,
                                        true,
                                        kCGRenderingIntentDefault);
    
    self = [self initWithCGImage:imageRef];
    return self;
}

@end
