//
//  FBShapesController.h
//  FlipPad
//
//  Created by Akshay Phulare on 06/03/23.
//  Copyright © 2023 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBShapesController : NSObject<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) NSMutableArray* shapes; // FBBrush

@end

NS_ASSUME_NONNULL_END
