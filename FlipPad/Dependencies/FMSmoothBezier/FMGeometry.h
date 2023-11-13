//
//  FMGeometry.h
//  fmkit
//
//  Created by August Mueller on 7/12/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef struct {
    CGPoint p;
    CGPoint q;
} FMLineSegment;


CGPoint FMRandomPointInTriangle(CGPoint A, CGPoint B, CGPoint C);

float FMGetAngleBetweenPoints(CGPoint a, CGPoint b);

float FMDistanceBetweenPoints(CGPoint a, CGPoint b);

CGPoint FMPointMidpoint( CGPoint a, CGPoint b );

BOOL FMLinesIntersectAtPoint(FMLineSegment *s1, FMLineSegment *s2, CGPoint *p);

static __inline__ int FMRandomIntBetween(int a, int b)
{
    int range = b - a < 0 ? b - a - 1 : b - a + 1; 
    int value = (int)(range * ((float)random() / (float) LONG_MAX));
    return value == range ? a : a + value;
}

static __inline__ float FMRandomFloatBetween(float a, float b)
{
    return a + (b - a) * ((float)random() / (float) LONG_MAX);
}

static __inline__ CGPoint FMRandomPointForSizeWithinRect(CGSize size, CGRect rect)
{
    return CGPointMake(floor(FMRandomFloatBetween(rect.origin.x, rect.origin.x + rect.size.width - size.width)),
                       floor(FMRandomFloatBetween(rect.origin.y, rect.origin.y + rect.size.height - size.height)));
}

static __inline__ CGRect FMCenteredRectInRect(CGRect innerRect, CGRect outerRect)
{
    innerRect.origin.x = floor((outerRect.size.width - innerRect.size.width) / 2);
    innerRect.origin.y = floor((outerRect.size.height - innerRect.size.height) / 2);
    return innerRect;
}

