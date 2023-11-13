//
//  FBDCFBSceneDatabase.m
//  FlipBookPad
//
//  Created by Manton Reece on 7/8/12.
//
//

#import "FBDCFBSceneDatabase.h"
#import "FBConstants.h"
#import "Header-Swift.h"

#import "Bundle.h"
#import "NSDictionary_Extras.h"

#define kSoundUrlKey @"sound_url"

#define kLevelNamesKey @"level_names"

#define kHiddenLevelsKey @"hidden_levels"

#define kLockedLevelsKey @"locked_levels"

#define kIsStraightAlpha @"is_straight_alpha"
#define kYES @"YES"

#define kDocumentStateKey @"document_state"

#define kCanvasTransform @"canvas_transform"
#define kCanvasOrientation @"canvas_orientation"
#define kCurrentBrush @"current_brush"
#define kCurrentColor @"current_color"
#define kCurrentSettings @"current_settings"

typedef enum { R, G, B, A } UIColorComponentIndices;

@implementation FBDCFBSceneDatabase

#pragma mark - Init

- (id) initWithPath:(NSString *)inPath
{
	self = [super init];
	if (self) {
		self.databaseQueue = [[FMDatabaseQueue alloc] initWithPath:inPath];
		[self createSchema];
		[self createDefaults];
	}
	
	return self;
}

- (void) createSchema
{
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS cells (id INTEGER PRIMARY KEY, x INTEGER, y INTEGER, label VARCHAR(50), pencil BLOB, paint BLOB, vector BLOB)"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY, name VARCHAR(50), value VARCHAR(50))"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS settingsData (id INTEGER PRIMARY KEY, name VARCHAR(50), value BLOB)"];
    }];
    
    NSString* k = @"migration";
    if ([self stringForSettingsKey:k] == nil) {
        [self setSettingsString:k withValue:@"1"];
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            [db executeUpdate:@"ALTER TABLE cells ADD COLUMN structure BLOB"];
        }];
    }
}

- (void) createDefaults
{
    if (![self stringForSettingsKey:@"resolution"]) {
        NSString* resolution_s = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentResolutionPrefKey];
        [self setSettingsString:@"resolution" withValue:resolution_s];
    }
}

#pragma mark - Properties

- (NSInteger) maxRow
{
	__block int result = 0;
	[self.databaseQueue inDatabase:^(FMDatabase* db) {
		FMResultSet* rs = [db executeQuery:@"SELECT x FROM cells ORDER BY x DESC LIMIT 1"];
		if ([rs next]) {
			result = [rs intForColumnIndex:0];
		}
		[rs close];
	}];
	
	return result;
}

- (NSInteger) maxColumn
{
	__block int result = 0;
	[self.databaseQueue inDatabase:^(FMDatabase* db) {
		FMResultSet* rs = [db executeQuery:@"SELECT y FROM cells ORDER BY y DESC LIMIT 1"];
		if ([rs next]) {
			result = [rs intForColumnIndex:0];
		}
		[rs close];
	}];
	return result;
}

- (NSInteger) maxDesiredColumn
{
    NSString* columnsString = [self stringForSettingsKey:@"columns"];
    NSInteger columns = 2;
    
    if (columnsString != nil) {
        columns = MAX(2, [columnsString intValue]);
    }
    
    return columns;
}

- (void)setMaxDesiredColumn:(NSInteger)column
{
    [self setSettingsString:@"columns" withValue:[NSString stringWithFormat:@"%li", (long)column]];
}

- (CGSize)frameSize
{
    NSString* resolution_s = [self stringForSettingsKey:@"resolution"];
    NSInteger w = [[[resolution_s componentsSeparatedByString:@"x"] firstObject] integerValue];
    NSInteger h = [[[resolution_s componentsSeparatedByString:@"x"] lastObject] integerValue];
    return CGSizeMake(w, h);
}

- (CGFloat)soundOffset
{
    NSString* offsetString = [self stringForSettingsKey:@"soundOffset"];
    CGFloat offset = [offsetString floatValue];
    return offset;
}

