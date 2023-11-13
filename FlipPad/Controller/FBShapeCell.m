//
//  FBShapeCell.m
//  FlipPad
//
//  Created by Akshay Phulare on 08/03/23.
//  Copyright © 2023 Alex. All rights reserved.
//

#import "FBShapeCell.h"
#import "Header-Swift.h"

@implementation FBShapeCell

- (void) setupWithShape:(FBShape *)shape
{
    self.nameField.text = shape.name;
    self.previewImageView.image = [UIImage imageNamed:shape.previewName];
    
    NSString *previousSelection = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentShapePrefKey];

    if (previousSelection == shape.name) {
        self.backgroundColor = [UIColor colorWithWhite:0.927 alpha:1.000];
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
    
}

@end
