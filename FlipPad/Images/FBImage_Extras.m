//
//  FBImage+FBImage.m
//  FlipPad
//
//  Created by Alex Vihlayew on 5/18/21.
//  Copyright © 2021 Alex. All rights reserved.
//

#import "FBImage_Extras.h"

@implementation FBImage (Extras)

static char FB_ASSOCIATED_OBJECT_1_KEY = 0;

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

@end
