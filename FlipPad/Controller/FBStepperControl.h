//
//  FBStepperControl.h
//  FlipBookPad
//
//  Created by Manton Reece on 5/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBStepperControl : UIControl
{
}

@property (assign, nonatomic) NSInteger value;
@property (assign, nonatomic) BOOL topHighlighted;
@property (assign, nonatomic) BOOL bottomHighlighted;
@property (assign, nonatomic) NSInteger minimumValue;
@property (assign, nonatomic) NSInteger maximumValue;

@end
