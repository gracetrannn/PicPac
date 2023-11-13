//
//  FBColorPaletteView.h
//  FlipBookPad
//
//  Created by Manton Reece on 5/23/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBColor;

@protocol FBColorPaletteViewDelegate <NSObject>

- (void)colorPaletteViewDidSelectColor:(FBColor *)color
                               atIndex:(NSInteger)index;

- (void)colorPaletteViewDidLongSelectColor:(FBColor *)color
                                   atIndex:(NSInteger)index;

@end

@interface FBColorPaletteView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) id<FBColorPaletteViewDelegate> delegate;

@property (strong, nonatomic) NSArray<FBColor *> *colors;

- (void)loadColors:(NSArray<FBColor *> *)colors;

@end
