//
//  FBBrushCell.h
//  FlipPad
//
//  Created by Manton Reece on 1/18/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBBrush;

@interface FBBrushCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;

- (void) setupWithBrush:(FBBrush *)brush;

@end
