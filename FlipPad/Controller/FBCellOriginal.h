//
//  FBCellOriginal.h
//  FlipPad
//
//  Created by zuzex on 11.10.2021.
//  Copyright © 2021 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBImageOriginal;

@interface FBCellOriginal : NSObject

@property (strong, nonatomic) FBImageOriginal* _Nullable pencilImage;
@property (strong, nonatomic) FBImageOriginal* _Nullable paintImage;
@property (strong, nonatomic) FBImageOriginal* _Nullable backgroundImage;

@property NSInteger frame;
@property NSInteger level;

@property (assign, nonatomic) BOOL isLoaded;

+ (FBCellOriginal * _Nullable) emptyCel;
+ (FBCellOriginal * _Nullable) clearCel;

- (BOOL) isEmpty; // there is no image data at all, so the previous image holds over to this frame
- (BOOL) isBackground;
- (BOOL) isClear; // there is image data but it's completely blank, so the hold stops

@end
