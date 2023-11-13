//
//  FBDCFBSceneDatabase.h
//  FlipBookPad
//
//  Created by Manton Reece on 7/8/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FBSceneDatabase.h"

@interface FBDCFBSceneDatabase : NSObject <FBSceneDatabase>

@property (strong, atomic) FMDatabaseQueue* databaseQueue;
@property (assign, atomic) BOOL isSaving;

- (NSInteger) maxDesiredColumn;
- (void)setMaxDesiredColumn:(NSInteger)column;

#pragma mark - Old image methods

- (UIImage *) old_imagePencilForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (UIImage *) old_imagePaintForRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (UIImage *) old_imageStructureForRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (void) old_setPencilImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (void) old_setPaintImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;
- (void) old_setStructureImage:(UIImage *)inImage forRow:(NSInteger)inRow column:(NSInteger)inColumn;

@end
