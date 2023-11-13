//
//  FBCell.h
//  FlipBookPad
//
//  Created by Manton Reece on 4/24/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FBImage;

@interface FBCell : NSObject

@property (strong, nonatomic) FBImage* _Nullable pencilImage;
@property (strong, nonatomic) FBImage* _Nullable paintImage;
@property (strong, nonatomic) FBImage* _Nullable structureImage;
@property (strong, nonatomic) FBImage* _Nullable backgroundImage;
@property (assign, nonatomic) BOOL isLoaded;

+ (FBCell *) emptyCel;
+ (FBCell *) clearCel;

//+ (BOOL) looksLikePencilImage:(UIImage *)inImage;
+ (BOOL) looksCompletelyTransparentImage:(UIImage *)inImage;

- (BOOL) isEmpty; // there is no image data at all, so the previous image holds over to this frame
- (BOOL) isBackground;
- (BOOL) isClear; // there is image data but it's completely blank, so the hold stops

@end

@interface FBOldCell : NSObject

@property (strong, nonatomic) UIImage* pencilImage;
@property (strong, nonatomic) UIImage* paintImage;
@property (strong, nonatomic) UIImage* structureImage;
@property (assign, nonatomic) BOOL isLoaded;

+ (FBCell *) emptyCel;
+ (FBCell *) clearCel;

//+ (BOOL) looksLikePencilImage:(UIImage *)inImage;
+ (BOOL) looksCompletelyTransparentImage:(UIImage *)inImage;

- (BOOL) isEmpty; // there is no image data at all, so the previous image holds over to this frame
- (BOOL) isClear; // there is image data but it's completely blank, so the hold stops

@end