- (void)setSoundOffset:(CGFloat)offset
{
    [self setSettingsString:@"soundOffset" withValue:[NSString stringWithFormat:@"%f", offset]];
}

#pragma mark - Cell images

- (BOOL) existsForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	__block BOOL found_row = NO;
	[self.databaseQueue inDatabase:^(FMDatabase* db) {
		FMResultSet* rs = [db executeQuery:@"SELECT * FROM cells WHERE x = ? AND y = ?", [NSNumber numberWithInteger:inRow], [NSNumber numberWithInteger:inColumn]];
		if ([rs next]) {
			found_row = YES;
		}
		[rs close];
	}];
	return found_row;
}

- (NSData *) dataForRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
	__block NSData* d = nil;
	NSString* sql = [NSString stringWithFormat:@"SELECT %@ FROM cells WHERE x = ? AND y = ?", inLayer];
	[self.databaseQueue inDatabase:^(FMDatabase* db) {
		FMResultSet* rs = [db executeQuery:sql, [NSNumber numberWithInteger:inRow], [NSNumber numberWithInteger:inColumn]];
		if ([rs next]) {
			d = [rs dataForColumnIndex:0];
		}
		[rs close];
	}];
	
	return d;
}

- (void) setData:(NSData *)inData forRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
	// x = row, y = column (really should be the opposite of that)
	if ([self existsForRow:inRow column:inColumn]) {
		[self.databaseQueue inDatabase:^(FMDatabase* db) {
			NSString* sql = [NSString stringWithFormat:@"UPDATE cells SET %@ = ? WHERE x = ? AND y = ?", inLayer];
			[db executeUpdate:sql, inData, [NSNumber numberWithInteger:inRow], [NSNumber numberWithInteger:inColumn]];
		}];
	} else {
		[self.databaseQueue inDatabase:^(FMDatabase* db) {
			NSString* sql = [NSString stringWithFormat:@"INSERT INTO cells (x, y, %@) VALUES (?, ?, ?)", inLayer];
			[db executeUpdate:sql, [NSNumber numberWithInteger:inRow], [NSNumber numberWithInteger:inColumn], inData];
		}];
	}
}

#pragma mark - Old image methods

- (UIImage *) old_imageForRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
	NSData* d = [self dataForRow:inRow column:inColumn layer:inLayer];
	UIImage* img = nil;
	if ([d length] > 0) {
		img = [UIImage imageWithData:d];
	}
	return img;
}

- (UIImage *) old_imagePencilForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	return [self old_imageForRow:inRow column:inColumn layer:@"pencil"];
}

- (UIImage *) old_imagePaintForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	return [self old_imageForRow:inRow column:inColumn layer:@"paint"];
}

- (UIImage *) old_imageStructureForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	return [self old_imageForRow:inRow column:inColumn layer:@"structure"];
}

- (void) old_setImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
	NSData* d = nil;
	if (inImage) {
		d = UIImagePNGRepresentation (inImage);
	}
	else {
		d = [NSData data];
	}
	[self setData:d forRow:inRow column:inColumn layer:inLayer];
}

- (void) old_setPencilImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	[self old_setImage:inImage forRow:inRow column:inColumn layer:@"pencil"];
}

- (void) old_setPaintImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	[self old_setImage:inImage forRow:inRow column:inColumn layer:@"paint"];
}

- (void) old_setStructureImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
	[self old_setImage:inImage forRow:inRow column:inColumn layer:@"structure"];
}

#pragma mark - New image methods

- (FBImage *) imageForRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
    NSData* d = [self dataForRow:inRow column:inColumn layer:inLayer];
    if (d) {
        return [[FBImage alloc] initWithStraightImagePNGData:d];
    } else {
        return nil;
    }
}

- (FBImage *) imagePencilForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    return [self imageForRow:inRow column:inColumn layer:@"pencil"];
}

- (FBImage *) imagePaintForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    return [self imageForRow:inRow column:inColumn layer:@"paint"];
}

- (FBImage *) imageStructureForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    return [self imageForRow:inRow column:inColumn layer:@"structure"];
}

- (FBImage *) imageBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    return nil;
}

