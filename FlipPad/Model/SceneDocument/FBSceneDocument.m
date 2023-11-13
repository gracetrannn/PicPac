//
//  FBSceneDocument.m
//  FlipBookPad
//
//  Created by Manton Reece on 2/26/12.
//  Copyright (c) 2012 DigiCel. All rights reserved.
//

#import "FBSceneDocument.h"

#import "FBSceneController.h"
#import "FBDCFBSceneDatabase.h"
#import "FBDGCSceneDatabase.h"

#import "NSString_Extras.h"
#import "UIImage_Extras.h"
#import "FBMacros.h"
#import "FBConstants.h"
#import "Header-Swift.h"
#import "FBCell.h"

static FBSceneDocument* sCurrentSceneDocument = nil;

@implementation FBSceneDocument

- (id)initWithPath:(NSString *)inFilePath
{
    self = [super init];
    if (self) {
        BOOL newlyCreated = ![inFilePath pathExists];
        
        self.filePath = inFilePath;
        
        if ([[inFilePath pathExtension].lowercaseString isEqualToString:kDGC]) {
            self.database = [[FBDGCSceneDatabase alloc] initWithPath:inFilePath];
        } else {
            self.database = [[FBDCFBSceneDatabase alloc] initWithPath:inFilePath];
        }
        
        self.storage = [[FBXsheetStorage alloc] initWithDatabase:self.database];
        if (newlyCreated) {
            [self.storage fillEmptyRowsWithCount:10];
            [self.database setIsStraightAlpha];
        }
    }
    
    return self;
}

+ (FBSceneDocument *)currentDocument
{
    return sCurrentSceneDocument;
}

- (NSString *)displayName
{
    return [[self.filePath lastPathComponent] stringByDeletingPathExtension];
}

- (UIImage *)thumbnailImage
{
    UIImage* big_img = [self.storage previewImage];
    CGSize sz = CGSizeMake (150, 150);
    return [big_img imageByScalingToSize:sz];
}

- (CGSize)resolutionSize
{
    if (self.cachedSceneDimensions.width == 0) {
        self.cachedSceneDimensions = [[self database] frameSize];
    }
    
    return self.cachedSceneDimensions;
}

- (NSInteger)fps
{
    NSInteger fps = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentFramesPerSecondPrefKey];
    return fps;
}

- (void)setSoundData:(NSData *)data
{    
    [[self database] setSoundData:data];
}

- (BOOL)isAudioMissing {
    return [[self database] isAudioMissing];
}

- (NSData *)soundData
{
    NSData* data = [[self database] soundData];
    return data;
}

- (void)setSoundOffset:(CGFloat)offset
{
    [self.database setSoundOffset:offset];
}

- (CGFloat)soundOffset
{
    return [self.database soundOffset];
}

- (BOOL)rename:(NSString *)inNewName error:(NSError **)outError
{
    NSString* cleaned_name = inNewName;
    
    cleaned_name = [cleaned_name stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    cleaned_name = [cleaned_name stringByReplacingOccurrencesOfString:@".." withString:@" "];
    
    NSString* ext = [self.filePath pathExtension];
    NSString* parent_path = [self.filePath stringByDeletingLastPathComponent];
    NSString* new_path = [[parent_path stringByAppendingPathComponent:cleaned_name] stringByAppendingPathExtension:ext];
    
    BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:self.filePath toPath:new_path error:outError];
    if (ok) {
        self.filePath = new_path;
    }
    
    return ok;
}

@end

