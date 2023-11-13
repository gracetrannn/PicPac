//
//  FBLightboxController.h
//  FlipPad
//
//  Created by Manton Reece on 5/26/15.
//  Copyright (c) 2015 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MARKRangeSlider.h"

@interface FBLightboxController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UISlider *layersCountSlider;
@property (weak, nonatomic) IBOutlet UILabel *layersCountLabel;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundSwitch;
@property (weak, nonatomic) IBOutlet MARKRangeSlider *rangeOpacitySlider;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;

+ (NSInteger) previousFramesCount;
+ (BOOL)shouldDisplayBackground;

@end
