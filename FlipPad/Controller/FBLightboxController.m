//
//  FBLightboxController.m
//  FlipPad
//
//  Created by Manton Reece on 5/26/15.
//  Copyright (c) 2015 DigiCel, Inc. All rights reserved.
//

#import "FBLightboxController.h"
#import "FBConstants.h"

static NSInteger const kLightboxPreviousFramesDefault = 5;

@implementation FBLightboxController

- (instancetype)init
{
	self = [super initWithNibName:@"Lightbox" bundle:nil];
	if (self) {
		self.preferredContentSize = self.view.bounds.size;
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.delegate = self;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self.backgroundSwitch setOn:[[self class] shouldDisplayBackground]];
    
    [_rangeOpacitySlider addTarget:self
                         action:@selector(rangeSliderValueDidChange:)
               forControlEvents:UIControlEventValueChanged];

    float min = [[NSUserDefaults standardUserDefaults] floatForKey:kMinimumOpacityRange];
    float max = [[NSUserDefaults standardUserDefaults] floatForKey:kMaximumOpacityRange];
    if (max == 0) max = 1.0;
    UIImage *originImage = [UIImage imageNamed:@"rangeSliderTrackRange.png"];
    UIImage *tintedImage = [originImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _rangeOpacitySlider.rangeImage = tintedImage;
    _rangeOpacitySlider.tintColor = [UIColor systemBlueColor];
    [_rangeOpacitySlider setMinValue:0.0 maxValue:1.0];
    [_rangeOpacitySlider setLeftValue:min rightValue:max];
    _rangeOpacitySlider.minimumDistance = 0.1;
    
    _rangeLabel.text = [NSString stringWithFormat:@"%0.1f - %0.1f", min, max];
    _rangeLabel.textColor = [UIColor blackColor];
    NSInteger framesCount = [[self class] previousFramesCount];
    self.layersCountSlider.value = framesCount;
    self.layersCountLabel.text = [NSString stringWithFormat:@"%li", (long)framesCount];
}

- (void)close:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (IBAction)layersCountChanged:(UISlider *)sender {
    int framesCount = (int)sender.value;
    self.layersCountLabel.text = [NSString stringWithFormat:@"%li", (long)framesCount];
    [[NSUserDefaults standardUserDefaults] setInteger:framesCount forKey:kLightboxPreviousFramesPrefKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadCurrentCellNotification object:self];
}

- (IBAction)backgroundSwitched:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[_backgroundSwitch isOn] forKey:kLightboxBackgroundDisplayPrefKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadCurrentCellNotification object:self];
}

#pragma mark - UserDefaults read

+ (NSInteger)previousFramesCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kLightboxPreviousFramesPrefKey];;
}

+ (BOOL)shouldDisplayBackground
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLightboxBackgroundDisplayPrefKey];
}

- (void)rangeSliderValueDidChange:(MARKRangeSlider *)slider {
    float min = slider.leftValue;
    float max = slider.rightValue;

    [[NSUserDefaults standardUserDefaults] setFloat:min forKey:kMinimumOpacityRange];
    [[NSUserDefaults standardUserDefaults] setFloat:max forKey:kMaximumOpacityRange];
    _rangeLabel.text = [NSString stringWithFormat:@"%0.1f - %0.1f", min, max];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLightbox object:nil];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

@end
