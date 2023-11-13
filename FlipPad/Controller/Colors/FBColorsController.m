//
//  FBColorsController.m
//  FlipBookPad
//
//  Created by Manton Reece on 4/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBColorsController.h"
#import "FBMacros.h"
#import "FBConstants.h"
#import "FBPickerController.h"
#import "UIColor_Extras.h"
#import "Header-Swift.h"

#define kCurrentColorIndexPrefKey @"CurrentColorIndex"

@import ObjcDGC;

@interface FBColorsController () <FBColorPaletteViewDelegate>

// Storage

// DCFB
@property (strong, nonatomic) NSString *paletteFilePath;

// DGC
@property (strong, nonatomic) FBPalette *palette;

@property (strong, nonatomic) IBOutlet UISlider *opacitySlider;

@property (strong, nonatomic) IBOutlet UIView *colorBox;

@property (strong, nonatomic) IBOutlet FBColorPaletteView *paletteView;

@property (assign, nonatomic) NSInteger editIndex;

@end

@implementation FBColorsController

- (id)initWithPaletteFile:(NSString *)filePath {
    self = [super initWithNibName:@"Colors"
                           bundle:nil];
    if (self) {
        self.editIndex = -1;
        self.paletteFilePath = filePath;
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.preferredContentSize = self.view.bounds.size;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(prefsDidChangeNotification:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(palettePickerSavedColorNotification:)
                                                     name:kPalettePickerSavedColorNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithDGCFile:(DGC *)dgcFile
                level:(NSInteger)level {
    self = [super initWithNibName:@"Colors"
                           bundle:nil];
    if (self) {
        self.editIndex = -1;
        self.palette = [dgcFile paletteForLevel:level];
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.preferredContentSize = self.view.bounds.size;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(prefsDidChangeNotification:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(palettePickerSavedColorNotification:)
                                                     name:kPalettePickerSavedColorNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_palette) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(addColor:)];
    }
    [_paletteView setDelegate:self];
    CGFloat opacity = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentAlphaPrefKey];
    _opacitySlider.value = opacity;
    [self opacityChanged:_opacitySlider];
    [self loadPalette];
}

- (CGSize)preferredContentSize {
    NSInteger colorsCount = [_paletteView.colors count];
    CGFloat rowHeight = (_paletteView.frame.size.width / 8.0f);
    CGFloat colorsHeight = rowHeight * ceil((CGFloat)(colorsCount) / 8.0f);
    return CGSizeMake(320.0f, 80.0f + colorsHeight);
}

- (void)openPickerWithColor:(FBColor *)color {
    FBPickerController *pickerController = [[FBPickerController alloc] initWithColor:color];
    [self.navigationController pushViewController:pickerController
                                         animated:YES];
}

- (void)addColor:(id)sender {
    if (![FeatureManager.shared checkSubscribtion:1 ]) {
        __weak UIViewController *weakController = self.presentingViewController;
        [self dismissViewControllerAnimated:YES
                                 completion:^{
            [UIAlertController showBlockedAlertControllerFor:weakController feature:@"Adding more colors" level:@"Lite or higher"];
        }];
        return;
    }
    [self openPickerWithColor:[[FBColor alloc] initWithRed:255
                                                     green:255
                                                      blue:255
                                                     alpha:255]];
}

- (FBColor *)selectedColor {
    if (_palette) {
        NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentColorIndexPrefKey];
        if (index > ([_palette.colors count] - 1)) {
            return 0;
        }
        return [_palette.colors objectAtIndex:index];
    } else {
        NSString *hex = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentColorPrefKey];
        UIColor *color = [UIColor fb_colorFromString:hex];
        return [[FBColor alloc] initWithUIColor:color];
    }
}

- (void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

#pragma mark -

- (IBAction)opacityChanged:(UISlider *)sender {
    UIColor *color = [UIColor fb_colorFromString:[[NSUserDefaults standardUserDefaults] objectForKey:kCurrentColorPrefKey]];
    CGFloat opacity = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentAlphaPrefKey];
    _colorBox.backgroundColor = color;
    _colorBox.alpha = sender.value;
    if (opacity != sender.value) {
        [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                                                 forKey:kCurrentAlphaPrefKey];
    }
}

- (IBAction)smoothingChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value
                                             forKey:kCurrentSmoothingPrefKey];
}

#pragma mark -

- (void)prefsDidChangeNotification:(NSNotification *)notification {
    UIColor *color = [UIColor fb_colorFromString:[[NSUserDefaults standardUserDefaults] objectForKey:kCurrentColorPrefKey]];
    float opacity = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentAlphaPrefKey];
    _colorBox.backgroundColor = color;
    _colorBox.alpha = opacity;
}

- (void)palettePickerSavedColorNotification:(NSNotification *)notification {
    FBColor *color = notification.userInfo[@"color"];
    
    if (_palette) {
        [[NSUserDefaults standardUserDefaults] setInteger:_editIndex forKey:kCurrentColorIndexPrefKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[color.uiColor fb_stringValue]
                                                  forKey:kCurrentColorPrefKey];
    }

    NSMutableArray *colors = [_paletteView.colors mutableCopy];
    if (0 <= _editIndex && _editIndex < _paletteView.colors.count) {
        [colors replaceObjectAtIndex:_editIndex
                          withObject:color];
    } else {
        [colors addObject:color];
    }
    [_paletteView loadColors:colors];
    [self savePalette];
    _editIndex = -1;
}

#pragma mark -

- (void)loadPalette {
    NSMutableArray<FBColor *> *colors;
    if (_palette) {
        colors = [_palette.colors mutableCopy];
    } else {
        colors = [NSMutableArray new];
        NSArray<NSString *> *hexArray = [NSArray arrayWithContentsOfFile:_paletteFilePath];
        for (NSString *hex in hexArray) {
            [colors addObject:[[FBColor alloc] initWithUIColor:[UIColor fb_colorFromString:hex]]];
        }
    }
    [_paletteView loadColors:colors];
}

- (void)savePalette {
    if (_palette) {
        for (NSInteger i = 0; i < _palette.colors.count; i++) {
            if (i < _paletteView.colors.count) {
                [_palette replaceColorAtIndex:i
                                    withColor:_paletteView.colors[i]];
            }
        }
    } else {
        NSMutableArray<NSString *> *hexArray = [NSMutableArray new];
        for (FBColor *color in _paletteView.colors) {
            [hexArray addObject:color.hex];
        }
        [hexArray writeToFile:_paletteFilePath
                   atomically:YES];
    }
}

#pragma mark - FBColorPaletteViewDelegate

- (void)colorPaletteViewDidSelectColor:(FBColor *)color
                               atIndex:(NSInteger)index {
    if (_palette) {
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kCurrentColorIndexPrefKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[color.uiColor fb_stringValue]
                                                  forKey:kCurrentColorPrefKey];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:kUsingEraserToolPrefKey];
    [self close];
}

- (void)colorPaletteViewDidLongSelectColor:(FBColor *)color
                                   atIndex:(NSInteger)index {
    _editIndex = index;
    [self openPickerWithColor:color];
}

@end
