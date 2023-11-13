//
//  FBShapeCell.h
//  FlipPad
//
//  Created by Akshay Phulare on 08/03/23.
//  Copyright © 2023 Alex. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBShape;

@interface FBShapeCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;

- (void) setupWithShape:(FBShape *)shape;

@end

