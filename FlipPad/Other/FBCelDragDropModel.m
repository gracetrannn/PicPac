//
//  FBCelDragDropModel.m
//  FlipPad
//
//  Created by Alex on 2/21/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

#import "FBCelDragDropModel.h"

@implementation FBCelDragDropModel

- (instancetype)initWithPencil:(FBImage *)pencilImage paint:(FBImage *)paintImage structure:(FBImage *)strImage row:(NSInteger)row column:(NSInteger)column
{
    self = [super init];
    if (self) {
        _paintImage = paintImage;
        _pencilImage = pencilImage;
        _structureImage = strImage;
        
        _row = row;
        _column = column;
    }
    return self;
}

@end
