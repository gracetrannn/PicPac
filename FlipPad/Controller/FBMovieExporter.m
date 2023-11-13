//
//  FBMovieExporter.m
//  FlipBookPad
//
//  Created by Manton Reece on 9/15/12.
//
//

#import "FBMovieExporter.h"
#import "FBMacros.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

@implementation FBMovieExporter

+ (void) writeImagesAsMovie:(NSArray<NSURL*> *)inImageURLs toPath:(NSString*)path size:(CGSize)inSize duration:(NSInteger)duration fps:(NSInteger)fps completion:(FBExportMovieCompletionBlock)inCompletion
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4 error:&error];
    
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecTypeH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:inSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:inSize.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];    
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    UIImage* firstImage = [UIImage imageWithContentsOfFile:[inImageURLs objectAtIndex:0].path];
    buffer = [self pixelBufferFromCGImage:[firstImage CGImage] size:inSize];
    
	CMTimeScale timescale = 600;
	CMTimeValue timevalue = 1.0 / (float)fps * timescale;
    [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(0, timescale)];
	NSUInteger i = 1;
    while (1) {
		if (writerInput.readyForMoreMediaData) {
			CMTime frameTime = CMTimeMake(timevalue, timescale);
			CMTime lastTime=CMTimeMake(i * timevalue, timescale);
			CMTime presentTime=CMTimeAdd(lastTime, frameTime);
			
			if (i >= [inImageURLs count]) {
				buffer = NULL;
                CVBufferRelease(buffer);
			} else {
                UIImage* image = [UIImage imageWithContentsOfFile:[inImageURLs objectAtIndex:i].path];
				buffer = [self pixelBufferFromCGImage:[image CGImage] size:inSize];
			}
			
			if (buffer) {
				// append buffer
				[adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
				i++;
                CVBufferRelease(buffer);
			} else {
				//Finish the session:
				[writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"finishWritingWithCompletionHandler");
                    CVBufferRelease(buffer);
                    CVPixelBufferRelease(buffer);
                    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                    inCompletion(error);
                }];

				CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
				
				break;
			}
		}
	}
}

+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
										  &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
	if (status != kCVReturnSuccess) {
		return NULL;
	}
	
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
	
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
	
    //CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    //CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
	
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
										   CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
	
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
	
    return pxbuffer;
}

+ (void) addAudioData:(NSData *)inAudioData forVideo:(NSString *)filePath atTime:(NSTimeInterval)soundStartTime toPath:(NSString *)outFilePath completion:(FBExportMovieCompletionBlock)inCompletion
{
    NSError * error = nil;

    AVMutableComposition * composition = [AVMutableComposition composition];

    AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];

    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];

    CMTime audioStartTime;
    CMTimeRange audioRange;
    
    if (soundStartTime > 0.0) {
        // If audio is moved forward
        audioStartTime = CMTimeMakeWithSeconds(soundStartTime, 1);
        audioRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(videoAsset.duration, audioStartTime));
    } else {
        // If audio is moved backward
        CMTime offset = CMTimeMakeWithSeconds(fabs(soundStartTime), 1);
        
        audioStartTime = kCMTimeZero;
        audioRange = CMTimeRangeMake(offset, CMTimeSubtract(videoAsset.duration, offset));
    }
    
    NSString* tempAudioPath = [NSTemporaryDirectory() stringByAppendingString:@"TempAudio.m4a"];
    if ([NSFileManager.defaultManager fileExistsAtPath:tempAudioPath]) {
        [NSFileManager.defaultManager removeItemAtPath:tempAudioPath error:&error];
    }
    [NSFileManager.defaultManager createFileAtPath:tempAudioPath contents:inAudioData attributes:nil];
    
	AVAsset* urlAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:tempAudioPath]];
    [urlAsset loadValuesAsynchronouslyForKeys:@[ @"playable", @"tracks" ] completionHandler:^{
        NSError * error = nil;
        
        if (urlAsset.tracks.count > 0) {
            AVAssetTrack * audioAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

            [compositionAudioTrack insertTimeRange:audioRange ofTrack:audioAssetTrack atTime:audioStartTime error:&error];
        }
        
        AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];

        assetExport.outputFileType = AVFileTypeQuickTimeMovie;// @"com.apple.quicktime-movie";
        assetExport.outputURL = [NSURL fileURLWithPath:outFilePath];

        [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (assetExport.status) {
                case AVAssetExportSessionStatusUnknown: {
                    FBDebugLog (@"Export status unknown");
                }    break;
                case AVAssetExportSessionStatusWaiting: {
                    FBDebugLog (@"Export waiting");
                }    break;
                case AVAssetExportSessionStatusExporting: {
                    FBDebugLog (@"Exporting...");
                }    break;
                case AVAssetExportSessionStatusCompleted: {
                    FBDebugLog (@"Export completed");
                    inCompletion(nil);
                }    break;
                case AVAssetExportSessionStatusFailed: {
                    FBDebugLog (@"Export failed");
                    FBDebugLog (@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                    inCompletion(assetExport.error);
                }    break;
                case AVAssetExportSessionStatusCancelled: {
                    FBDebugLog (@"Export failed");
                    FBDebugLog (@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                    inCompletion(assetExport.error);
                }    break;
            }
        }];
    }];
}


@end
