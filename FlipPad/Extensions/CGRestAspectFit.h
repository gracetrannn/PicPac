//
//  CGRestAspectFit.h
//  FlipPad
//
//  Created by Alex Vihlayew on 4/16/21.
//  Copyright © 2021 Alex. All rights reserved.
//

#ifndef CGRestAspectFit_h
#define CGRestAspectFit_h

#import <UIKit/UIKit.h>

CGFloat ScaleToAspectFitRectInRect(CGRect rfit, CGRect rtarget);

CGRect AspectFitRectInRect(CGRect rfit, CGRect rtarget);

CGFloat ScaleToAspectFitRectAroundRect(CGRect rfit, CGRect rtarget);

CGRect AspectFitRectAroundRect(CGRect rfit, CGRect rtarget);

#endif /* CGRestAspectFit_h */
