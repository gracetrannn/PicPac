//
//  FBEraserController.h
//  FlipPad
//
//  Created by Manton Reece on 2/16/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBEraserController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (retain, nonatomic) IBOutlet UISlider *sizeSlider;
@property (retain, nonatomic) IBOutlet UISlider *hardnessSlider;

@property (retain, nonatomic) IBOutlet UILabel *sizeField;
@property (retain, nonatomic) IBOutlet UILabel *hardnessLabel;

@end
