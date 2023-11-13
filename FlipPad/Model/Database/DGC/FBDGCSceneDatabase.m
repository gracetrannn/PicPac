//
//  FBDGCSceneDatabase.m
//  FlipPad
//
//  Created by Alex Vihlayew on 11/2/20.
//  Copyright © 2020 Alex. All rights reserved.
//

#import "FBDGCSceneDatabase.h"
#import "UIImage_Extras.h"
#import "Header-Swift.h"

#import "Bundle.h"
#import "NSDictionary_Extras.h"

@import ObjcDGC;

@interface FBDGCSceneDatabase ()

@property (strong, nonatomic) DGC* dgc;

@end

@implementation FBDGCSceneDatabase

- (DGC*)getDGC
{
    return _dgc;
}

#pragma mark - Init

- (id)initWithPath:(NSString *)inPath {
    self = [super init];
    if (self) {
        self.dgc = [[DGC alloc] initWithPath:inPath];
    }

    return self;
}

#pragma mark - Properties

- (NSInteger)maxColumn {
    return [self.dgc levels];
}

- (NSInteger)maxRow {
    return [self.dgc frames];
}

- (CGSize)frameSize {
    return [self.dgc frameSize];
}

- (CGSize)frameComSize {
    return [self.dgc frameComSize];
}

#pragma mark - Levels

- (NSString*)levelNameAtIndex:(NSInteger)index {
    if(index >= 0)
        return [self.dgc levelNameAtIndex:index];
    else
        return @"";
}

- (void)setLevelName:(NSString*)name atIndex:(NSInteger)index {
    if(index >= 0)
        [self.dgc setLevelName:name atIndex:index];
}

- (BOOL)isLevelHiddenAtIndex:(NSInteger)index {
    // TODO
    return NO;
}

- (void)setLevelIsHidden:(BOOL)hidden atIndex:(NSInteger)index {
    // TODO
}

- (BOOL)isLevelLockedAtIndex:(NSInteger)index {
    // TODO
    return NO;
}

- (void)setLevelIsLocked:(BOOL)locked atIndex:(NSInteger)index {
    // TODO
}

- (NSInteger)getLevelWidthForLevel:(NSInteger)level twidth:(NSInteger)twidth {
    return [self.dgc getLevelWidth:(level - 1) twidth:twidth];
}

#pragma mark - Cell images

// Get

- (FBImage *)imagePaintForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    if(inColumn == 1)
        // BackGround
        return nil;
    else {
        uint32_t depth;
        NSData* paintImage = [self.dgc paintImageDataForFrame:(inRow - 1) level:(inColumn - 1) convert: true depth: &depth];
        return [[FBImage alloc] initWithStraightImageBitmapData:paintImage
                                                          width:self.dgc.frameSize.width
                                                         height:self.dgc.frameSize.height];
    }
}

- (FBImage *)imagePencilForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    if(inColumn == 1)
        // BackGround
        return nil;
    else {
        uint32_t depth;
        NSData* pencilImage = [self.dgc pencilImageDataForFrame:(inRow - 1) level:(inColumn - 1) convert: true depth: &depth];
        return [[FBImage alloc] initWithStraightImageBitmapData:pencilImage
                                                          width:self.dgc.frameSize.width
                                                         height:self.dgc.frameSize.height];
    }
}

- (FBImage *)imageStructureForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    return nil;
}

- (FBImage *)imageBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    if(inColumn == 1) {
        // BackGround
        uint32_t depth;
        NSData* backgroundImageData = [self.dgc backgroundImageDataForFrame:(inRow - 1) convert: true depth: &depth];
        return [[FBImage alloc] initWithStraightImageBitmapData:backgroundImageData
                                                          width:self.dgc.frameComSize.width
                                                         height:self.dgc.frameComSize.height];
    }
    else
        return nil;
}

// Original

- (FBImageOriginal * _Nullable) imageOriginalPaintForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    if(inColumn == 1)
        // BackGround
        return nil;
    else {
        uint32_t depth;
        NSData* paintImage = [self.dgc paintImageDataForFrame:(inRow - 1) level:(inColumn - 1) convert: false depth: &depth];
        return [[FBImageOriginal alloc] initWithImageData:paintImage
                                                    width:self.dgc.frameSize.width
                                                   height:self.dgc.frameSize.height
                                                pixelBits:depth];
    }
}

