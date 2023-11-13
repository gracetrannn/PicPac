//
//  FBPickerController.m
//  FlipPad
//
//  Created by Manton Reece on 6/29/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBPickerController.h"

#import "FBConstants.h"
#import "UIColor_Extras.h"
#import "MSColorSelectionView.h"
#import "MSColorPicker.h"

@import ObjcDGC;

@implementation FBPickerController

- (id) initWithColor:(FBColor *)inColor
{
	self = [super initWithNibName:@"Picker" bundle:nil];
	if (self) {
		self.preferredContentSize = CGSizeMake (320.0, 350.0);
		self.defaultColor = inColor;
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save Color" style:UIBarButtonItemStyleDone target:self action:@selector(saveColor:)];

//	HRRGBColor rgb;
//	RGBColorFromUIColor (self.defaultColor, &rgb);
	self.pickerView = [[MSColorSelectionView alloc] init];
	[self.view addSubview:self.pickerView];
    
    self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [[self.pickerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0] setActive:YES];
    [[self.pickerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0] setActive:YES];
    [[self.pickerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:0] setActive: YES];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [[self.pickerView.widthAnchor constraintEqualToAnchor:self.view.heightAnchor constant:0] setActive:YES];
    }
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"RGB", ), NSLocalizedString(@"HSB", )]];
    [segmentControl addTarget:self action:@selector(segmentControlDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    segmentControl.selectedSegmentIndex = 1;
    self.navigationItem.titleView = segmentControl;

    [self.pickerView setSelectedIndex:1 animated:NO];
	self.pickerView.color = self.defaultColor.uiColor;
    self.pickerView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [self.view layoutIfNeeded];
}

- (IBAction) segmentControlDidChangeValue:(UISegmentedControl *)segmentedControl
{
    [self.pickerView setSelectedIndex:segmentedControl.selectedSegmentIndex animated:YES];
}

- (void) colorView:(id<MSColorView>)colorView didChangeColor:(UIColor *)color
{
	self.pickerView.color = color;
}

- (IBAction) saveColor:(id)inSender
{
	NSDictionary* user_info = @{
		kPalettePickerSavedColorKey: [[FBColor alloc] initWithUIColor:self.pickerView.color],
		kPalettePickerColorIndexKey: [NSNumber numberWithUnsignedInteger:self.paletteColorIndex]
	};
	[[NSNotificationCenter defaultCenter] postNotificationName:kPalettePickerSavedColorNotification object:self userInfo:user_info];
	
	[self.navigationController popViewControllerAnimated:YES];
}

@end