- (FBImageOriginal * _Nullable) imageOriginalPencilForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    return nil;
}

- (FBImageOriginal * _Nullable) imageOriginalPaintForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    return nil;
}

- (FBImageOriginal * _Nullable) imageOriginalBackgroundForRow:(NSInteger)inRow column:(NSInteger)inColumn {
    return nil;
}

- (void) setImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn layer:(NSString *)inLayer
{
    NSData* d = nil;
    if (inImage) {
        d = [inImage straightImagePNGData];
    }
    else {
        d = [NSData data];
    }
    [self setData:d forRow:inRow column:inColumn layer:inLayer];
}

- (void) setPencilImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    [self setImage:inImage forRow:inRow column:inColumn layer:@"pencil"];
}

- (void) setPaintImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    [self setImage:inImage forRow:inRow column:inColumn layer:@"paint"];
}

- (void) setStructureImage:(FBImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    [self setImage:inImage forRow:inRow column:inColumn layer:@"structure"];
}

- (void)setOriginalPencilImage:(FBImageOriginal *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    
}

- (void)setOriginalPaintImage:(FBImageOriginal *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn {
    
}

- (UIImage* _Nullable) imageCompositeForRow:(NSInteger)inRow {
    return nil;
}

#pragma mark - Vector data

- (NSData *) vectorDataForRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    return [self dataForRow:inRow column:inColumn layer:@"vector"];
}

- (void) setVectorData:(NSData *)inData forRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    [self setData:inData forRow:inRow column:inColumn layer:@"vector"];
}

#pragma mark - Cell operations

- (void) shiftCellsForwardStartingFromRow:(NSInteger)fromRow
{
    if ([self existsForRow:fromRow column:1]) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            NSString* sql = [NSString stringWithFormat:@"UPDATE cells SET x = x + 1 WHERE x >= %li", (long)fromRow];
            [db executeUpdate:sql];
        }];
    }
}

- (void) shiftCellsBackwardStartingFromRow:(NSInteger)fromRow
{
    if (![self existsForRow:fromRow column:1]) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            NSString* sql = [NSString stringWithFormat:@"UPDATE cells SET x = x - 1 WHERE x >= %li", (long)fromRow];
            [db executeUpdate:sql];
        }];
    }
}

- (void) deleteRow:(NSInteger)row
{
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        [db executeUpdate:@"DELETE FROM cells WHERE x = ?", [NSNumber numberWithInteger:row]];
    }];
}

- (void) truncateToRows:(NSInteger)inNumRows
{
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        [db executeUpdate:@"DELETE FROM cells WHERE x > ?", [NSNumber numberWithInteger:inNumRows]];
    }];
}

- (void) shiftCellsForwardStartingFromColumn:(NSInteger)fromColumn {
    if ([self existsForRow:1 column:fromColumn]) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            NSString* sql = [NSString stringWithFormat:@"UPDATE cells SET y = y + 1 WHERE y >= %li", (long)fromColumn];
            [db executeUpdate:sql];
        }];
    }
}

- (void) shiftCellsBackwardStartingFromColumn:(NSInteger)fromColumn {
    if (![self existsForRow:1 column:fromColumn]) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            NSString* sql = [NSString stringWithFormat:@"UPDATE cells SET y = y - 1 WHERE y >= %li", (long)fromColumn];
            [db executeUpdate:sql];
        }];
    }
}

- (void) deleteColumn:(NSInteger)column
{
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        [db executeUpdate:@"DELETE FROM cells WHERE y = ?", [NSNumber numberWithInteger:column]];
    }];
}

- (void) truncateToColumns:(NSInteger)inNumColumns
{
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        [db executeUpdate:@"DELETE FROM cells WHERE y > ?", [NSNumber numberWithInteger:inNumColumns]];
    }];
}

#pragma mark - Sound

- (BOOL)isAudioMissing {
    return NO;
}

- (NSData *)soundData
{
    return [self dataForSettingsKey:kSoundUrlKey];
}

- (void)setSoundData:(NSData *)soundData
{
    [self setSettingsData:soundData forKey:kSoundUrlKey];
}

#pragma mark - Levels

