//
//  FBRelativePoint.h
//  FlipPad
//
//  Created by Manton Reece on 10/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FBPointsLine;

@interface FBRelativePoint : NSObject

@property (assign, nonatomic) CGPoint point;

- (id) initWithX:(CGFloat)inX andY:(CGFloat)inY;

@end
