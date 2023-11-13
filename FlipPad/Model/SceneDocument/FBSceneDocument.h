//
//  FBSceneDocument.h
//  FlipBookPad
//
//  Created by Manton Reece on 2/26/12.
//  Copyright (c) 2012 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBXsheetStorage;
@protocol FBSceneDatabase;

@interface FBSceneDocument : NSObject

+ (FBSceneDocument *)currentDocument;

@property (strong, nonatomic) NSObject<FBSceneDatabase>* database;
@property (strong, nonatomic) FBXsheetStorage* storage;

@property (strong, nonatomic) NSString* filePath;
@property (assign, nonatomic) CGSize cachedSceneDimensions;


- (id)initWithPath:(NSString *)inFilePath;

- (NSString *) displayName;
- (UIImage *) thumbnailImage;
- (CGSize) resolutionSize;
- (NSInteger) fps;

- (CGAffineTransform*) canvasTransform;

- (BOOL)isAudioMissing;

- (void)setSoundData:(NSData *)data;
- (NSData *)soundData;

- (void)setSoundOffset:(CGFloat)offset;
- (CGFloat)soundOffset;

- (BOOL) rename:(NSString *)inNewName error:(NSError **)outError;

@end
