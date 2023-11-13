//
//  FBPencilController.m
//  FlipPad
//
//  Created by Manton Reece on 7/9/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBPencilController.h"
#import "FBMacros.h"
#import "FBSceneController.h"
#import "FBConstants.h"
#import "FBHelpController.h"

const int shapesHeight = 75 + 1; //View Height + Divider

@implementation FBPencilController

- (id) init
{
	self = [super initWithNibName:@"Pencil" bundle:nil];
	if (self) {
		self.preferredContentSize = self.view.bounds.size;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
    _pencilReachability = [[ApplePencilReachability alloc] init];

	[self setupNavigation];
	[self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupPopoverSize];
    [self setupControls];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[FBHelpController showHelpPane:kHelpPaneDrawing];
}

- (void) setupNavigation
{
	self.title = @"Pencil";
	self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) setupPopoverSize
{
//    self.preferredContentSize
//    = [_pencilReachability isPencilAvailable]
//    ? CGSizeMake(356, 300 + shapesHeight)
//    : CGSizeMake(356, 200 + shapesHeight);
    self.preferredContentSize = CGSizeMake(356, 300 + shapesHeight);
}

- (void) setupControls
{
    BOOL isStylusConnected = true;
    
    _minSizeStackView.hidden = !isStylusConnected;
    _pressingForceStackView.hidden = !isStylusConnected;

    NSString* titleLabel = isStylusConnected ? @"Max:" : @"Size";
    _maxLabel.text = titleLabel;

    NSDictionary* minValues = [NSUserDefaults.standardUserDefaults dictionaryForKey:kMinimumLineWidthsPrefKey];
    NSDictionary* maxValues = [NSUserDefaults.standardUserDefaults dictionaryForKey:kMaximumLineWidthsPrefKey];
    NSString* currentBrush = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentBrushPrefKey];
    
    _minSizeSlider.minimumValue = kMinBrushSize;
    _minSizeSlider.maximumValue = kMaxBrushSize;
    
    _maxSizeSlider.minimumValue = kMinBrushSize;
    _maxSizeSlider.maximumValue = kMaxBrushSize;
    
    Float32 minValue = isStylusConnected
    ? [(NSNumber*)[minValues valueForKey:currentBrush] floatValue]
    : [(NSNumber*)[maxValues valueForKey:currentBrush] floatValue];

    
    //[(NSNumber*)[minValues valueForKey:currentBrush] floatValue];
//    self.minSizeSlider.value = [(NSNumber*)[minValues valueForKey:currentBrush] floatValue];

    
    self.minSizeSlider.value = minValue;
	self.maxSizeSlider.value = [(NSNumber*)[maxValues valueForKey:currentBrush] floatValue];
    
    [self minSizeChanged:self.minSizeSlider];
	[self maxSizeChanged:self.maxSizeSlider];
    
    self.pressureSensitivitySlider.value = [[NSUserDefaults standardUserDefaults] doubleForKey:kBrushPressureSensitivityKey];
    NSInteger sensitivity = (NSInteger)self.pressureSensitivitySlider.value;
    [self.pressureSensitivityLabel setText:[NSString stringWithFormat:@"%li", (long)sensitivity]];
    
    self.hardnessSlider.value = [[NSUserDefaults standardUserDefaults] doubleForKey:kBrushHardnessKey];
    NSInteger hardness = (NSInteger)self.hardnessSlider.value;
    [self.hardnessLabel setText:[NSString stringWithFormat:@"%li", (long)hardness]];
    
    self.smoothingSlider.value = [[NSUserDefaults standardUserDefaults] integerForKey:kBrushSmoothingKey];
    NSInteger smoothing = (NSInteger)self.smoothingSlider.value;
    [self.smoothingLabel setText:[NSString stringWithFormat:@"%li", (long)smoothing]];
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushSelectedNotification:) name:kBrushSelectedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shapeSelectedNotification:) name:kShapeSelectedNotification object:nil];
}

