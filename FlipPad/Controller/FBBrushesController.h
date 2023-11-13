//
//  FBBrushesController.h
//  FlipPad
//
//  Created by Manton Reece on 1/18/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBBrushesController : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSMutableArray* brushes; // FBBrush

@end
