//
//  FBCelStack.h
//  FlipPad
//
//  Created by Manton Reece on 5/17/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBCell;

@interface FBCelStack : NSObject

// FBStackInfo
@property (strong) NSMutableArray* mixedCells;
@property (strong) NSMutableArray* backgroundCells;
@property (strong) NSMutableArray* foregroundCells;

- (void)removeAll;

- (void)push:(FBCell *)cel withRow:(NSInteger)row column:(NSInteger)column;
- (void)pushBackgroundCell:(FBCell *)cel withRow:(NSInteger)row column:(NSInteger)column;

- (NSArray *)singleBackgroundCelsSkipping:(NSInteger)row;
- (NSArray *)allForegroundCelsSkipping:(NSInteger)row column:(NSInteger)column;;
- (NSArray *)allBackgroundCelsSkipping:(NSInteger)row;
- (NSArray *)allMixedCelsSkipping:(NSInteger)row column:(NSInteger)column;

- (void)deleteRow:(NSInteger)row columnsCount:(NSInteger)columnsCount;
- (void)deleteCellWithRow:(NSInteger)row column:(NSInteger)column;

- (void)shiftContentFromRow:(NSInteger)row byOffset:(NSInteger)offset;

@end