- (NSDictionary *)shiftDictionaryKeysInDictionary:(NSDictionary *)dictionary fromColumn:(NSInteger)column offset:(NSInteger)offset {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSString *key in dictionary.allKeys) {
        NSInteger keyInteger = [key integerValue];
        if (keyInteger >= column) {
            [result addEntriesFromDictionary:@{
                [NSString stringWithFormat:@"%ld", keyInteger + offset]: dictionary[key]
            }];
        } else {
            [result addEntriesFromDictionary:@{
                key: dictionary[key]
            }];
        }
    }
    return result;
}

- (void)shiftLevelsFromColumn:(NSInteger)column offset:(NSInteger)offset {
    NSData *levelNamesData = [self dataForSettingsKey:kLevelNamesKey];
    NSData *hiddenLevelsData = [self dataForSettingsKey:kHiddenLevelsKey];
    NSData *lockedLevelsData = [self dataForSettingsKey:kLockedLevelsKey];
    if (levelNamesData) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:levelNamesData options:kNilOptions error:nil];
        if (dict) {
            NSDictionary *shifted = [self shiftDictionaryKeysInDictionary:dict fromColumn:column offset:offset];
            NSData *data = [NSJSONSerialization dataWithJSONObject:shifted options:kNilOptions error:nil];
            [self setSettingsData:data forKey:kLevelNamesKey];
        }
    }
    if (hiddenLevelsData) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:hiddenLevelsData options:kNilOptions error:nil];
        if (dict) {
            NSDictionary *shifted = [self shiftDictionaryKeysInDictionary:dict fromColumn:column offset:offset];
            NSData *data = [NSJSONSerialization dataWithJSONObject:shifted options:kNilOptions error:nil];
            [self setSettingsData:data forKey:kHiddenLevelsKey];
        }
    }
    if (lockedLevelsData) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:lockedLevelsData options:kNilOptions error:nil];
        if (dict) {
            NSDictionary *shifted = [self shiftDictionaryKeysInDictionary:dict fromColumn:column offset:offset];
            NSData *data = [NSJSONSerialization dataWithJSONObject:shifted options:kNilOptions error:nil];
            [self setSettingsData:data forKey:kLockedLevelsKey];
        }
    }
}

- (void)shiftToLeftLevelsFromColumn:(NSInteger)column {
    [self shiftLevelsFromColumn:column - 1 offset:+1];
}

- (void)shiftToRightLevelsFromColumn:(NSInteger)column {
    [self shiftLevelsFromColumn:column - 1 offset:-1];
}

- (NSString*)levelNameAtIndex:(NSInteger)index
{
    NSData* levelNamesData = [self dataForSettingsKey:kLevelNamesKey];
    if (levelNamesData) {
        NSDictionary* nameDict = [NSJSONSerialization JSONObjectWithData:levelNamesData options:kNilOptions error:nil];
        if (nameDict) {
            NSString* name = [nameDict objectForKey:[NSString stringWithFormat:@"%li", (long)index]];
            if (name != nil) {
                return name;
            }
        }
    }
    // Default name
    NSInteger visibleColumns = [self maxDesiredColumn];
    if (index == -1) {
        return @"Sound";
    } else if (index != 0) {
        // Foreground
        if (visibleColumns > 2) {
            return [NSString stringWithFormat:@"Foreground %li", (long)index];
        } else {
            return @"Foreground";
        }
    } else {
        // Background
        return @"Background";
    }
}

- (void)setLevelName:(NSString*)name atIndex:(NSInteger)index
{
    NSData* levelNamesData = [self dataForSettingsKey:kLevelNamesKey];
    NSMutableDictionary* nameDict;
    if (levelNamesData) {
        nameDict = [NSJSONSerialization JSONObjectWithData:levelNamesData options:NSJSONReadingMutableContainers error:nil];
    }
    if (!nameDict) {
        nameDict = [NSMutableDictionary new];
    }
    if (name) {
        // TODO: - 510 and 514 lines it's piece of shit! Say thanks to someone who start cell counting from 1!
        NSString *key = [NSString stringWithFormat:@"%li", (long)index];
        [nameDict setObject:name forKey:key];
    } else {
        NSString *key = [NSString stringWithFormat:@"%li", (long)index - 1];
        [nameDict removeObjectForKey:key];
    }
    //
    NSData* newDictData = [NSJSONSerialization dataWithJSONObject:nameDict options:kNilOptions error:nil];
    [self setSettingsData:newDictData forKey:kLevelNamesKey];
    
}