- (FBImageOriginal * _Nullable) imageOriginalPencilForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    if(inColumn == 1)
        // BackGround
        return nil;
    else {
        uint32_t depth;
        NSData* pencilImage = [self.dgc pencilImageDataForFrame:(inRow - 1) level:(inColumn - 1) convert: false depth: &depth];
        return [[FBImageOriginal alloc] initWithImageData:pencilImage
                                                    width:self.dgc.frameSize.width
                                                   height:self.dgc.frameSize.height
                                                pixelBits:depth];
    }
}

- (FBImageOriginal * _Nullable) imageOriginalBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    return nil;
}

- (UIImage* _Nullable) imageCompositeForRow:(NSInteger)inRow {
    NSData* compositeImageData = [self.dgc compositeImageDataForFrame:(inRow - 1)];
    // TODO: tmp convert
    UIImage *image =  [[FBImage alloc] initWithStraightImageBitmapData:compositeImageData
                                                                 width:self.dgc.frameComSize.width
                                                                height:self.dgc.frameComSize.height].previewUiImage;
    return image;
}

// Set

- (void)setPencilImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    [self.dgc setPencilImageData:[inImage straightImageBitmapData] sizeImage:(CGSize)inImage.size frame:(inRow - 1) level:(inColumn - 1)];
}

- (void)setPaintImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    [self.dgc setPaintImageData:[inImage straightImageBitmapData] sizeImage:(CGSize)inImage.size frame:(inRow - 1) level:(inColumn - 1)];
}

- (void)setStructureImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {

}

- (void)setOriginalPencilImage:(FBImageOriginal *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    [self.dgc setPencilImageData:inImage.buffer size:(CGSize)inImage.size depth:inImage.pixelBits frame:(inRow - 1) level:(inColumn - 1)];
}

- (void)setOriginalPaintImage:(FBImageOriginal *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    [self.dgc setPaintImageData:inImage.buffer size:(CGSize)inImage.size depth:inImage.pixelBits frame:(inRow - 1) level:(inColumn - 1)];
}

#pragma mark - Cell operations

- (void)shiftCellsBackwardStartingFromRow:(NSInteger)fromRow {
    [self.dgc shiftCellsBackwardStartingFromRow:(fromRow - 1)];
}

- (void)shiftCellsForwardStartingFromRow:(NSInteger)fromRow {
    [self.dgc shiftCellsForwardStartingFromRow:(fromRow - 1)];
}

- (void)truncateToRows:(NSInteger)inNumRows {
//    [self.dgc truncateToRows:(inNumRows - 1)];
}

- (void)deleteRow:(NSInteger)row {
    [self.dgc deleteRow:(row - 1)];
}

- (void) shiftCellsForwardStartingFromColumn:(NSInteger)fromColumn {
    [self.dgc shiftCellsForwardStartingFromColumn:(fromColumn - 1)];
}

- (void) shiftCellsBackwardStartingFromColumn:(NSInteger)fromColumn {
//    [self.dgc shiftCellsBackwardStartingFromColumn:(fromColumn - 1)];
}

- (void) deleteColumn:(NSInteger)column {
    [self.dgc deleteColumn:(column - 1)];
}

- (void) truncateToColumns:(NSInteger)inNumColumns {
//    [self.dgc truncateToColumns:(inNumColumns - 1)];
}

#pragma mark - Cut, Copy, Paste Cell

#define kPencilKey [kBundleName stringByAppendingString:@".pencil"]
#define kPaintKey [kBundleName stringByAppendingString:@".paint"]
#define kDepthKey [kBundleName stringByAppendingString:@".depth"]
#define kWidthKey [kBundleName stringByAppendingString:@".width"]
#define kHeightKey [kBundleName stringByAppendingString:@".height"]

- (void) cutCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column {
    [self.dgc cutCopyCellAtRow:(row - 1) column: (column - 1) isCopy:FALSE];
    
    [self copyCell:cell cellOriginal:cellOriginal row:row column: column];
}

