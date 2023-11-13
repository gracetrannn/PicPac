//
//  FBDocumentCell.m
//  FlipPad
//
//  Created by Manton Reece on 6/28/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBDocumentCell.h"

@implementation FBDocumentCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameField.text = nil;
    self.previewImageView.image = nil;
    [self.activityIndicator stopAnimating];
}

@end
