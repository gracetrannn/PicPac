//
//  FBPencilController.h
//  FlipPad
//
//  Created by Manton Reece on 7/9/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Header-Swift.h"

@interface FBPencilController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider* minSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel* minSizeField;
@property (weak, nonatomic) IBOutlet UISlider* maxSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel* maxSizeField;

@property (weak, nonatomic) IBOutlet UILabel *maxLabel;

@property (weak, nonatomic) IBOutlet UIStackView *pressingForceStackView;
@property (weak, nonatomic) IBOutlet UISlider *pressureSensitivitySlider;
@property (weak, nonatomic) IBOutlet UILabel *pressureSensitivityLabel;

@property (weak, nonatomic) IBOutlet UISlider* hardnessSlider;
@property (weak, nonatomic) IBOutlet UISlider* smoothingSlider;

@property (strong, nonatomic) IBOutlet id brushesController;
@property (strong, nonatomic) IBOutlet id shapesController;

@property (weak, nonatomic) IBOutlet UILabel *hardnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *smoothingLabel;

@property (weak, nonatomic) IBOutlet UIStackView *minSizeStackView;

@property (strong, nonatomic) ApplePencilReachability* pencilReachability;

@end