- (BOOL)isLevelHiddenAtIndex:(NSInteger)index {
    NSData *hiddenLevelsData = [self dataForSettingsKey:kHiddenLevelsKey];
    if (!hiddenLevelsData) {
        return NO;
    }
    NSDictionary *hiddenDict = [NSJSONSerialization JSONObjectWithData:hiddenLevelsData options:kNilOptions error:nil];
    if (!hiddenDict) {
        return NO;
    }
    NSNumber *isHidden = [hiddenDict objectForKey:[NSString stringWithFormat:@"%li", (long)index]];
    if (!isHidden) {
        return NO;
    }
    BOOL value = [isHidden boolValue];
    return index == -1 ? ([self soundData] != nil && value) : value;
}

- (void)setLevelIsHidden:(BOOL)hidden atIndex:(NSInteger)index
{
    NSData* hiddenLevelsData = [self dataForSettingsKey:kHiddenLevelsKey];
    NSMutableDictionary* hiddenDict;
    if (hiddenLevelsData) {
        hiddenDict = [NSJSONSerialization JSONObjectWithData:hiddenLevelsData options:NSJSONReadingMutableContainers error:nil];
    }
    if (!hiddenDict) {
        hiddenDict = [NSMutableDictionary new];
    }
    [hiddenDict setObject:[NSNumber numberWithBool:hidden] forKey:[NSString stringWithFormat:@"%li", (long)index]];
    //
    NSData* newDictData = [NSJSONSerialization dataWithJSONObject:hiddenDict options:kNilOptions error:nil];
    [self setSettingsData:newDictData forKey:kHiddenLevelsKey];
}

- (BOOL)isLevelLockedAtIndex:(NSInteger)index
{
    NSData* lockedLevelsData = [self dataForSettingsKey:kLockedLevelsKey];
    if (!lockedLevelsData) {
        return nil;
    }
    NSDictionary* lockedDict = [NSJSONSerialization JSONObjectWithData:lockedLevelsData options:kNilOptions error:nil];
    if (!lockedDict) {
        return nil;
    }
    NSNumber* isLocked = [lockedDict objectForKey:[NSString stringWithFormat:@"%li", (long)index]];
    return [isLocked boolValue];
}

- (void)setLevelIsLocked:(BOOL)locked atIndex:(NSInteger)index
{
    NSData* lockedLevelsData = [self dataForSettingsKey:kLockedLevelsKey];
    NSMutableDictionary* lockedDict;
    if (lockedLevelsData) {
        lockedDict = [NSJSONSerialization JSONObjectWithData:lockedLevelsData options:NSJSONReadingMutableContainers error:nil];
    }
    if (!lockedDict) {
        lockedDict = [NSMutableDictionary new];
    }
    [lockedDict setObject:[NSNumber numberWithBool:locked] forKey:[NSString stringWithFormat:@"%li", (long)index]];
    //
    NSData* newDictData = [NSJSONSerialization dataWithJSONObject:lockedDict options:kNilOptions error:nil];
    [self setSettingsData:newDictData forKey:kLockedLevelsKey];
}

- (NSInteger)getLevelWidthForLevel:(NSInteger)level twidth:(NSInteger)twidth {
    return 80;
}

#pragma mark - Cut, Copy, Paste Cell

#define kPencilKey [kBundleName stringByAppendingString:@".pencil"]
#define kPaintKey [kBundleName stringByAppendingString:@".paint"]
#define kStructureKey [kBundleName stringByAppendingString:@".structureImage"]

- (void) cutCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column {
    [self copyCell:cell cellOriginal:cellOriginal row:row column: column];
}

