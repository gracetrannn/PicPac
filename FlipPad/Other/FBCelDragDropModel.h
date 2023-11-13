//
//  FBCelDragDropModel.h
//  FlipPad
//
//  Created by Alex on 2/21/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBImage;

@interface FBCelDragDropModel: NSObject

@property (nonatomic, strong) FBImage *pencilImage;
@property (nonatomic, strong) FBImage *paintImage;
@property (nonatomic, strong) FBImage *structureImage;

@property (assign) NSInteger row;
@property (assign) NSInteger column;

- (instancetype)initWithPencil:(FBImage *)pencilImage paint:(FBImage *)paintImage structure:(FBImage *)strImage row:(NSInteger)row column:(NSInteger)column;

@end
