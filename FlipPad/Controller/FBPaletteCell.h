//
//  FBPaletteCell.h
//  FlipPad
//
//  Created by Manton Reece on 7/10/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBColorPaletteView;

@interface FBPaletteCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet FBColorPaletteView* colorsView;

@end
