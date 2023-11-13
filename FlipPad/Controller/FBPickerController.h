//
//  FBPickerController.h
//  FlipPad
//
//  Created by Manton Reece on 6/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSColorView.h"

#define kPalettePickerSavedColorNotification @"FBPalettePickerSavedColor"
#define kPalettePickerSavedColorKey @"color"
#define kPalettePickerColorIndexKey @"index"

@class FBColor;
@class MSColorSelectionView;

@interface FBPickerController : UIViewController <MSColorViewDelegate>

@property (strong, nonatomic) FBColor* defaultColor;
@property (strong, nonatomic) MSColorSelectionView* pickerView;
@property (assign, nonatomic) NSUInteger paletteColorIndex;

- (id) initWithColor:(FBColor *)inColor;

@end
