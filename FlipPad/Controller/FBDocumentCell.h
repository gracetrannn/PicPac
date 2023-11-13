//
//  FBDocumentCell.h
//  FlipPad
//
//  Created by Manton Reece on 6/28/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBDocumentCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel* nameField;
@property (strong, nonatomic) IBOutlet UIImageView* previewImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
