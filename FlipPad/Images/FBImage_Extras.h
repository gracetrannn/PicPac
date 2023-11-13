//
//  FBImage+Extras.h
//  FlipPad
//
//  Created by Alex Vihlayew on 5/18/21.
//  Copyright © 2021 Alex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Header-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBImage (Extras)

- (void) fb_setAssociatedAlpha:(CGFloat)inAlpha;
- (CGFloat) fb_associatedAlpha;

@end

NS_ASSUME_NONNULL_END