- (void) copyCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column {
//    [self.dgc cutCopyCellAtRow:(row - 1) column: (column - 1) isCopy:TRUE];
    
    NSMutableDictionary* flippad_info = [NSMutableDictionary dictionary];

    NSInteger depth = 0;
    NSInteger width = 0;
    NSInteger height = 0;

    // Get images
    if (cellOriginal.pencilImage && cellOriginal.pencilImage.buffer) {
        [flippad_info rf_setObject:cellOriginal.pencilImage.buffer forKey:kPencilKey];
        depth = cellOriginal.pencilImage.pixelBits;
        width = cellOriginal.pencilImage.size.width;
        height = cellOriginal.pencilImage.size.height;
    }

    if (cellOriginal.paintImage && cellOriginal.paintImage.buffer) {
        [flippad_info rf_setObject:cellOriginal.paintImage.buffer forKey:kPaintKey];
        depth = cellOriginal.paintImage.pixelBits;
        width = cellOriginal.paintImage.size.width;
        height = cellOriginal.paintImage.size.height;
    }

    if (depth == 0 || width == 0 || height == 0) {
        return;
    }

    [flippad_info rf_setObject:[NSData dataWithBytes: &depth length: sizeof(depth)] forKey:kDepthKey];
    [flippad_info rf_setObject:[NSData dataWithBytes: &width length: sizeof(width)] forKey:kWidthKey];
    [flippad_info rf_setObject:[NSData dataWithBytes: &height length: sizeof(height)] forKey:kHeightKey];

    [[UIPasteboard generalPasteboard] setItems:@[ flippad_info ]];
}

- (void) pasteCellAtRow:(NSInteger)row column: (NSInteger)column {
//    [self.dgc pasteCellAtRow:(row - 1) column: (column - 1)];
    
    NSData* pencil_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kPencilKey inItemSet:nil] firstObject];
    NSData* paint_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kPaintKey inItemSet:nil] firstObject];
    NSData* depth_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kDepthKey inItemSet:nil] firstObject];
    NSData* width_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kWidthKey inItemSet:nil] firstObject];
    NSData* height_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kHeightKey inItemSet:nil] firstObject];

    if (depth_d == nil || width_d == nil || height_d == nil) {
        return;
    }

    NSInteger depth = *(NSInteger*)([depth_d bytes]);
    NSInteger width = *(NSInteger*)([width_d bytes]);
    NSInteger height = *(NSInteger*)([height_d bytes]);
    CGSize size = CGSizeMake((CGFloat)width, (CGFloat)height);

    if (pencil_d != nil) {
        [self.dgc setPencilImageData:pencil_d size:size depth:depth frame:(row - 1) level:(column - 1)];
    }

    if (paint_d != nil) {
        [self.dgc setPaintImageData:paint_d size:size depth:depth frame:(row - 1) level:(column - 1)];
    }
}

#pragma mark - Sound

- (BOOL)isAudioMissing {
    return _dgc.soundPath.length > 0 && _dgc.soundData.length == 0;
}

- (void)setSoundData:(NSData *)soundData {
    // TODO
}

- (NSData *)soundData {
    return [self.dgc soundData];
}

- (CGFloat)soundOffset {
    // TODO
    return 0;
}

- (void)setSoundOffset:(CGFloat)offset {
    // TODO
}

#pragma mark - Straight alpha

- (BOOL)isStraightAlpha
{
    return YES;
}

- (void)setIsStraightAlpha { }

#pragma mark -

- (void)getSelectedRow:(NSInteger * _Nonnull)row
          selectedItem:(NSInteger * _Nonnull)item {
    *row = 1;
    *item = 1;
}

- (void)setSelectedRow:(NSInteger)row
          selectedItem:(NSInteger)item {
    // TODO: -
}

#pragma mark -

- (BOOL)getCurrentTransform:(CGAffineTransform *)transform {
    return NO;
}

- (void)setCurrentTransform:(CGAffineTransform)transform {
    // Empty.
}

#pragma mark -

- (void)dealloc
{
    NSLog(@"");
}

@end
