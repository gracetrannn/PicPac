//
//  FBCelStack.m
//  FlipPad
//
//  Created by Manton Reece on 5/17/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import "FBCelStack.h"
#import "FBLightboxController.h"
#import "FBCell.h"
#import "Header-Swift.h"

static NSInteger const kDefaultStackCelsMax = 6;

#pragma mark -

@implementation FBCelStack

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mixedCells = [NSMutableArray array];
        self.backgroundCells = [NSMutableArray array];
        self.foregroundCells = [NSMutableArray array];
    }
    
    return self;
}

- (void)removeAll {
    [_mixedCells removeAllObjects];
    [_backgroundCells removeAllObjects];
    [_foregroundCells removeAllObjects];
}

- (void)push:(FBCell *)cel withRow:(NSInteger)row column:(NSInteger)column
{
    if (cel) {
        [self pushMixedCell:cel withRow:row column:column];
        
        FBStackInfo* new_info = [[FBStackInfo alloc] init];
        new_info.cel = cel;
        new_info.row = row;
        new_info.column = column;
        
        for (FBStackInfo* info in self.foregroundCells) {
            if ((info.cel == cel) || ((info.row == row) && (info.column == column))) {
                [self.foregroundCells removeObject:info];
                break;
            }
        }
        
        if (column > 1) { // One of the foregrounds
            [self.foregroundCells insertObject:new_info atIndex:0];
        }
        
        if (self.foregroundCells.count > kDefaultStackCelsMax) {
            [self.foregroundCells removeLastObject];
        }
    }
}

- (void)pushBackgroundCell:(FBCell *)cel withRow:(NSInteger)row column:(NSInteger)column
{
    for (FBStackInfo* info in self.backgroundCells) {
        if ((info.cel == cel) || ((info.row == row) && (info.column == column))) {
            [self.backgroundCells removeObject:info];
            break;
        }
    }

    if (self.backgroundCells.count > kDefaultStackCelsMax) {
        [self.backgroundCells removeLastObject];
    }
    if (cel) {
        FBStackInfo* new_info = [[FBStackInfo alloc] init];
        new_info.cel = cel;
        new_info.row = row;
        new_info.column = column;
        [self.backgroundCells insertObject:new_info atIndex:0];
    }
}

- (void)pushMixedCell:(FBCell *)cel withRow:(NSInteger)row column:(NSInteger)column
{
    FBStackInfo* new_info = [[FBStackInfo alloc] init];
    new_info.cel = cel;
    new_info.row = row;
    new_info.column = column;
    
    for (FBStackInfo* info in self.mixedCells) {
        if ((info.cel == cel) || ((info.row == row) && (info.column == column))) {
            [self.mixedCells removeObject:info];
            break;
        }
    }
    
    [self.mixedCells insertObject:new_info atIndex:0];
    
    if (self.mixedCells.count > kDefaultStackCelsMax) {
        [self.mixedCells removeLastObject];
    }
}

- (void)deleteRow:(NSInteger)row columnsCount:(NSInteger)columnsCount
{
    for (int i = 1; i <= columnsCount; i++) {
        [self deleteCellWithRow:row column:i];
    }
}

- (void)deleteCellWithRow:(NSInteger)row column:(NSInteger)column
{
    [self.mixedCells filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        FBStackInfo* info = evaluatedObject;
        if (((info.row == row) && (info.column == column))) {
            return NO;
        } else {
            return YES;
        }
    }]];
  
    for (FBStackInfo* info in self.backgroundCells) {
        if (((info.row == row) && (info.column == column))) {
            [self.backgroundCells removeObject:info];
            break;
        }
    }
    for (FBStackInfo* info in self.foregroundCells) {
        if (((info.row == row) && (info.column == column))) {
            [self.foregroundCells removeObject:info];
            break;
        }
    }
}

- (NSArray *)singleBackgroundCelsSkipping:(NSInteger)row
{
    NSMutableArray* result = [NSMutableArray array];
    if ([_backgroundCells count] > 0) {
        FBStackInfo* info = _backgroundCells[0];
        [result addObject: info.cel];
    }
    return result;
}

- (NSArray *)allBackgroundCelsSkipping:(NSInteger)row
{
    NSMutableArray* result = [NSMutableArray array];
    for (FBStackInfo* info in _backgroundCells) {
        if (result.count == [FBLightboxController previousFramesCount]) {
            break;
        }
        if (info.row != row) {
            [result addObject:info.cel];
        }
    }
    return result;
}

- (NSArray *)allForegroundCelsSkipping:(NSInteger)row column:(NSInteger)column;
{
    NSMutableArray* result = [NSMutableArray array];
    for (FBStackInfo* info in _foregroundCells) {
        if (result.count == [FBLightboxController previousFramesCount]) {
            break;
        }
        if (info.column != column || info.row != row) {
            [result addObject:info.cel];
        }
    }
    return result;
}

- (NSArray *)allMixedCelsSkipping:(NSInteger)row column:(NSInteger)column;
{
    NSMutableArray* result = [NSMutableArray array];
    for (FBStackInfo* info in _mixedCells) {
        if (result.count == [FBLightboxController previousFramesCount]) {
            break;
        }
        if (info.column != column || info.row != row) {
            [result addObject:info.cel];
        }
    }
    return result;
}

- (void)shiftContentFromRow:(NSInteger)row byOffset:(NSInteger)offset
{
    for (FBStackInfo* info in _mixedCells) {
        if (info.row > row) {
            info.row += offset;
        }
    }
    for (FBStackInfo* info in _foregroundCells) {
        if (info.row > row) {
            info.row += offset;
        }
    }
    for (FBStackInfo* info in _backgroundCells) {
        if (info.row > row) {
            info.row += offset;
        }
    }
}

@end
