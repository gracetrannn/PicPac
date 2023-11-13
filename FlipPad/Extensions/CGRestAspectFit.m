//
//  CGRestAspectFit.m
//  FlipPad
//
//  Created by Alex Vihlayew on 4/16/21.
//  Copyright © 2021 Alex. All rights reserved.
//

#import "CGRestAspectFit.h"

CGFloat ScaleToAspectFitRectInRect(CGRect rfit, CGRect rtarget)
{
    // first try to match width
    CGFloat s = CGRectGetWidth(rtarget) / CGRectGetWidth(rfit);
    // if we scale the height to make the widths equal, does it still fit?
    if (CGRectGetHeight(rfit) * s <= CGRectGetHeight(rtarget)) {
        return s;
    }
    // no, match height instead
    return CGRectGetHeight(rtarget) / CGRectGetHeight(rfit);
}

CGRect AspectFitRectInRect(CGRect rfit, CGRect rtarget)
{
    CGFloat s = ScaleToAspectFitRectInRect(rfit, rtarget);
    CGFloat w = CGRectGetWidth(rfit) * s;
    CGFloat h = CGRectGetHeight(rfit) * s;
    CGFloat x = CGRectGetMidX(rtarget) - w / 2;
    CGFloat y = CGRectGetMidY(rtarget) - h / 2;
    return CGRectMake(x, y, w, h);
}

CGFloat ScaleToAspectFitRectAroundRect(CGRect rfit, CGRect rtarget)
{
    // fit in the target inside the rectangle instead, and take the reciprocal
    return 1 / ScaleToAspectFitRectInRect(rtarget, rfit);
}

CGRect AspectFitRectAroundRect(CGRect rfit, CGRect rtarget)
{
    CGFloat s = ScaleToAspectFitRectAroundRect(rfit, rtarget);
    CGFloat w = CGRectGetWidth(rfit) * s;
    CGFloat h = CGRectGetHeight(rfit) * s;
    CGFloat x = CGRectGetMidX(rtarget) - w / 2;
    CGFloat y = CGRectGetMidY(rtarget) - h / 2;
    return CGRectMake(x, y, w, h);
}
