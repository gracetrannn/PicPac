//
//  FBCellOriginal.m
//  FlipPad
//
//  Created by zuzex on 11.10.2021.
//  Copyright © 2021 Alex. All rights reserved.
//

#import "FBCellOriginal.h"

#import "Header-Swift.h"

@implementation FBCellOriginal

+ (FBCellOriginal * _Nullable) emptyCel
{
    FBCellOriginal* cel = [[FBCellOriginal alloc] init];
    cel.isLoaded = YES;
    return cel;
}

+ (FBCellOriginal * _Nullable) clearCel
{
    FBCellOriginal* cel = [[FBCellOriginal alloc] init];
//    cel.pencilImage = [[FBImage alloc] initWithPremultipliedImage:[UIImage rf_imageWithSize:CGSizeMake (1, 1) fillColor:nil]];
    cel.isLoaded = YES;
    return cel;
}

- (BOOL) isEmpty
{
    return (self.pencilImage == nil) && (self.paintImage == nil) && (self.backgroundImage == nil);
}

- (BOOL) isBackground
{
    return (self.backgroundImage != nil);
}

- (BOOL) isClear
{
    if (self.pencilImage) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