- (void) copyCell:(FBCell * _Nullable)cell cellOriginal:(FBCellOriginal * _Nullable)cellOriginal row:(NSInteger)row column: (NSInteger)column {
    NSMutableDictionary* flippad_info = [NSMutableDictionary dictionary];

    // Get images
    if (cell.structureImage) {
        NSData* d = cell.structureImage.straightImagePNGData;
        [flippad_info rf_setObject:d forKey:kStructureKey];
    }
    if (cell.paintImage) {
        NSData* d = cell.paintImage.straightImagePNGData;
        [flippad_info rf_setObject:d forKey:kPaintKey];
    }
    if (cell.pencilImage) {
        NSData* d = cell.pencilImage.straightImagePNGData;
        [flippad_info rf_setObject:d forKey:kPencilKey];
    }

    [[UIPasteboard generalPasteboard] setItems:@[ flippad_info ]];
}

- (void) pasteCellAtRow:(NSInteger)row column: (NSInteger)column {
    NSData* pencil_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kPencilKey inItemSet:nil] firstObject];
    NSData* paint_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kPaintKey inItemSet:nil] firstObject];
    NSData* structure_d = [[[UIPasteboard generalPasteboard] dataForPasteboardType:kStructureKey inItemSet:nil] firstObject];
    
    [self setData:pencil_d forRow:row column:column layer:@"pencil"];
    [self setData:paint_d forRow:row column:column layer:@"paint"];
    [self setData:structure_d forRow:row column:column layer:@"structure"];
}

#pragma mark - Straight alpha

- (BOOL)isStraightAlpha
{
    NSString* isStraight = [self stringForSettingsKey:kIsStraightAlpha];
    return [isStraight isEqualToString:kYES];
}

- (void)setIsStraightAlpha
{
    [self setSettingsString:kIsStraightAlpha withValue:kYES];
}

#pragma mark - Settings persistence

- (NSString *) stringForSettingsKey:(NSString *)inName
{
	__block NSString* val = nil;
	[self.databaseQueue inDatabase:^(FMDatabase* db) {
		FMResultSet* rs = [db executeQuery:@"SELECT value FROM settings WHERE name = ?", inName];
		if ([rs next]) {
			val = [rs stringForColumnIndex:0];
		}
		[rs close];
	}];
	return val;
}

- (void) setSettingsString:(NSString *)inName withValue:(NSString *)inValue
{
	if (inValue == nil) {
		[self.databaseQueue inDatabase:^(FMDatabase* db) {
			[db executeUpdate:@"DELETE FROM settings WHERE name = ?", inName];
		}];
	}
	else if ([self stringForSettingsKey:inName]) {
		[self.databaseQueue inDatabase:^(FMDatabase* db) {
			[db executeUpdate:@"UPDATE settings SET value = ? WHERE name = ?", inValue, inName];
		}];
	}
	else {
		[self.databaseQueue inDatabase:^(FMDatabase* db) {
			[db executeUpdate:@"INSERT INTO settings (name, value) VALUES (?, ?)", inName, inValue];
		}];
	}
}

- (NSData *) dataForSettingsKey:(NSString *)inName
{
    __block NSData* val = nil;
    [self.databaseQueue inDatabase:^(FMDatabase* db) {
        FMResultSet* rs = [db executeQuery:@"SELECT value FROM settingsData WHERE name = ?", inName];
        if ([rs next]) {
            val = [rs dataForColumnIndex:0];
        }
        [rs close];
    }];
    return val;
}

- (void) setSettingsData:(NSData *)inData forKey:(NSString *)inKey
{
    if (inData == nil) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            [db executeUpdate:@"DELETE FROM settingsData WHERE name = ?", inKey];
        }];
    }
    else if ([self dataForSettingsKey:inKey]) {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            [db executeUpdate:@"UPDATE settingsData SET value = ? WHERE name = ?", inData, inKey];
        }];
    }
    else {
        [self.databaseQueue inDatabase:^(FMDatabase* db) {
            [db executeUpdate:@"INSERT INTO settingsData (name, value) VALUES (?, ?)", inKey, inData];
        }];
    }
}

#pragma mark -

