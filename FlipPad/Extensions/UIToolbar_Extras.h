//
//  UIToolbar_Extras.h
//  FlipPad
//
//  Created by Manton Reece on 7/1/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIToolbar (Extras)

- (void) rf_enableAllButtons;
- (void) rf_disableAllButtons;

- (void) rf_enableButtonsWithTags:(NSArray *)inTags;
- (void) rf_disableButtonsWithTags:(NSArray *)inTags;

@end
