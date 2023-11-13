//
//  FBColorsController.h
//  FlipBookPad
//
//  Created by Manton Reece on 4/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBColorPaletteView.h"
#import "HRColorPickerView.h"

@import ObjcDGC;
@class FBColor;

@interface FBColorsController : UIViewController

- (FBColor *)selectedColor;

- (id)initWithPaletteFile:(NSString *)filePath;

- (id)initWithDGCFile:(DGC *)dgcFile
                level:(NSInteger)level;


@end