- (NSDictionary *)documentState {
    NSData *data = [self dataForSettingsKey:kDocumentStateKey];
    NSDictionary *result = nil;
    if (data) {
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    if (result.count == 0) {
        result = @{
            @"row" : @1,
            @"item" : @1
        };
    }
    return result;
}

- (NSDictionary *)canvasTransform{
    NSData *data = [self dataForSettingsKey:kCanvasTransform];
    NSDictionary *result = nil;
    if (data) {
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    return result;
}

- (NSDictionary *)currentColor {
    NSData *data = [self dataForSettingsKey:kCurrentColor];
    NSDictionary *result = nil;
    if (data) {
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    if (result.count == 0) {
        result = @{
            @"alpha": @1,
            @"blue": @1,
            @"green": @1,
            @"red": @1
        };
    }
    return result;
}

- (NSInteger)canvasOrientation
{
    NSString* orientation = [self stringForSettingsKey:kCanvasOrientation];
    NSInteger result = [orientation integerValue];
    return result;
}

- (NSString*)currentBrush
{
    NSString* brush = [self stringForSettingsKey:kCurrentBrush];
    return brush;
}

- (void)setDocumentState:(NSDictionary *)documentState {
    NSData *data = [NSJSONSerialization dataWithJSONObject:documentState options:kNilOptions error:nil];
    [self setSettingsData:data forKey:kDocumentStateKey];
}

- (void)setDocumentCurrentColor:(NSDictionary *)currentColor {
    NSData *data = [NSJSONSerialization dataWithJSONObject:currentColor options:kNilOptions error:nil];
    [self setSettingsData:data forKey:kCurrentColor];
}

- (void)setDocumentCanvasTransform:(NSDictionary *)transform {
    NSData *data = [NSJSONSerialization dataWithJSONObject:transform options:kNilOptions error:nil];
    [self setSettingsData:data forKey:kCanvasTransform];
}


#pragma mark -

- (void)getSelectedRow:(NSInteger * _Nonnull)row
          selectedItem:(NSInteger * _Nonnull)item {
    NSDictionary *documentState = [self documentState];
    *row = [documentState[@"row"] intValue];
    *item = [documentState[@"item"] intValue];
}

- (void)setSelectedRow:(NSInteger)row
          selectedItem:(NSInteger)item {
    NSMutableDictionary *documentState = [[self documentState] mutableCopy];
    
    [documentState setObject:@(row) forKey:@"row"];
    [documentState setObject:@(item) forKey:@"item"];
    [self setDocumentState:documentState];
}

#pragma mark -

- (BOOL)getCurrentTransform:(CGAffineTransform * _Nonnull)transform {
    NSDictionary *dict = [self canvasTransform];
    if (dict.count == 0) {
        return NO;
    }
    CGFloat a = [dict[@"a"] floatValue];
    CGFloat b = [dict[@"b"] floatValue];
    CGFloat c = [dict[@"c"] floatValue];
    CGFloat d = [dict[@"d"] floatValue];
    CGFloat tx = [dict[@"tx"] floatValue];
    CGFloat ty = [dict[@"ty"] floatValue];
    CGAffineTransform result = CGAffineTransformMake(a, b, c, d, tx, ty);
    *transform = result;
    return YES;
}

- (void)setCurrentTransform:(CGAffineTransform)transform {
    NSDictionary *result = @{
        @"a": @(transform.a),
        @"b": @(transform.b),
        @"c": @(transform.c),
        @"d": @(transform.d),
        @"tx": @(transform.tx),
        @"ty": @(transform.ty)
    };
    [self setDocumentCanvasTransform:result];
}


- (NSDictionary* _Nonnull)getCurrentSettings;
{
    NSData *data = [self dataForSettingsKey:kCurrentSettings];
    NSError *error;
    NSDictionary *result = [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class fromData:data error:&error];
    
    if (error) {  NSLog(@"%@", error); }
    return result;
}

- (void)setCurrentSettings:(NSDictionary*_Nonnull)settings;
{
    NSData *myData = [NSKeyedArchiver archivedDataWithRootObject:settings requiringSecureCoding:NO error:nil];
    [self setSettingsData:myData forKey:kCurrentSettings];
}


@end
