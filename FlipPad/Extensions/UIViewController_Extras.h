//
//  UIViewController.h
//  FlipPad
//
//  Created by Manton Reece on 3/27/18.
//  Copyright © 2018 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIViewController (Extras)

#if TARGET_OS_MACCATALYST
- (void)setDrawingToolbarDocName:(NSString*)docName;
- (void)setToolbar:(NSToolbar*)toolbar isTitleVisible:(BOOL)isVisible;
#endif

- (void)showErrorWithMessage:(NSString *)message;
- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
