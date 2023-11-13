//
//  FBInfoController.h
//  FlipPad
//
//  Created by Manton Reece on 7/12/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBSceneController;

@interface FBInfoController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) FBSceneController* sceneController;

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (strong, nonatomic) IBOutlet UICollectionView* resolutionCollectionView;

@property (strong, nonatomic) IBOutlet UILabel* productLabel;

@property (strong, nonatomic) IBOutlet UILabel* versionField;
@property (strong, nonatomic) IBOutlet UILabel* buildField;

@property (strong, nonatomic) IBOutlet UISlider* fpsSlider;
@property (strong, nonatomic) IBOutlet UILabel* fpsField;

@property (strong, nonatomic) IBOutlet UILabel* resolutionField;


//Tips Alert Outlets
@property (strong, nonatomic) IBOutlet UIView* helpView;
@property (strong, nonatomic) IBOutlet UILabel* helpField;
@property (strong, nonatomic) IBOutlet UIScrollView* helpScrollView;
@property (strong, nonatomic) IBOutlet UIView* helpScrollViewBackground;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* helpViewHeightConstrnt;

@property (strong, nonatomic) NSArray* resolutions;

- (id) initForSpeed;

@end
