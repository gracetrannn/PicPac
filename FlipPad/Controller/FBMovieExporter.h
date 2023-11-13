//
//  FBMovieExporter.h
//  FlipBookPad
//
//  Created by Manton Reece on 9/15/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^FBExportMovieCompletionBlock)(NSError *error);

@interface FBMovieExporter : NSObject

+ (void) writeImagesAsMovie:(NSArray<NSURL*> *)inImageURLs toPath:(NSString*)path size:(CGSize)size duration:(NSInteger)duration fps:(NSInteger)fps completion:(FBExportMovieCompletionBlock)inCompletion;
+ (void) addAudioData:(NSData *)inAudioData forVideo:(NSString *)filePath atTime:(NSTimeInterval)soundStartTime toPath:(NSString *)outFilePath completion:(FBExportMovieCompletionBlock)inCompletion;

@end
