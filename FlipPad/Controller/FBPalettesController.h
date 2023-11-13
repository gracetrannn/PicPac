//
//  FBPalettesController.h
//  FlipPad
//
//  Created by Manton Reece on 7/10/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBPalettesController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSArray* palettes; // file paths

+ (NSString*)getLastPalette;

- (void) openLastPaletteAnimated:(BOOL)inAnimated;
- (void) openPaletteAtIndex:(NSUInteger)inIndex animated:(BOOL)inAnimated;

@end