- (void) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (void) brushSelectedNotification:(NSNotification *)notification
{
    NSString* currentBrush = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentBrushPrefKey];
    
    NSNumber* minValue = (NSNumber*)[[NSUserDefaults.standardUserDefaults dictionaryForKey:kMinimumLineWidthsPrefKey] objectForKey:currentBrush];
    NSNumber* maxValue = (NSNumber*)[[NSUserDefaults.standardUserDefaults dictionaryForKey:kMaximumLineWidthsPrefKey] objectForKey:currentBrush];
    
	[self.minSizeSlider setValue:[minValue floatValue] animated:YES];
	[self.maxSizeSlider setValue:[maxValue floatValue] animated:YES];

	[self minSizeChanged:self.minSizeSlider];
	[self maxSizeChanged:self.maxSizeSlider];
}

- (void) shapeSelectedNotification:(NSNotification *)notification
{
    NSString* currentBrush = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentShapePrefKey];
    
    NSLog(@"%@", currentBrush);
}

- (IBAction) minSizeChanged:(UISlider *)inSender
{
    NSMutableDictionary* minValues = [[NSUserDefaults.standardUserDefaults dictionaryForKey:kMinimumLineWidthsPrefKey] mutableCopy];
    NSString* currentBrush = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentBrushPrefKey];
    [minValues setObject:[NSNumber numberWithFloat:inSender.value] forKey:currentBrush];
	[[NSUserDefaults standardUserDefaults] setValue:minValues forKey:kMinimumLineWidthsPrefKey];
    
	if (inSender.value < 1.0) {
		self.minSizeField.text = [NSString stringWithFormat:@"%.1f", inSender.value];
	}
	else {
		self.minSizeField.text = [NSString stringWithFormat:@"%.0f", inSender.value];
	}
        
    if (_maxSizeSlider.value < _minSizeSlider.value) {
        _maxSizeSlider.value = _minSizeSlider.value;
        [self maxSizeChanged:_maxSizeSlider];
    }
}

- (IBAction) maxSizeChanged:(UISlider *)inSender
{
	NSMutableDictionary* maxValues = [[NSUserDefaults.standardUserDefaults dictionaryForKey:kMaximumLineWidthsPrefKey] mutableCopy];
    NSString* currentBrush = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentBrushPrefKey];
    [maxValues setObject:[NSNumber numberWithFloat:inSender.value] forKey:currentBrush];
    [[NSUserDefaults standardUserDefaults] setValue:maxValues forKey:kMaximumLineWidthsPrefKey];
    
	if (inSender.value < 1.0) {
		self.maxSizeField.text = [NSString stringWithFormat:@"%.1f", inSender.value];
	}
	else {
		self.maxSizeField.text = [NSString stringWithFormat:@"%.0f", inSender.value];
	}
    
    if (_minSizeSlider.value > _maxSizeSlider.value) {
        _minSizeSlider.value = _maxSizeSlider.value;
        [self minSizeChanged:_minSizeSlider];
    }
}

- (IBAction)pressureSensitivityChanged:(UISlider *)inSender {
    [[NSUserDefaults standardUserDefaults] setDouble:inSender.value forKey:kBrushPressureSensitivityKey];
    NSInteger sensitivity = (NSInteger)self.pressureSensitivitySlider.value;
    [self.pressureSensitivityLabel setText:[NSString stringWithFormat:@"%li", (long)sensitivity]];
}

- (IBAction)hardnessChanged:(UISlider *)inSender
{
    [[NSUserDefaults standardUserDefaults] setDouble:inSender.value forKey:kBrushHardnessKey];
    NSInteger hardness = (NSInteger)self.hardnessSlider.value;
    [self.hardnessLabel setText:[NSString stringWithFormat:@"%li", (long)hardness]];
}

- (IBAction)smoothingChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)sender.value forKey:kBrushSmoothingKey];
    NSInteger smoothing = (NSInteger)self.smoothingSlider.value;
    [self.smoothingLabel setText:[NSString stringWithFormat:@"%li", (long)smoothing]];
}

@end
