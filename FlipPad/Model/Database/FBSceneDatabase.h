//
//  FBSceneDatabase.h
//  FlipPad
//
//  Created by Alex Vihlayew on 11/2/20.
//  Copyright © 2020 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FBCell;
@class FBCellOriginal;
@class FBImage;
@class FBImageOriginal;

@protocol FBSceneDatabase <NSObject>

- (id _Nullable) initWithPath:(NSString * _Nullable)inPath;

- (NSInteger) maxRow;
- (NSInteger) maxColumn;

- (CGSize)frameSize;
- (CGSize)frameComSize;

#pragma mark - New image methods

- (FBImage * _Nullable) imagePencilForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (FBImage * _Nullable) imagePaintForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (FBImage * _Nullable) imageStructureForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (FBImage * _Nullable) imageBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (FBImageOriginal * _Nullable) imageOriginalPencilForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (FBImageOriginal * _Nullable) imageOriginalPaintForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (FBImageOriginal * _Nullable) imageOriginalBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (void) setPencilImage:(FBImage * _Nullable)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (void) setPaintImage:(FBImage * _Nullable)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (void) setStructureImage:(FBImage * _Nullable)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (void)setOriginalPencilImage:(FBImageOriginal * _Nullable)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (void)setOriginalPaintImage:(FBImageOriginal * _Nullable)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (UIImage* _Nullable) imageCompositeForRow:(NSInteger)inRow;

#pragma mark -

- (void) shiftCellsForwardStartingFromRow:(NSInteger)fromRow;
- (void) shiftCellsBackwardStartingFromRow:(NSInteger)fromRow;

- (void) deleteRow:(NSInteger)row;
- (void) truncateToRows:(NSInteger)inNumRows;

- (void) shiftCellsForwardStartingFromColumn:(NSInteger)fromColumn;
- (void) shiftCellsBackwardStartingFromColumn:(NSInteger)fromColumn;

- (void) deleteColumn:(NSInteger)column;
- (void) truncateToColumns:(NSInteger)inNumColumns;

//- (NSString *) stringForSettingsKey:(NSString *)inName;
//- (void) setSettingsString:(NSString *)inName withValue:(NSString *)inValue;

//- (NSData *) dataForSettingsKey:(NSString *)inName;
//- (void) setSettingsData:(NSData *)inData forKey:(NSString *)inKey;

#pragma mark - Cut, Copy, Paste Cell

- (void) cutCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column;

- (void) copyCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column;

- (void) pasteCellAtRow:(NSInteger)row column: (NSInteger)column;

#pragma mark - Straight alpha

- (BOOL)isStraightAlpha;

- (void)setIsStraightAlpha;

#pragma mark - Sound

- (BOOL)isAudioMissing;

- (void)setSoundData:(NSData* _Nullable)soundData;
- (NSData* _Nullable)soundData;

- (CGFloat)soundOffset;
- (void)setSoundOffset:(CGFloat)offset;

#pragma mark - Levels

- (NSString* _Nullable)levelNameAtIndex:(NSInteger)index;
- (void)setLevelName:(NSString* _Nullable)name atIndex:(NSInteger)index;

- (BOOL)isLevelHiddenAtIndex:(NSInteger)index;
- (void)setLevelIsHidden:(BOOL)hidden atIndex:(NSInteger)index;

- (BOOL)isLevelLockedAtIndex:(NSInteger)index;
- (void)setLevelIsLocked:(BOOL)locked atIndex:(NSInteger)index;

- (NSInteger)getLevelWidthForLevel:(NSInteger)level twidth:(NSInteger)twidth;

- (void)shiftToLeftLevelsFromColumn:(NSInteger)column;
- (void)shiftToRightLevelsFromColumn:(NSInteger)column;

#pragma mark -

- (void)getSelectedRow:(NSInteger * _Nonnull)row
          selectedItem:(NSInteger * _Nonnull)item;

- (void)setSelectedRow:(NSInteger)row
          selectedItem:(NSInteger)item;

#pragma mark -

- (BOOL)getCurrentTransform:(CGAffineTransform * _Nonnull)transform;

- (void)setCurrentTransform:(CGAffineTransform)transform;

- (NSDictionary* _Nonnull)getCurrentSettings;

- (void)setCurrentSettings:(NSDictionary*_Nonnull)settings;

@end
