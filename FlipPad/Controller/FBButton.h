//
//  FBButton.h
//  FlipPad
//
//  Created by Manton Reece on 2/14/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBButton : UIButton

@property (strong) NSString* customTitle;
@property (strong) UIColor* customBackgroundColor;
@property (assign) CGFloat customBackgroundAlpha;

- (instancetype) initWithTitle:(NSString *)inTitle;

- (instancetype) initWithImage:(UIImage *)image;

@end
