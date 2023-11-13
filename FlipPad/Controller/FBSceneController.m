//
//  FBSceneController.m
//  FlipBookPad
//
//  Created by Manton Reece on 3/9/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBSceneController.h"

#import "Header-Swift.h"
#import "FBColorsController.h"
#import "FBCell.h"
#import "FBConstants.h"
#import "FBPlayerView.h"
#import "FBXsheetController.h"
#import "FBSceneDocument.h"
#import "FBMovieExporter.h"
#import "NSString_Extras.h"
#import "UIToolbar_Extras.h"
#import "NSURL_Extras.h"
#import "FBLimits.h"
#import "FBPencilController.h"
#import "FBEraserController.h"
#import "FBPalettesController.h"
#import "FBInfoController.h"
#import "FBHistoryImage.h"
#import "FBButton.h"
#import "FBHelpController.h"
#import "UIColor_Extras.h"
#import "NSDictionary_Extras.h"
#import "UIViewController_Extras.h"
#import "FBLightboxController.h"
#import "UIImage_Extras.h"
#import "FBPrefs.h"
#import "FBMacros.h"
#import "SRToolsItemConfiguration.h"
#import "Name.h"
#import "FBDGCSceneDatabase.h"

#if TARGET_OS_MACCATALYST
#import <UIKit/NSToolbar+UIKitAdditions.h>
#import <AppKit/NSToolbarItemGroup.h>
#import "SRImageToolbarItem.h"

///constants ids
#define kExitItem @"ExitSceneItem"
#define kHideXsheetItem @"HideXsheetItem"
#define kTitleItem @"TitleItem"
#define kUndoItem @"UndoItem"
#define kRedoItem @"RedoItem"
#define kToolItem @"ToolItem"
#define kEraserItem @"EraserItem"
#define kPalleteItem @"PalleteItem"
#define kLightBoxItem @"LightBoxItem"
#endif

@import MobileCoreServices;

#define kLightboxButtonTag 1
#define kUndoButtonTag 2
#define kRedoButtonTag 3
#define kPaletteButtonTag 4
#define kXsheetButtonTag 5
#define kPercentButtonTag 100
#define kLoopButtonTag 101
#define kLoopPaddingTag 107
#define kPlayPauseButtonTag 102
#define kUnwindButtonTag 103
#define kFastforwardButtonTag 104

#define kPencilToolTag 108
#define kEraserToolTag 109
#define kFillToolTag 110
#define kLassoToolTag 111

#define kHasUsedXsheetPrefKey @"HasUsedXsheet"

typedef void (^FBExportStillsCompletionBlock)(UIImage* img, NSString* filename);
typedef void (^FBExportFinishedCompletionBlock)(NSArray* images);

@interface FBExportedImage : NSObject

@property (strong) UIImage* image;
@property (strong) NSString* filename;

@end

@implementation FBExportedImage

@end

//typedef NS_ENUM(NSUInteger, FBSceneState) {
//    FBSceneStateEditing,
//    FBSceneStatePlaying,
//    FBSceneStatePaused,
//};

@interface FBSceneController () <FBBrushCircleViewDelegate, FBTransformingSceneViewDelegate, FBSlideViewDelegate>

#if TARGET_OS_MACCATALYST
@property (strong, nonatomic) UIBarButtonItem* undoCatalystButton;
@property (strong, nonatomic) UIBarButtonItem* redoCatalystButton;
@property (strong, nonatomic) UIBarButtonItem* eraserCatalystButton;
@property (strong, nonatomic) UIBarButtonItem* lightBoxOptionsCatalystButton;

@property (strong, nonatomic) UIView* lightBoxOptionsCatalystView;
@property (strong, nonatomic) UIView* palleteOptionsCatalystView;
@property (strong, nonatomic) UIView* pencilOptionsCatalystView;
@property (strong, nonatomic) UIView* eraserOptionsCatalystView;
@property (strong, nonatomic) UIView* fillOptionsCatalystView;

@property (strong, nonatomic) NSLayoutConstraint* trailingPencilSettingsCatalystConstraint;
@property (strong, nonatomic) NSLayoutConstraint* trailingEraserSettingsCatalystConstraint;
@property (strong, nonatomic) NSLayoutConstraint* trailingFillSettingsCatalystConstraint;
#endif

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sketchViewTopConstraint;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

//@property (assign, nonatomic) FBSceneState state;

@property (assign, nonatomic) CGFloat FPS;
@property (assign, nonatomic) CGFloat soundOffset;
@property (assign, nonatomic) CGFloat numberOfRows;
@property (assign, nonatomic) CGFloat lastSliderPosition;
@property (assign, nonatomic) NSTimeInterval lastSliderPositionUpdateTimestamp;

@property (weak, nonatomic) IBOutlet UIView *playbackSliderView;
@property (weak, nonatomic) IBOutlet UISlider *playbackPositionSlider;

@property (strong, nonatomic) id<ImageCaptureController> imageCaptureController;

@property (strong, nonatomic) SoundScrubPlayer* soundScrubPlayer;

@property (strong, nonatomic) TouchLockingView* touchLockingView;
@property (strong, nonatomic) FBSlideView* sideSlideXSheetView;

@property (strong, nonatomic) FBBrushCircleView *brushCircleView;

@end

#pragma mark -

@implementation FBSceneController

@synthesize document = fDocument;
@synthesize xsheetController = fXsheetController;
@synthesize titleButton = fTitleButton;

- (BOOL)isPlaying
{
    return _state == FBSceneStatePlaying;
}

#pragma mark -

- (id) initWithDocument:(FBSceneDocument *)inDocument
{
    self = [super initWithNibName:@"Scene" bundle:nil];
    if (self) {
        self.document = inDocument;

        [self configureScrubSoundPlayers];
        
        // State
        self.state = FBSceneStateEditing;
        
        if ([self.document.database isKindOfClass:[FBDGCSceneDatabase class]]) {
            // DGC
            DGC* dgc = [(FBDGCSceneDatabase*)(self.document.database) getDGC];
            NSInteger level = [self.xsheetController selectedItem].item;
            FBColorsController* colorsController = [[FBColorsController alloc] initWithDGCFile:dgc level:level];
            [self setColorsController:colorsController];
        } else {
            // DCFB
            FBColorsController* colorsController = [[FBColorsController alloc] initWithPaletteFile:[FBPalettesController getLastPalette]];
            [self setColorsController:colorsController];
        }
        
//        if (@available(iOS 11.0, macCatalyst 14.0, *)) {
//            self.imageCaptureController = [FullImageCaptureController new];
//        } else {
//            self.imageCaptureController = [LimitedImageCaptureController new];
//        }
        
        self.touchLockingView = [TouchLockingView new];
        [self.touchLockingView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.touchLockingView setTarget:self];
        [self.touchLockingView setAction:@selector(tryToTouchLockingView)];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    _versionLabel.text = [NSString stringWithFormat:@"%@ (%@)", appVersion, buildNumber];
    
    self.isEditingEnabled = NO;
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUsingLassoToolPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CanDraw"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    fCels = [[NSMutableDictionary alloc] initWithCapacity:50];

    self.topToolbar.tintColor = [UIColor colorWithRed:0.899 green:0.936 blue:0.984 alpha:1.000];
    self.bottomPlaybackToolbar.tintColor = [UIColor colorWithRed:0.899 green:0.936 blue:0.984 alpha:1.000];
    
    [self.bottomImageCaptureToolbar setHidden:YES];

    [self setupGestures];
    [self setupSketchView];
    [self setupHelp];

    if ([Config floatingToolbars]) {
        [self configureFloatingToolbars];
        [self.bottomPlaybackToolbar removeFromSuperview];
        [self.playbackSliderView removeFromSuperview];
        [self.topToolbar removeFromSuperview];
    #if TARGET_OS_MACCATALYST
        [self setDrawingToolbarDocName:[self.document displayName]];
    #endif
    } else {
    #if TARGET_OS_MACCATALYST
        [self setupCatalystButtons];
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
        [self.topToolbar removeFromSuperview];
    #else
        _sketchViewTopConstraint.constant = 44.0;
    #endif
    }
    
    [self setupPlaybackToolbar];
    [self updateToolButtons];
    [self updatePlayPauseButton];
    [self refreshToolbar];
    
    [self resetDrawingTool];
    
    [self updateTitleButton];
    
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        [self updateLightboxButton];
    }
#else
    [self updateLightboxButton];
#endif
    
    [self updateUndoButtons];
    [self updateLoopButton];
    [self updatePaletteButton];
    [self setPlayPauseButton];

    [self setupNotifications];
    
//    [self configureXsheet];
    [self configureBrushPuck];
    
    [self configureToolControllers];
    
#if TARGET_OS_MACCATALYST
    [MenuAssembler setState: StateDrawing];
    [MenuAssembler rebuild];
#endif
    [[_transformingSceneView.leadingAnchor constraintEqualToAnchor: self.view.leadingAnchor constant: 0] setActive: YES];
    [[_transformingSceneView.trailingAnchor constraintEqualToAnchor: self.view.trailingAnchor constant: 0] setActive: YES];
    [self setupSideSlideXSheetView];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    NSDictionary *dict = [fDocument.database getCurrentSettings];
    [[NSUserDefaults standardUserDefaults] setValuesForKeysWithDictionary:dict];
    [[NSUserDefaults standardUserDefaults] setValue: [self.document displayName] forKey:kLastSceneName];
}

- (void) viewDidAppear:(BOOL)inAnimated
{
    [super viewDidAppear:inAnimated];
    
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    
//    [self showXsheet];
    if (![FBPrefs boolFor:kHasUsedXsheetPrefKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasUsedXsheetPrefKey];
        fb_dispatch_seconds (0.5, ^{
            [self showHelp];
        });
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    BOOL hasTransform = [fDocument.database getCurrentTransform:&transform];

    if (hasTransform) {
        [_transformingSceneView applyTransform:transform animated:YES];
    } else {
        [_transformingSceneView zoomToFit:YES];
    }
        
    if (self.document.isAudioMissing) {
        [self showAlertWithTitle:@"The audio file is missing!"
                      andMessage:@"You must place the audio file in folder with this DGC document!"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:self];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveSettingsIntoProject];

    if (self.presentedViewController.class != [FBLandscapeImagePickerController class]) {
        if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
            [self hideAllPopovers];
        }
    }
    
    [self.sideSlideXSheetView hide];
    if (self.state == FBSceneStatePlaying) {
        [self.drawingView pauseSequenceWithFrameUpdate:NO];
    }
    [self.drawingView saveChanges];
    // To refresh thumbnail.
    [self.delegate sceneControllerWillCloseForDocumentAtPath:[self.document filePath]];
}

-(void)saveSettingsIntoProject
{
    
    CGAffineTransform dbTransform = [_transformingSceneView getTransform];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[kCurrentColorPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentColorPrefKey];
    dict[kCurrentBrushPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentBrushPrefKey];
    dict[kMinimumLineWidthsPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kMinimumLineWidthsPrefKey];
    dict[kMaximumLineWidthsPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kMaximumLineWidthsPrefKey];
    dict[kCurrentEraserWidthPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentEraserWidthPrefKey];
    dict[kCurrentEraserHardnessPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentEraserHardnessPrefKey];
    dict[kCurrentAlphaPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentAlphaPrefKey];
    dict[kUsingFillToolPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kUsingFillToolPrefKey];
    dict[kUsingEraserToolPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kUsingEraserToolPrefKey];
    dict[kUsingLassoToolPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kUsingLassoToolPrefKey];
    dict[kLightboxEnabledPrefKey] = [[NSUserDefaults standardUserDefaults] stringForKey:kLightboxEnabledPrefKey];
    
    [fDocument.database setCurrentTransform:dbTransform];
    [fDocument.database setCurrentSettings:dict];
    [fDocument.database setSelectedRow:self.xsheetController.selectedItem.row
                selectedItem:self.xsheetController.selectedItem.item];

}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

#if TARGET_OS_MACCATALYST
    _trailingPencilSettingsCatalystConstraint.constant = -286.0;
#endif
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self correctFloatingPositions];
    [self updateToolbarOrientation];
    __weak typeof(self) weakSelf = self;
    [self repositionFloatingViewIfNeededWithBlock:^{
        [weakSelf correctFloatingPositions];
        [weakSelf updateToolbarOrientation];
    }];
}

- (void)correctFloatingPositions
{
    if ([Config floatingToolbars]) {
        for (FloatingView* view in @[self.navigationToolbar,
                                     self.toolsToolbar,
                                     self.playbackToolbar]) {
            [view correctPosition];
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self configureBarTints];
}

- (BOOL) shouldAutorotate
{
    return YES;
}

- (void)orientationChanged
{
    [self configureFloatingToolbars];
    [self updateToolButtons];
    
    [self refreshToolbar];
    [self updatePaletteButton];
    [self updatePlayPauseButton];
    [self setupPlaybackToolbar];
    [self updatePaletteButton];
}

//- (UIInterfaceOrientationMask) supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscape;
//}
//
//- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationLandscapeRight;
//}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    for (UIPress* press in presses)
    {
        if (press.key == nil) {
            continue;
        }
        NSString *character = press.key.charactersIgnoringModifiers;
        BOOL isCommand = (press.key.modifierFlags & UIKeyModifierCommand) == UIKeyModifierCommand;
        BOOL isShift = (press.key.modifierFlags & UIKeyModifierShift) == UIKeyModifierShift;
        NSLog(@"Preesed key character: %@", character);        
        if ([character isEqualToString:@"h"]) { // Hand (pan)
            _transformingSceneView.mode = ModeMoving;
            _drawingView.userInteractionEnabled = NO;
            return;
        }
        if ([character isEqualToString:@"z"]) { // Zoom/Undo/Redo
            if (isCommand) {
                if (isShift) {
                    NSLog(@"Command+Shift+Z");
                    [self redo:nil];
                } else {
                    NSLog(@"Command+Z");
                    [self undo:nil];
                }
            } else {
                _transformingSceneView.mode = ModeScaling;
                _drawingView.userInteractionEnabled = NO;
            }
            return;
        }
        
        if ([character isEqualToString:@"l"] && isCommand && isShift) { // Cheat-code: show hidden resolutions
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowHiddenResolutionsNotification object:self];
        }
        
        if ([character isEqualToString:@"r"]) { // Rotate
            _transformingSceneView.mode = ModeRotating;
            _drawingView.userInteractionEnabled = NO;
            return;
        }
        // Arrows
        if ([character isEqualToString:UIKeyInputUpArrow]) {
            [self.xsheetController selectPreviousRow];
            return;
        }
        if ([character isEqualToString:UIKeyInputDownArrow]) {
            [self.xsheetController selectNextRow];
            return;
        }
        if ([character isEqualToString:UIKeyInputLeftArrow]) {
            [self.xsheetController selectNextColumn];
            return;
        }
        if ([character isEqualToString:UIKeyInputRightArrow]) {
            [self.xsheetController selectPreviousColumn];
            return;
        }
        // Page Up / Down
        if ([character isEqualToString:UIKeyInputPageUp]) {
            [self.xsheetController selectPreviousCell];
            return;
        }
        if ([character isEqualToString:UIKeyInputPageDown]) {
            [self.xsheetController selectNextCell];
            return;
        }
        if (isCommand && [character isEqualToString:@"x"]) {
            NSLog(@"Command+X");
            [self.xsheetController cut:nil];
        }
        if (isCommand && [character isEqualToString:@"c"]) {
            NSLog(@"Command+C");
            [self.xsheetController copy:nil];
        }
        if (isCommand && [character isEqualToString:@"v"]) {
            NSLog(@"Command+V");
            [self.xsheetController paste:nil];
        }
    }
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    _transformingSceneView.mode = ModeUndefined;
    _drawingView.userInteractionEnabled = YES;
}

#pragma mark -

- (void)configureFloatingToolbars
{
    if (self.navigationToolbar != nil) {
        [self.navigationToolbar removeFromSuperview];
    }
    if (self.toolsToolbar != nil) {
        [self.toolsToolbar removeFromSuperview];
    }
    if (self.playbackToolbar != nil) {
        [self.playbackToolbar removeFromSuperview];
    }

    
    BOOL isRTL = [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
    BOOL isInvertedXsheet = [SettingsBundleHelper xsheetLocation] == XSheetLocationTrailing;
    BOOL isPortrait = (UIDevice.currentDevice.orientation == UIDeviceOrientationPortrait);
    
    // Navigation
    
    NSMutableArray* navItems = [[self.topToolbar.items subarrayWithRange:NSMakeRange(0, 7)] mutableCopy];
    
    [navItems replaceObjectAtIndex:1 withObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [navItems replaceObjectAtIndex:3 withObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [navItems replaceObjectAtIndex:5 withObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    CGFloat naviagtionToolBarLength;
    CGFloat toolsToolBarLength;
    CGFloat playBackToolBarLength;
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        naviagtionToolBarLength = 220.0;
        toolsToolBarLength = 350.0;
        playBackToolBarLength = 430;
    } else {
        naviagtionToolBarLength = 250.0;
        toolsToolBarLength = 450.0;
        playBackToolBarLength = isPortrait ? 540.0f : 580.0f;
    }
    
    ToolsToolbarView* navigationToolbar = [[ToolsToolbarView alloc] initWithItems:navItems length: naviagtionToolBarLength];
    if (SettingsBundleHelper.navigationToolbarPosition.x > -1000) {
        navigationToolbar.position = SettingsBundleHelper.navigationToolbarPosition;
    } else {
        if (isInvertedXsheet) {
            [navigationToolbar setPosition:CGPointMake(isRTL ? 0.0 : 1.0, 0.02)];
            [navigationToolbar setAnchor:AnchorTopTrailing];
        } else {
            [navigationToolbar setPosition:CGPointMake(isRTL ? 1.0 : 0.0, 0.02)];
            [navigationToolbar setAnchor:AnchorTopLeading];
        }
    }
    self.navigationToolbar = navigationToolbar;
    [_transformingSceneView addSubview:navigationToolbar];
    
    
    // Tools
    
    NSUInteger palette_index = [self indexForButtonWithTag:kPaletteButtonTag inButtons:self.topToolbar.items];
    NSMutableArray* toolsItems = [[self.topToolbar.items subarrayWithRange:NSMakeRange(palette_index, self.topToolbar.items.count - palette_index)] mutableCopy];
    
    [toolsItems replaceObjectAtIndex:1 withObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [toolsItems replaceObjectAtIndex:(toolsItems.count - 3) withObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    ToolsToolbarView* toolsToolbar = [[ToolsToolbarView alloc] initWithItems:toolsItems length: toolsToolBarLength];
    
    if (SettingsBundleHelper.instrumentToolbarPosition.x > -1000) {
        toolsToolbar.position = SettingsBundleHelper.instrumentToolbarPosition;
    } else {
        if (isInvertedXsheet) {
            [toolsToolbar setPosition:CGPointMake(isRTL ? 0.98 : 0.02, isPortrait ? 0.1 : 0.02)];
            [toolsToolbar setAnchor:AnchorTopLeading];
        } else {
            [toolsToolbar setPosition:CGPointMake(isRTL ? 0.02 : 0.98, isPortrait ? 0.1 : 0.02)];
            [toolsToolbar setAnchor:AnchorTopTrailing];
        }
    }
    self.toolsToolbar = toolsToolbar;
    [_transformingSceneView addSubview:toolsToolbar];
    
    
    // Playback
    
    PlaybackToolbarView* playbackToolbar = [[PlaybackToolbarView alloc] initWithItems:[self.bottomPlaybackToolbar.items mutableCopy] length: playBackToolBarLength];
    if (SettingsBundleHelper.playBackToolBarPosition.x > -1000) {
        playbackToolbar.position = SettingsBundleHelper.playBackToolBarPosition;
    } else {
        [playbackToolbar setPosition:CGPointMake(0.5, 0.9)];
    }
    
    self.playbackToolbar = playbackToolbar;
    self.playbackPositionSlider = playbackToolbar.slider;
    [_transformingSceneView addSubview:playbackToolbar];
    
    [self.view layoutSubviews];
    [self correctFloatingPositions];
    [self configureBarTints];
}

- (void)configureBarTints {
    UIColor* tintColor;
    switch ([self.view.traitCollection userInterfaceStyle]) {
        case UIUserInterfaceStyleDark:
            tintColor = [UIColor whiteColor];
            break;
        default:
            tintColor = [UIColor blackColor];
            break;
    }
    
    if ([Config floatingToolbars]) {
        for (UIView* toolbar in @[self.navigationToolbar, self.toolsToolbar, self.playbackToolbar]) {
            [toolbar setTintColor:tintColor];
        }
    } else {
        self.topToolbar.tintColor = [UIColor whiteColor];
        self.bottomPlaybackToolbar.tintColor = [UIColor whiteColor];
    }
}

#if TARGET_OS_MACCATALYST
-(void) setupCatalystButtons
{
    UIImage* undoIcon = [UIImage imageNamed:@"undo_icon"];
    UIImage* redoIcon = [UIImage imageNamed:@"redo_icon"];
    _undoCatalystButton = [[UIBarButtonItem alloc] initWithImage:[undoIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(undo:)];
    _redoCatalystButton = [[UIBarButtonItem alloc] initWithImage:[redoIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(redo:)];
    _lightBoxOptionsCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gear"] style:UIBarButtonItemStyleDone target:self action:@selector(showLightboxOptions)];
    _eraserCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_erase_off_catalyst"] style:UIBarButtonItemStyleDone target:self action:@selector(toggleEraserTool)];
    
    _palleteOptionsCatalystView = [[UIView alloc] initWithFrame: CGRectZero];
    _palleteOptionsCatalystView.translatesAutoresizingMaskIntoConstraints = NO;
    _lightBoxOptionsCatalystView = [[UIView alloc] initWithFrame: CGRectZero];
    _lightBoxOptionsCatalystView.translatesAutoresizingMaskIntoConstraints = NO;
    _pencilOptionsCatalystView = [[UIView alloc] initWithFrame: CGRectZero];
    _pencilOptionsCatalystView.translatesAutoresizingMaskIntoConstraints = NO;
    _eraserOptionsCatalystView = [[UIView alloc] initWithFrame: CGRectZero];
    _eraserOptionsCatalystView.translatesAutoresizingMaskIntoConstraints = NO;
    _fillOptionsCatalystView = [[UIView alloc] initWithFrame: CGRectZero];
    _fillOptionsCatalystView.translatesAutoresizingMaskIntoConstraints = NO;

    [[self view] addSubview:_lightBoxOptionsCatalystView];
    [[self view] addSubview:_palleteOptionsCatalystView];
    [[self view] addSubview:_pencilOptionsCatalystView];
    [[self view] addSubview:_eraserOptionsCatalystView];
    [[self view] addSubview:_fillOptionsCatalystView];

    [[[_lightBoxOptionsCatalystView widthAnchor] constraintEqualToConstant:60.0] setActive:YES];
    [[[_palleteOptionsCatalystView widthAnchor] constraintEqualToConstant:60.0] setActive:YES];
    [[[_pencilOptionsCatalystView widthAnchor] constraintEqualToConstant:60.0] setActive:YES];
    [[[_eraserOptionsCatalystView widthAnchor] constraintEqualToConstant:60.0] setActive:YES];
    [[[_fillOptionsCatalystView widthAnchor] constraintEqualToConstant:60.0] setActive:YES];

    [[[_lightBoxOptionsCatalystView heightAnchor] constraintEqualToConstant:6.0] setActive:YES];
    [[[_palleteOptionsCatalystView heightAnchor] constraintEqualToConstant:6.0] setActive:YES];
    [[[_pencilOptionsCatalystView heightAnchor] constraintEqualToConstant:6.0] setActive:YES];
    [[[_eraserOptionsCatalystView heightAnchor] constraintEqualToConstant:6.0] setActive:YES];
    [[[_fillOptionsCatalystView heightAnchor] constraintEqualToConstant:6.0] setActive:YES];
    
    if (@available(iOS 11, *)) {
        UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
        [[_lightBoxOptionsCatalystView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
        [[[_lightBoxOptionsCatalystView leadingAnchor] constraintEqualToAnchor:self.view.leadingAnchor constant:182.0] setActive:YES];
        
        [[_palleteOptionsCatalystView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
        [[[_palleteOptionsCatalystView trailingAnchor] constraintEqualToAnchor:self.view.trailingAnchor constant:-408.0] setActive:YES];
        
        [[_pencilOptionsCatalystView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
        _trailingPencilSettingsCatalystConstraint = [_pencilOptionsCatalystView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-300.0];
        [_trailingPencilSettingsCatalystConstraint setActive:YES];
        
        [[_eraserOptionsCatalystView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
        _trailingEraserSettingsCatalystConstraint = [_eraserOptionsCatalystView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-250.0];
        [_trailingEraserSettingsCatalystConstraint setActive:YES];
        
        [[_fillOptionsCatalystView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
        _trailingFillSettingsCatalystConstraint = [_fillOptionsCatalystView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-200.0];
        [_trailingFillSettingsCatalystConstraint setActive:YES];
    }
}
#endif

- (void)setupPlaybackToolbar
{
    [_playbackPositionSlider setThumbImage:[UIImage imageNamed:@"thumb_20"] forState:UIControlStateNormal];
    [_playbackPositionSlider addTarget:self action:@selector(scenePlaybackPositionChanged:) forControlEvents:UIControlEventValueChanged];
    [_playbackPositionSlider addTarget:self action:@selector(scenePlaybackPositionChangeStarted) forControlEvents:(UIControlEventTouchDown)];
    [_playbackPositionSlider addTarget:self action:@selector(scenePlaybackPositionChangeEnded) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
}

- (void)updateToolButtons
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[self.toolsToolbar items] mutableCopy];
    } else {
        items = [[self.topToolbar items] mutableCopy];
    }
    
    NSUInteger pencil_index = [self indexForButtonWithTag:kPencilToolTag inButtons:items];
    NSUInteger eraser_index = [self indexForButtonWithTag:kEraserToolTag inButtons:items];
    NSUInteger fill_index   = [self indexForButtonWithTag:kFillToolTag inButtons:items];
    NSUInteger lasso_index  = [self indexForButtonWithTag:kLassoToolTag inButtons:items];
    
    // Pencil
    UIImageView* pencilImageView = [[UIImageView alloc] initWithImage:_pencilItem.image];
    if (pencilImageView.image) {
        [self setPencilItemImageView:pencilImageView];
    }
    UILongPressGestureRecognizer* pencilLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                                   action:@selector(pencilLongPressAction:)];
    [pencilImageView addGestureRecognizer:pencilLongPressGestureRecognizer];
    UITapGestureRecognizer* pencilTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(pencilPressed:)];
    [pencilImageView addGestureRecognizer:pencilTapGestureRecognizer];
    UIBarButtonItem* pencilItem = [[UIBarButtonItem alloc] initWithCustomView:self.pencilItemImageView];
    [pencilItem setTag:kPencilToolTag];
    [self setPencilItem:pencilItem];
    
    // Eraser
    UIImageView* eraserImageView = [[UIImageView alloc] initWithImage:_eraserItem.image];
    if (eraserImageView.image) {
        [self setEraserItemImageView:eraserImageView];
    }
    UILongPressGestureRecognizer* eraserLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                                   action:@selector(eraserLongPressAction:)];
    [eraserImageView addGestureRecognizer:eraserLongPressGestureRecognizer];
    UITapGestureRecognizer* eraserTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(eraserPressed:)];
    [eraserImageView addGestureRecognizer:eraserTapGestureRecognizer];
    UIBarButtonItem* eraserItem = [[UIBarButtonItem alloc] initWithCustomView:self.eraserItemImageView];
    [eraserItem setTag:kEraserToolTag];
    [self setEraserItem:eraserItem];
    
    // Fill
    UIImageView* fillImageView = [[UIImageView alloc] initWithImage:_fillItem.image];
    if (fillImageView.image) {
        [self setFillItemImageView:fillImageView];
    }
    UILongPressGestureRecognizer* fillLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                                 action:@selector(fillLongPressAction:)];
    [fillImageView addGestureRecognizer:fillLongPressGestureRecognizer];
    UITapGestureRecognizer* fillTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(fillPressed:)];
    [fillImageView addGestureRecognizer:fillTapGestureRecognizer];
    UIBarButtonItem* fillItem = [[UIBarButtonItem alloc] initWithCustomView:self.fillItemImageView];
    [fillItem setTag:kFillToolTag];
    [self setFillItem:fillItem];
    
    // Lasso
    UIImageView* lassoImageView = [[UIImageView alloc] initWithImage:_lassoItem.image];
    if (lassoImageView.image) {
        [self setLassoItemImageView:lassoImageView];
    }
    UITapGestureRecognizer* lassoTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(lassoPressed:)];
    [lassoImageView addGestureRecognizer:lassoTapGestureRecognizer];
    UIBarButtonItem* lassoItem = [[UIBarButtonItem alloc] initWithCustomView:self.lassoItemImageView];
    [lassoItem setTag:kLassoToolTag];
    [self setLassoItem:lassoItem];
    
    CGFloat rotationAngle = -90 * M_PI / 180;
    CGAffineTransform rotationTransfor = CGAffineTransformMakeRotation(rotationAngle);
    CGAffineTransform defaultState = CGAffineTransformMakeRotation(0);
    
    if (SettingsBundleHelper.verticalToolbar) {
        pencilItem.customView.transform = rotationTransfor;
        eraserItem.customView.transform = rotationTransfor;
        fillItem.customView.transform   = rotationTransfor;
        lassoItem.customView.transform  = rotationTransfor;
    } else {
        pencilItem.customView.transform = defaultState;
        eraserItem.customView.transform = defaultState;
        fillItem.customView.transform   = defaultState;
        lassoItem.customView.transform  = defaultState;
    }
    
    [items replaceObjectAtIndex:pencil_index withObject:pencilItem];
    [items replaceObjectAtIndex:eraser_index withObject:eraserItem];
    [items replaceObjectAtIndex:fill_index withObject:fillItem];
    [items replaceObjectAtIndex:lasso_index withObject:lassoItem];
    
    if ([Config floatingToolbars]) {
        [self.toolsToolbar setItems:items];
    } else {
        [self.topToolbar setItems:items];
    }
}

- (void) showHelp
{
    if (FBIsPhone()) {
        return;
    }

    self.helpController = [[FBHelpController alloc] initWithHelpPane:kHelpPaneXsheet];

    self.helpController.modalPresentationStyle = UIModalPresentationPopover;
    self.helpController.popoverPresentationController.barButtonItem = self.xsheetButton;
    self.helpController.popoverPresentationController.backgroundColor = self.helpController.view.backgroundColor;
    self.helpController.popoverPresentationController.delegate = self;
}

- (void) setupSketchView {
    CGRect rect;
    rect.origin = CGPointMake(0.0f, 0.0f);
    rect.size = [fDocument resolutionSize];
    _drawingView = [[FBDrawingView alloc] initWithFrame:rect];
    _contentView = [[FBSceneContentView alloc] initWithFrame:rect];
    _drawingView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_drawingView setBackgroundColor:[UIColor clearColor]];
    [_contentView setBackgroundColor:[UIColor whiteColor]];
    [_contentView addSubview:_drawingView];
    [[_contentView.leftAnchor constraintEqualToAnchor:_drawingView.leftAnchor] setActive:YES];
    [[_contentView.topAnchor constraintEqualToAnchor:_drawingView.topAnchor] setActive:YES];
    [[_contentView.rightAnchor constraintEqualToAnchor:_drawingView.rightAnchor] setActive:YES];
    [[_contentView.bottomAnchor constraintEqualToAnchor:_drawingView.bottomAnchor] setActive:YES];
    [_drawingView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:_drawingView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:rect.size.width],
        [NSLayoutConstraint constraintWithItem:_drawingView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:rect.size.height]
    ]];
    [_drawingView setSceneController:self];
    [_drawingView setDrawingDelegate:self.xsheetController];
    [self.xsheetController setDrawingView:_drawingView];
    _transformingSceneView.delegate = self;
    [_transformingSceneView setSourceView:_contentView];
    [_drawingView configure];
}

- (void)addLassoView
{
    if (_lassoView) {
        return;
    }
    
    CGRect sketch_r;
    sketch_r.origin = CGPointMake (0, 0);
    sketch_r.size = [fDocument resolutionSize];
    
    self.lassoView = [[FBLassoView alloc] initWithFrame:sketch_r];
    [self.lassoView setDelegate:self];
    [self.lassoView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentView addSubview:self.lassoView];
    
    NSLayoutConstraint* leftConstraint = [self.contentView.leftAnchor constraintEqualToAnchor:self.lassoView.leftAnchor];
    [leftConstraint setActive:YES];
    NSLayoutConstraint* topConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.lassoView.topAnchor];
    [topConstraint setActive:YES];
    NSLayoutConstraint* rightConstraint = [self.contentView.rightAnchor constraintEqualToAnchor:self.lassoView.rightAnchor];
    [rightConstraint setActive:YES];
    NSLayoutConstraint* bottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.lassoView.bottomAnchor];
    [bottomConstraint setActive:YES];
    
    [self.lassoView configure];
}

- (void)removeLassoView
{
    [self willStartSelecting];
    if (_lassoView) {
        [self.lassoView removeFromSuperview];
        [self setLassoView:nil];
    }
}

- (void)installCapturePreviewView
{
    UIView* _capturePreviewView = [_imageCaptureController previewView];
    if (!_capturePreviewView) {
        return;
    }
    
    if ([_capturePreviewView superview] != nil) {
        return;
    }
    [_capturePreviewView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIView* capturePreviewViewContainer = [UIView new];
    [capturePreviewViewContainer setBackgroundColor:[UIColor whiteColor]];
    [capturePreviewViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [capturePreviewViewContainer addSubview:_capturePreviewView];
    [[capturePreviewViewContainer.topAnchor constraintEqualToAnchor:_capturePreviewView.topAnchor] setActive:YES];
    [[capturePreviewViewContainer.bottomAnchor constraintEqualToAnchor:_capturePreviewView.bottomAnchor] setActive:YES];
    [[capturePreviewViewContainer.leftAnchor constraintEqualToAnchor:_capturePreviewView.leftAnchor] setActive:YES];
    [[capturePreviewViewContainer.rightAnchor constraintEqualToAnchor:_capturePreviewView.rightAnchor] setActive:YES];
    
    [_contentView addSubview:capturePreviewViewContainer];
    [[_contentView.topAnchor constraintEqualToAnchor:capturePreviewViewContainer.topAnchor] setActive:YES];
    [[_contentView.bottomAnchor constraintEqualToAnchor:capturePreviewViewContainer.bottomAnchor] setActive:YES];
    [[_contentView.leftAnchor constraintEqualToAnchor:capturePreviewViewContainer.leftAnchor] setActive:YES];
    [[_contentView.rightAnchor constraintEqualToAnchor:capturePreviewViewContainer.rightAnchor] setActive:YES];
}

- (void)removeCapturePreviewView
{
    UIView* _capturePreviewView = [_imageCaptureController previewView];
    if (!_capturePreviewView) {
        return;
    }
    
    [_capturePreviewView.superview removeFromSuperview];
}

- (void)tryToTouchLockingView
{
    if ([fXsheetController.selectedItem mode] == Item) {
        NSInteger row = [fXsheetController.selectedItem row] - 1;
        NSInteger item = [fXsheetController.selectedItem item] - 1;
        XSheetTableCell* cell = [fXsheetController.fTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        [cell flashAt:item];
    }
}

- (void)lockDrawingView
{
    if ([_touchLockingView superview] != nil) {
        return;
    }
    [_contentView addSubview:_touchLockingView];
    [[_contentView.topAnchor constraintEqualToAnchor:_touchLockingView.topAnchor] setActive:YES];
    [[_contentView.bottomAnchor constraintEqualToAnchor:_touchLockingView.bottomAnchor] setActive:YES];
    [[_contentView.leftAnchor constraintEqualToAnchor:_touchLockingView.leftAnchor] setActive:YES];
    [[_contentView.rightAnchor constraintEqualToAnchor:_touchLockingView.rightAnchor] setActive:YES];
}

- (void)unlockDrawingView
{
    [_touchLockingView removeFromSuperview];
}

- (void) setupHelp
{
//    self.helpView.layer.cornerRadius = 5.0;
//    self.helpView.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.helpView.layer.shadowOpacity = 0.1;
    self.helpView.hidden = YES;
    self.helpScrollView.layer.cornerRadius = 5.0;
    self.helpScrollViewBackground.layer.cornerRadius = 5.0;
    self.helpScrollViewBackground.layer.shadowColor = [UIColor blackColor].CGColor;
    self.helpScrollViewBackground.layer.shadowOpacity = 0.1;
    self.helpScrollViewBackground.hidden = YES;
    self.helpScrollView.hidden = YES;
}

- (void) setupNotifications
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideXsheetNotification:) name:kHideXsheetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideAllPopoversNotification:) name:kHideAllPopoversNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefsDidChangeNotification:) name:NSUserDefaultsDidChangeNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortcutButtonEraserNotification:) name:kPressureShortcutEraserNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortcutButtonUndoNotification:) name:kPressureShortcutUndoNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortcutButtonRedoNotification:) name:kPressureShortcutRedoNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPencilOptions:) name:kShowPencilOptionsNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newRowAddedCurrentCellNotification:) name:kNewRowAddedCellNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playUpdateForPausedNotification:) name:kPlayUpdateForPausedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneResolutionChangedNotification:) name:kSceneResolutionChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelpNotification:) name:kShowHelpNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUndoButtons) name:NSUndoManagerDidUndoChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUndoButtons) name:NSUndoManagerDidRedoChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toolBarPositionChanged)
                                                 name:kToolBarPositionChanged
                                               object:nil];
}

- (void)toolBarPositionChanged {
    __weak typeof(self) weakSelf = self;
    [self repositionFloatingViewIfNeededWithBlock:^{
        [weakSelf saveToolBarsPosition];
    }];
}

- (void)saveToolBarsPosition {
    SettingsBundleHelper.instrumentToolbarPosition = _toolsToolbar.position;
    SettingsBundleHelper.navigationToolbarPosition = _navigationToolbar.position;
    SettingsBundleHelper.playBackToolBarPosition   = _playbackToolbar.position;
}

- (void) setupGestures
{
    fSwipePreviousGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePrevious:)];
    fSwipePreviousGesture.direction = UISwipeGestureRecognizerDirectionDown;
    fSwipePreviousGesture.numberOfTouchesRequired = 3;
    fSwipePreviousGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:fSwipePreviousGesture];
    
    fSwipeNextGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeNext:)];
    fSwipeNextGesture.direction = UISwipeGestureRecognizerDirectionUp;
    fSwipeNextGesture.numberOfTouchesRequired = 3;
    fSwipeNextGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:fSwipeNextGesture];

    fSwipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    fSwipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    fSwipeLeftGesture.numberOfTouchesRequired = 3;
    fSwipeLeftGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:fSwipeLeftGesture];

    fSwipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    fSwipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    fSwipeRightGesture.numberOfTouchesRequired = 3;
    fSwipeRightGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:fSwipeRightGesture];
    
    for (id gesture_recognizer in _transformingSceneView.gestureRecognizers) {
        if ([gesture_recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            UIPanGestureRecognizer* pan_gr = gesture_recognizer;
            pan_gr.minimumNumberOfTouches = 2;
            pan_gr.maximumNumberOfTouches = 2;
            [pan_gr requireGestureRecognizerToFail:fSwipePreviousGesture];
            [pan_gr requireGestureRecognizerToFail:fSwipeNextGesture];
            [pan_gr requireGestureRecognizerToFail:fSwipeLeftGesture];
            [pan_gr requireGestureRecognizerToFail:fSwipeRightGesture];
        }
    }
    NSString* tapPlay_PauseName = @"tapPlay_Pause";
    NSString* panSelectFrameName = @"panSelectFrame";
    UITapGestureRecognizer* play_pauseTapGesture = [[UITapGestureRecognizer alloc]initWithTarget: self
                                                                                          action: @selector(tapPlay_PauseSceneAction:)];
    play_pauseTapGesture.name = tapPlay_PauseName;
    play_pauseTapGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:play_pauseTapGesture];
    
    UIPanGestureRecognizer* frameSelectionPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                               action: @selector(swipeBetweenFramesAction:)];
    frameSelectionPanGesture.name = panSelectFrameName;
    frameSelectionPanGesture.delegate = self;
    [_transformingSceneView addGestureRecognizer:frameSelectionPanGesture];
}

- (void) tapPlay_PauseSceneAction: (UITapGestureRecognizer* )sender {
    CGPoint playbackViewLocation = [sender locationInView: _playbackToolbar];
    if (![_playbackToolbar hitTest:playbackViewLocation withEvent:NULL]) {
        if (self.state == FBSceneStatePlaying) {
            [self pauseScene: NULL];
        } else if (self.state == FBSceneStatePaused) {
            [self playScene: NULL];
        }
    }
}

CGPoint startLocation;
NSInteger selectedIndex;
NSInteger endedIndex;
bool isNoHitPlaybackToolBar = YES;

- (void) swipeBetweenFramesAction:(UIPanGestureRecognizer* )sender {
    if (self.state == FBSceneStatePaused) {
        CGPoint location = [sender locationInView:_transformingSceneView];
        if (sender.state == UIGestureRecognizerStateBegan) {
            CGPoint playbackViewLocation = [sender locationInView: _playbackToolbar];
            isNoHitPlaybackToolBar = ![_playbackToolbar hitTest: playbackViewLocation
                                          withEvent:NULL];
            startLocation = location;
            selectedIndex = self.xsheetController.selectedItem.row - 1;
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            if (isNoHitPlaybackToolBar) {
                CGFloat xLocation = location.x;
                CGFloat sceneWidth = _transformingSceneView.frame.size.width;
                NSInteger numberOfRows = [self.document.storage numberOfRows];
                
                CGFloat value = sceneWidth / numberOfRows * 0.5f;
                CGFloat delta = xLocation - startLocation.x;
                int appendIndex = (int)delta / (int)value;
                NSInteger newIndex = selectedIndex + appendIndex;
                if (newIndex < 0) {
                    newIndex = 0;
                } else if (newIndex >= numberOfRows) {
                    newIndex = numberOfRows - 1;
                }
                [self updateSliderForRow: newIndex + 1];
                endedIndex = newIndex;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showCompositedIndex: newIndex];
                });
                
            }
            
        } else if (sender.state == UIGestureRecognizerStateEnded) {
            [fXsheetController didPauseOnRow: endedIndex];
        }
    }
}

- (void)configureScrubSoundPlayers
{
    // Prepare for sound playback
    if (self.document.soundData) {
        self.soundScrubPlayer = [[SoundScrubPlayer alloc] initWithAudioData:[self.document soundData]];
    } else {
        self.soundScrubPlayer = nil;
    }
}

- (BOOL)canEnableLasso
{
    BOOL isNotLocked = ([_touchLockingView superview] == nil);
    BOOL isNotRowSelection = (fXsheetController.selectedItem.mode == Item);
    return isNotLocked && isNotRowSelection;
}

#pragma mark -

- (void) swipePrevious:(UIGestureRecognizer *)inGestureRecognizer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUsingNonDrawableGesturePrefKey];
    if (inGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJumpXsheetPreviousNotification object:self];
        [self enableDrawingAfterDelay];
    }
}

- (void) swipeNext:(UIGestureRecognizer *)inGestureRecognizer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUsingNonDrawableGesturePrefKey];
    if (inGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJumpXsheetNextNotification object:self];
        [self enableDrawingAfterDelay];
    }
}

- (void) swipeLeft:(UIGestureRecognizer *)inGestureRecognizer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUsingNonDrawableGesturePrefKey];
    if (inGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJumpXsheetRightNotification object:self];
        [self enableDrawingAfterDelay];
    }
}

- (void) swipeRight:(UIGestureRecognizer *)inGestureRecognizer
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUsingNonDrawableGesturePrefKey];
    if (inGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJumpXsheetLeftNotification object:self];
        [self enableDrawingAfterDelay];
    }
}

- (void) enableDrawingAfterDelay
{
    double delay_seconds = 0.5;
    dispatch_time_t pop_time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay_seconds * NSEC_PER_SEC));
    dispatch_after (pop_time, dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUsingNonDrawableGesturePrefKey];
    });
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)inGestureRecognizer shouldReceiveTouch:(UITouch *)inTouch
{
    NSString* tapPlay_PauseName = @"tapPlay_Pause";
    NSString* panSelectFrameName = @"panSelectFrame";
    if (inGestureRecognizer.name == tapPlay_PauseName) {
        return self.state != FBSceneStateEditing;
    } else if (inGestureRecognizer.name == panSelectFrameName) {
        return self.state == FBSceneStatePaused;
    }
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)inGestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)inOtherGestureRecognizer
{
    return YES;
}

- (void) setupSideSlideXSheetView {
    _sideSlideXSheetView = [[FBSlideView alloc] initWithFrame: CGRectZero];
    _sideSlideXSheetView.dataSource = fXsheetController;
    _sideSlideXSheetView.delegate = self;
    [self addChildViewController: fXsheetController];
    UIView* xSheetView = [fXsheetController view];
    xSheetView.layer.cornerRadius = 12.0;
    xSheetView.layer.masksToBounds = YES;
    
    [_sideSlideXSheetView setupIn: self.view
                   with: [fXsheetController view]
                     at: [SettingsBundleHelper xsheetLocation] == XSheetLocationTrailing ? SideRight : SideLeft
               isClosed: NO];
    [fXsheetController didMoveToParentViewController:self];
}

- (void) updateSideSlideXSheetView {
    [_sideSlideXSheetView updateWithSide: [SettingsBundleHelper xsheetLocation] == XSheetLocationTrailing ? SideRight : SideLeft];
}

#pragma mark - FBTransformingSceneViewDelegate

- (void)transformingSceneView:(FBTransformingSceneView *)transformingSceneView {
    [self updatePercentButtonWithZoom:transformingSceneView.scale];
    if (_pasteView) {
        [_pasteView setNeedsLayout];
        [_pasteView layoutIfNeeded];
    }
}

#pragma mark -

- (IBAction)closeScene:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setValue: @"none" forKey:kLastSceneName];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate closeDocumentWithAnimated:YES];
}

- (IBAction) showXsheet:(id)inSender
{
    if (_sideSlideXSheetView.isClosed) {
        [self.sideSlideXSheetView show];
        [self.xsheetButton setImage: [UIImage imageNamed:@"sidebar_off"]];
    } else {
        [self.sideSlideXSheetView hide];
        [self.xsheetButton setImage: [UIImage imageNamed:@"sidebar_off"]];
    }
}

- (IBAction) showColors:(id)inSender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    self.colorsNavigationController = [[UINavigationController alloc] init];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.colorsNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    } else {
        self.colorsNavigationController.modalPresentationStyle = UIModalPresentationPopover;
    }
    
    self.colorsNavigationController.popoverPresentationController.delegate = self;
    
    UIPopoverPresentationController* popover_controller = [self.colorsNavigationController popoverPresentationController];
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        CGRect r = [inSender convertRect:[inSender bounds] toView:self.view];
        self.colorsNavigationController.modalPresentationStyle = UIModalPresentationPopover;
        popover_controller.sourceRect = r;
        popover_controller.sourceView = self.view;
        popover_controller.delegate = self;
    } else {
        popover_controller.sourceView = _palleteOptionsCatalystView;
    }
#else
    CGRect r = [inSender convertRect:[inSender bounds] toView:self.view];
    popover_controller.sourceRect = r;
    popover_controller.sourceView = self.view;
    popover_controller.delegate = self;
#endif
    
    if ([self.document.database isKindOfClass:[FBDGCSceneDatabase class]]) {
        // DGC
        // Configure level?
        [self.colorsNavigationController setViewControllers:@[self.colorsController]];
        [self presentViewController:self.colorsNavigationController animated:YES completion:^{
            [FBHelpController showHelpPane:kHelpPaneColor];
        }];
    } else {
        // DCFB
        FBPalettesController* palettesController = [[FBPalettesController alloc] init];
        [self.colorsNavigationController setViewControllers:@[palettesController]];
        [self presentViewController:self.colorsNavigationController animated:YES completion:^{
            [palettesController openLastPaletteAnimated:NO];
            [FBHelpController showHelpPane:kHelpPaneColor];
        }];
    }
}

- (void)showPencilOptions:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    UINavigationController* pencilOptionsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.pencilOptionsController];;
    
    pencilOptionsNavigationController.modalPresentationStyle = UIModalPresentationPopover;
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        pencilOptionsNavigationController.popoverPresentationController.barButtonItem = self.pencilItem;
    } else {
        pencilOptionsNavigationController.popoverPresentationController.sourceView = _pencilOptionsCatalystView;
    }
#else
    pencilOptionsNavigationController.popoverPresentationController.barButtonItem = self.pencilItem;
#endif
    pencilOptionsNavigationController.popoverPresentationController.delegate = self;
    
    [self presentViewController:pencilOptionsNavigationController animated:YES completion:NULL];
}

- (void)showEraserOptions:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        self.eraserOptionsController.popoverPresentationController.barButtonItem = self.eraserItem;
    } else {
        self.eraserOptionsController.popoverPresentationController.sourceView = _eraserOptionsCatalystView;
    }
#else
    self.eraserOptionsController.popoverPresentationController.barButtonItem = self.eraserItem;
#endif
    self.eraserOptionsController.popoverPresentationController.delegate = self;
    
    [self presentViewController:self.eraserOptionsController animated:YES completion:NULL];
}

- (void)showFillOptions:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        self.fillOptionsController.popoverPresentationController.barButtonItem = self.fillItem;
    } else {
        self.fillOptionsController.popoverPresentationController.sourceView = _fillOptionsCatalystView;
    }
#else
    self.fillOptionsController.popoverPresentationController.barButtonItem = self.fillItem;
#endif
    self.fillOptionsController.popoverPresentationController.delegate = self;
    
    [self presentViewController:self.fillOptionsController animated:YES completion:NULL];
}

- (void) loadCurrentCellNotification:(NSNotification *)inNotification
{
    NSNumber* is_paused = [inNotification.userInfo objectForKey:kUpdateIsCurrentlyPausedKey];
    if (![is_paused boolValue]) {
        self.state = FBSceneStateEditing;
        [self updatePlayPauseButton];
    }
}

// FIXME: WTF is this?
- (void) clearCurrentCellNotification:(NSNotification *)inNotification
{
    NSLog(@"🔥 Fix clearing");
    [self updateUndoButtons];

    self.state = FBSceneStateEditing;
    [self updatePlayPauseButton];
}

- (void) newRowAddedCurrentCellNotification:(NSNotification *)inNotification
{
    NSLog(@"🔥 new row added");
//    [[self undoManager] removeAllActions];
//    [self.document saveUpdatedRow:inNotification.userInfo]; !!!
    [self updateUndoButtons];

    self.state = FBSceneStateEditing;
    [self updatePlayPauseButton];
}


- (void)updateSliderForRow:(NSInteger)row
{
//    if (_state != FBSceneStatePaused) {
//        return;
//    }
        
    CGFloat position = ( (CGFloat)(row - 1) / (CGFloat)([self.document.storage numberOfRows] - 1) );
    [self didMoveToRelativePosition:position];
}

- (void)didMoveToRelativePosition:(CGFloat)position
{
    BOOL isAnimated = YES;
    if (_playbackPositionSlider.value > position) {
        isAnimated = NO;
    }
    [_playbackPositionSlider setValue:position animated:isAnimated];
}

- (void)updatePause
{
    self.state = FBSceneStatePaused;
    [self updatePlayPauseButton];
}

- (void) sceneResolutionChangedNotification:(NSNotification *)inNotification
{
    [self updateResolution];
    [_transformingSceneView zoomToFit:YES];
}

- (void) showCompositedIndex:(NSInteger)index
{
    NSLog(@"show: %li", index);
    UIImage* composited_image = [self compositedImageAtRow:index+1];
    if (composited_image) {
        [self.drawingView showCompositedFrameImage:composited_image];
    }
}

- (void) showHelpNotification:(NSNotification *)notification
{
    NSInteger index = [[notification.userInfo objectForKey:kShowHelpPaneKey] integerValue];

    NSString* k = [NSString stringWithFormat:@"DidShowHelp_%ld", (long)index];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:k]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:k];
        NSString* help_file = [[NSBundle mainBundle] pathForResource:[@"Help" stringByAppendingString:kAppName] ofType:@"plist"];
        NSArray* help_strings = [NSArray arrayWithContentsOfFile:help_file];
        self.helpField.textColor = [UIColor blackColor];
        self.helpField.text = [help_strings objectAtIndex:index];
        self.helpView.alpha = 0.0;
        self.helpView.hidden = NO;
        self.helpScrollView.alpha = 0.0;
        self.helpScrollView.hidden = NO;
        self.helpScrollViewBackground.alpha = 0.0;
        self.helpScrollViewBackground.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.helpView.alpha = 1.0;
            self.helpScrollView.alpha = 1.0;
            self.helpScrollViewBackground.alpha = 1.0;
        }];
    }
}

#pragma mark -

- (NSUInteger) indexForButtonWithTag:(NSUInteger)inTag inButtons:(NSArray *)inButtons
{
    NSUInteger result = -1;
    for (NSUInteger i = 0; i < [inButtons count]; i++) {
        UIBarButtonItem* button = [inButtons objectAtIndex:i];
        if (button.tag == inTag) {
            result = i;
            break;
        }
    }
    return result;
}

- (UIBarButtonItem *) barButtonWithTag:(NSUInteger)inTag inButtons:(NSArray *)inButtons
{
    UIBarButtonItem* result = nil;
    for (NSUInteger i = 0; i < [inButtons count]; i++) {
        UIBarButtonItem* button = [inButtons objectAtIndex:i];
        if (button.tag == inTag) {
            result = button;
            break;
        }
    }
    
    return result;
}

- (void) updatePercentButtonWithZoom:(float)inScale
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[_playbackToolbar items] mutableCopy];
    } else {
        items = [[_bottomPlaybackToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kPercentButtonTag inButtons:items];
    UIBarButtonItem* zoom_item = [items objectAtIndex:index];
    zoom_item.title = [NSString stringWithFormat:@"%d%%", (int)(inScale * 100)];
    [items replaceObjectAtIndex:index withObject:zoom_item];
    
    if ([Config floatingToolbars]) {
        [self.playbackToolbar setItems:items];
    } else {
        [self.bottomPlaybackToolbar setItems:items];
    }
}

- (void) resetDrawingTool
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUsingFillToolPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUsingEraserToolPrefKey];
}

- (void) updateResolution
{
    CGRect sketch_r;
    sketch_r.origin = CGPointMake (0, 0);
    sketch_r.size = [fDocument resolutionSize];
    [self.drawingView setBounds:sketch_r];
}

- (void) updateTitleButton
{
    if (FBIsPhone()) {
        fTitleButton.title = @"";
        [fTitleButton setEnabled:NO];
    }
    else {
        fTitleButton.title = [self.document displayName];
    }
}

- (void) updateLightboxButton
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[self.navigationToolbar items] mutableCopy];
    } else {
        items = [[self.topToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kLightboxButtonTag inButtons:items];
    
    if ([FBPrefs boolFor:kLightboxEnabledPrefKey]) {
        self.lightboxButton = [[FBButton alloc] initWithImage:[UIImage imageNamed:@"toolbar_lightbox"]];
    } else {
        self.lightboxButton = [[FBButton alloc] initWithImage:[UIImage imageNamed:@"toolbar_lightbox_off"]];
    }
    
    [self.lightboxButton addTarget:self action:@selector(toggleLightbox:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* lightbox_item = [[UIBarButtonItem alloc] initWithCustomView:self.lightboxButton];
    lightbox_item.tag = kLightboxButtonTag;

    self.lightboxHoldGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showLightboxOptions)];
    self.lightboxHoldGesture.minimumPressDuration = 0.5;
    [self.lightboxButton addGestureRecognizer:self.lightboxHoldGesture];
    
    if (SettingsBundleHelper.verticalToolbar) {
        lightbox_item.customView.transform = CGAffineTransformMakeRotation(-90 * M_PI / 180);
    }
    [items replaceObjectAtIndex:index withObject:lightbox_item];
    
    if ([Config floatingToolbars]) {
        [self.navigationToolbar setItems:items];
    } else {
        [self.topToolbar setItems:items];
    }
}

- (void) updateLoopButton
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[_playbackToolbar items] mutableCopy];
    } else {
        items = [[_bottomPlaybackToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kLoopButtonTag inButtons:items];

    FBButton* loop_button = [[FBButton alloc] initWithImage:[UIImage imageNamed:@"toolbar_loop"]];
    if ([FBPrefs boolFor:kLoopEnabledPrefKey]) {
        loop_button.customBackgroundAlpha = 0.3;
    }
    else {
        loop_button.customBackgroundAlpha = 0.1;
    }
    
    [loop_button addTarget:self action:@selector(loop:) forControlEvents:UIControlEventTouchUpInside];
    [[[loop_button widthAnchor] constraintEqualToConstant:44.0] setActive:YES];
    [[[loop_button heightAnchor] constraintEqualToConstant:30.0] setActive:YES];

    UIBarButtonItem* loop_item = [[UIBarButtonItem alloc] initWithCustomView:loop_button];
    loop_item.tag = kLoopButtonTag;

    [items replaceObjectAtIndex:index withObject:loop_item];
    
    if ([Config floatingToolbars]) {
        [self.playbackToolbar setItems:items];
    } else {
        [self.bottomPlaybackToolbar setItems:items];
    }
}

- (void) updatePaletteButton
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[self.toolsToolbar items] mutableCopy];
    } else {
        items = [[self.topToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kPaletteButtonTag inButtons:items];


    self.paletteButton = [[UIButton alloc] initWithFrame:CGRectMake (0, 0, 44, 44)];
    
    UIColor *color = _colorsController.selectedColor.uiColor;
    
    UIView* palette_circle = [[UIView alloc] initWithFrame:CGRectMake (10, 10, 24, 24)];
    palette_circle.backgroundColor = color;
    palette_circle.userInteractionEnabled = NO;
    palette_circle.layer.cornerRadius = 12.0;
    if (@available(iOS 13.0, *)) {
        palette_circle.layer.borderColor = [UIColor labelColor].CGColor;
    } else {
        palette_circle.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    palette_circle.layer.borderWidth = 1.0;
    
    [self.paletteButton addSubview:palette_circle];
    [self.paletteButton addTarget:self action:@selector(showColors:) forControlEvents:UIControlEventTouchDown];
//    UIBarButtonItem cir[[UIBarButtonItem alloc] initWithCustomView:palette_circle];
    self.paletteItem = [[UIBarButtonItem alloc] initWithCustomView:self.paletteButton];
    self.paletteItem.tag = kPaletteButtonTag;
    
    [items replaceObjectAtIndex:index withObject:self.paletteItem];
    
    if ([Config floatingToolbars]) {
        [self.toolsToolbar setItems:items];
    } else {
        [self.topToolbar setItems:items];
    }
    
    if (color) {
        _brushCircleView.color = color;
    }
}

- (void)switchToDrawingState
{
    self.state = FBSceneStateEditing;
    [self updatePlayPauseButton];
}

- (void) updatePlayPauseButton
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[_playbackToolbar items] mutableCopy];
    } else {
        items = [[_bottomPlaybackToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kPlayPauseButtonTag inButtons:items];
    NSUInteger unwind_index = [self indexForButtonWithTag:kUnwindButtonTag inButtons:items];
    NSUInteger fastforward_index = [self indexForButtonWithTag:kFastforwardButtonTag inButtons:items];
    
    UIBarButtonItem* current_play_item = [items objectAtIndex:index];
    UIBarButtonItem* new_play_item;
    
    UIBarButtonItem* current_unwind_item = [items objectAtIndex:unwind_index];
    UIBarButtonItem* current_fastforward_item = [items objectAtIndex:fastforward_index];
    UIBarButtonItem* new_unwind_item;
    UIBarButtonItem* new_fastforward_item;
    
    if (self.state == FBSceneStatePlaying) {
        UIButton* playButton = [[UIButton alloc] init];
        [playButton setFrame: CGRectMake(0, 0, 22, 22)];
        [playButton setImage: [UIImage imageNamed:@"Pause"]
                    forState:UIControlStateNormal];
        [playButton addTarget: self
                       action: @selector(pauseScene:)
             forControlEvents:UIControlEventTouchUpInside];
        new_play_item = [[UIBarButtonItem alloc] initWithCustomView: playButton];

    } else {
        UIButton* playButton = [[UIButton alloc] init];
        [playButton setFrame: CGRectMake(0, 0, 22, 22)];
        [playButton setImage: [UIImage imageNamed:@"Play"]
                    forState:UIControlStateNormal];
        [playButton addTarget: self
                       action: @selector(playScene:)
             forControlEvents:UIControlEventTouchUpInside];
        new_play_item = [[UIBarButtonItem alloc] initWithCustomView: playButton];
    }
    [[new_play_item.customView.widthAnchor constraintEqualToConstant:22] setActive:YES];
    [[new_play_item.customView.heightAnchor constraintEqualToConstant:22] setActive:YES];
    [new_play_item setEnabled:YES];
    new_play_item.tag = current_play_item.tag;
    
    UIImageView* unwindItemImageView = [[UIImageView alloc] init];
    UIImageView* fastForwardItemImageView = [[UIImageView alloc] init];
    
    unwindItemImageView.translatesAutoresizingMaskIntoConstraints = NO;
    fastForwardItemImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [unwindItemImageView setContentMode: UIViewContentModeScaleAspectFill];
    [fastForwardItemImageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [[unwindItemImageView.widthAnchor constraintEqualToConstant:22.0] setActive:YES];
    [[unwindItemImageView.heightAnchor constraintEqualToConstant:18.0] setActive:YES];
    
    [[fastForwardItemImageView.widthAnchor constraintEqualToConstant:22.0] setActive:YES];
    [[fastForwardItemImageView.heightAnchor constraintEqualToConstant:18.0] setActive:YES];
    
    SEL unwind_long_press_selector;
    SEL fastForward_long_press_selector;
    
    if (self.state == FBSceneStatePlaying) {
        [unwindItemImageView setImage:[UIImage imageNamed:@"unwind"]];
        [fastForwardItemImageView setImage:[UIImage imageNamed:@"fast_forward"]];
        
        unwind_long_press_selector = @selector(unwindLongPress);
        fastForward_long_press_selector = @selector(fastForwardLongPress);
    } else {
        [unwindItemImageView setImage:[UIImage imageNamed:@"Back"]];
        [fastForwardItemImageView setImage:[UIImage imageNamed:@"Forward"]];
        
        unwind_long_press_selector = @selector(minus_1_LongPressed:);
        fastForward_long_press_selector = @selector(plus_1_LongPressed:);
    }
    
    // Unwind
    UILongPressGestureRecognizer* unwindLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:unwind_long_press_selector];
    [unwindItemImageView addGestureRecognizer:unwindLongPressGestureRecognizer];
    UITapGestureRecognizer* unwindTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rewindScene:)];
    [unwindItemImageView addGestureRecognizer:unwindTapGestureRecognizer];
    new_unwind_item = [[UIBarButtonItem alloc] initWithCustomView:unwindItemImageView];
    
    // FastForward
    UILongPressGestureRecognizer* fastForwardLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:fastForward_long_press_selector];
    [fastForwardItemImageView addGestureRecognizer:fastForwardLongPressGestureRecognizer];
    UITapGestureRecognizer* fastForwardTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fastForwardScene:)];
    [fastForwardItemImageView addGestureRecognizer:fastForwardTapGestureRecognizer];
    new_fastforward_item = [[UIBarButtonItem alloc] initWithCustomView:fastForwardItemImageView];
    
    new_unwind_item.tag = current_unwind_item.tag;
    new_fastforward_item.tag = current_fastforward_item.tag;
    [items replaceObjectAtIndex:index withObject:new_play_item];
    [items replaceObjectAtIndex:unwind_index withObject:new_unwind_item];
    [items replaceObjectAtIndex:fastforward_index withObject:new_fastforward_item];
    
    
    if ([Config floatingToolbars]) {
        [self.playbackToolbar setItems:items];
    } else {
        [self.bottomPlaybackToolbar setItems:items];
    }
    
    // Bottom toolbar position
    
    if (self.state == FBSceneStateEditing) {
        if (self.isFullscreen) {
            _bottomToolbarConstraint.constant = -44.0;
        } else {
            _bottomToolbarConstraint.constant = 0.0;
        }
//        [_playbackSliderView setHidden:YES];
    } else {
        _bottomToolbarConstraint.constant = 0.0;
        [_playbackSliderView setHidden:NO];
    }
}

- (void)unwindLongPress
{
    if (self.state == FBSceneStatePlaying) {
        [self.drawingView stopSequenceAtStart];
    }
    
    self.state = FBSceneStatePaused;
    [self updatePlayPauseButton];
}

- (void)fastForwardLongPress
{
    if (self.state == FBSceneStatePlaying) {
        [self.drawingView stopSequenceAtEnd];
    }
    self.state = FBSceneStatePaused;
    [self updatePlayPauseButton];
}

- (void)minus_1_LongPressed:(UILongPressGestureRecognizer*)sender
{
    if ([sender state] != UIGestureRecognizerStateBegan) {
        return;
    }
    [self didMoveToRelativePosition:0.0];
    [self.xsheetController didPauseOnRow:0];
}

- (void)plus_1_LongPressed:(UILongPressGestureRecognizer*)sender
{
    if ([sender state] != UIGestureRecognizerStateBegan) {
        return;
    }
    NSInteger lastRow = [self.document.storage numberOfRows] - 1;
    [self didMoveToRelativePosition:1.0];
    [self.xsheetController didPauseOnRow:lastRow];
}

- (void) setPlayPauseButton
{
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[_playbackToolbar items] mutableCopy];
    } else {
        items = [[_bottomPlaybackToolbar items] mutableCopy];
    }
    
    NSUInteger index = [self indexForButtonWithTag:kPlayPauseButtonTag inButtons:items];
    UIBarButtonItem* current_item = [items objectAtIndex:index];
    UIBarButtonItem* new_item;
    UIButton* playButton = [[UIButton alloc] init];
    [playButton setFrame: CGRectMake(0, 0, 22, 22)];
    [playButton setImage: [UIImage imageNamed:@"Play"]
                forState:UIControlStateNormal];
    [playButton addTarget: self
                   action: @selector(playScene:)
         forControlEvents:UIControlEventTouchUpInside];
    new_item = [[UIBarButtonItem alloc] initWithCustomView: playButton];
    [[new_item.customView.widthAnchor constraintEqualToConstant:22] setActive:YES];
    [[new_item.customView.heightAnchor constraintEqualToConstant:22] setActive:YES];
    new_item.tag = current_item.tag;
    [items replaceObjectAtIndex:index withObject:new_item];
    
    if ([Config floatingToolbars]) {
        [self.playbackToolbar setItems:items];
    } else {
        [self.bottomPlaybackToolbar setItems:items];
    }
}

- (NSUndoManager *)undoManager
{
    return [self.drawingView undoManager];
}

- (void) updateUndoButtons
{
#if TARGET_OS_MACCATALYST
    if (![Config floatingToolbars]) {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
        return;
    }
#endif
    
//    [self.topToolbar rf_disableButtonsWithTags:disabled_tags];
    
    NSMutableArray* items;
    
    if ([Config floatingToolbars]) {
        items = [[self.toolsToolbar items] mutableCopy];
    } else {
        items = [[self.topToolbar items] mutableCopy];
    }
    
    BOOL canUndo = [[self.drawingView undoManager] canUndo];
    BOOL canRedo = [[self.drawingView undoManager] canRedo];
    
    for (UIBarButtonItem* button in items) {
        [button setEnabled:YES];
        if (button.tag == kUndoButtonTag && !canUndo) {
            [button setEnabled:NO];
        }
        if (button.tag == kRedoButtonTag && !canRedo) {
            [button setEnabled:NO];
        }
    }
    
}

#pragma mark -

- (void) showLightboxOptions
{
    self.lightboxController = [[FBLightboxController alloc] init];
    [self presentViewController:self.lightboxController animated:YES completion:NULL];
    
    UIPopoverPresentationController* popover_controller = [self.lightboxController popoverPresentationController];
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        CGRect r = [self.lightboxButton convertRect:[self.lightboxButton bounds] toView:self.view];
        popover_controller.sourceRect = r;
        popover_controller.sourceView = self.view;
        popover_controller.delegate = self;
        popover_controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
    } else {
        popover_controller.sourceView = _lightBoxOptionsCatalystView;
    }
#else
    CGRect r = [self.lightboxButton convertRect:[self.lightboxButton bounds] toView:self.view];
    popover_controller.sourceRect = r;
    popover_controller.sourceView = self.view;
    popover_controller.delegate = self;
    popover_controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
#endif
    
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (IBAction) toggleLightbox:(id)inSender
{
    if (![FBPrefs boolFor:kLightboxOptionsUsed]) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:kLightboxOptionsUsed];
        [self showLightboxOptions];
        return;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:![defaults boolForKey:kLightboxEnabledPrefKey] forKey:kLightboxEnabledPrefKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadCurrentCellNotification object:self];
    
#if TARGET_OS_MACCATALYST
    if ([Config floatingToolbars]) {
        [self updateLightboxButton];
    } else {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
    }
#else
    [self updateLightboxButton];
#endif
    
    [FBHelpController showHelpPane:kHelpPaneLightbox];
}

- (IBAction)help:(UIBarButtonItem *)sender
{
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://digicel.net/flippad/"]];
}

- (void)toggleEraserTool
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL old_value = [defaults boolForKey:kUsingEraserToolPrefKey];
    [defaults setBool:!old_value forKey:kUsingEraserToolPrefKey];
}

- (IBAction) renameScene:(id)inSender
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return;
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Rename Scene" message:@"Enter a new name for this scene:" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"New scene name";
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString* s = [[alert textFields][0] text];
        if ([s length] > 0) {
            NSError* error = nil;
            if ([self.document rename:s error:&error]) {
                [self.titleButton setTitle:s];
            }
            else {
                [@"Could not rename file" rf_showInAlertWithError:error];
            }
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];

    
}

- (IBAction) rewindScene:(id)inSender
{
    switch (self.state) {
        case FBSceneStatePlaying:
            [_drawingView speedDown];
            break;
            
        case FBSceneStateEditing:
            [self.drawingView saveChanges];
            [fXsheetController selectPreviousRow];
            break;
            
        case FBSceneStatePaused:
            [fXsheetController pausePreviousRow];
            break;
    }
}

- (IBAction) fastForwardScene:(id)inSender
{
    switch (self.state) {
        case FBSceneStatePlaying:
            [_drawingView speedUp];
            break;
            
        case FBSceneStateEditing:
            [self.drawingView saveChanges];
            [fXsheetController selectNextRow];
            break;
            
        case FBSceneStatePaused:
            [fXsheetController pauseNextRow];
            break;
    }
}

- (IBAction) showSceneInfo:(id)inSender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    FBInfoController* info_controller = [[FBInfoController alloc] initForSpeed];
    info_controller.sceneController = self;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        info_controller.preferredContentSize = info_controller.view.frame.size;
        UIPopoverPresentationController* popover_controller = [info_controller popoverPresentationController];
        popover_controller.barButtonItem = inSender;
        [popover_controller setDelegate: self];
        [popover_controller setBarButtonItem:inSender];
    }
    
    [self presentViewController:info_controller animated:YES completion:NULL];
}

- (IBAction) hideHelp:(id)inSender
{
    [UIView animateWithDuration:0.3 animations:^{
        self.helpView.alpha = 0.0;
        self.helpScrollView.alpha = 0.0;
        self.helpScrollViewBackground.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.helpView.hidden = YES;
        self.helpScrollView.hidden = YES;
        self.helpScrollViewBackground.hidden = YES;
    }];
}

//- (UIImage *)compositedImageAtRow:(NSInteger)row fromLevel:(NSInteger)fromLevel toLevel:(NSInteger)toLevel
//{
//    FBXsheetStorage* storage = [self.document storage];
//    id<FBSceneDatabase> database = [self.document database];
//    
//    FBImage* first_img = [storage firstValidCell].pencilImage;
//    if (first_img == nil) {
//        first_img = [storage firstValidCell].paintImage;
//    }
//    CGSize img_size;
//    if (first_img == nil) {
//        img_size = self.document.cachedSceneDimensions;
//    } else {
//        img_size = first_img.size;
//    }
//    
//    UIGraphicsBeginImageContext(img_size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
//    CGContextFillRect(context, CGRectMake (0, 0, img_size.width, img_size.height));
//    
//    CGContextSaveGState(context);
//    CGContextTranslateCTM(context, 0, img_size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//    
//    for (NSInteger col = fromLevel; col <= toLevel; col++) {
//        NSInteger level_index = col - 1;
//        if ([database isLevelHiddenAtIndex:level_index]) {
//            continue;
//        }
//        
//        FBCell* cel = [storage cellAtRow:row column:col];
//        if (!cel || [cel isEmpty]) {
//            cel = [storage previousCellAtRow:row column:col];
//        }
//        
//        if (cel) {
//            if (cel.backgroundImage) {
//                CGContextDrawImage(context, CGRectMake(0, 0, img_size.width, img_size.height), cel.backgroundImage.cgImage);
//            }
//            if (cel.paintImage) {
//                CGContextDrawImage(context, CGRectMake(0, 0, img_size.width, img_size.height), cel.paintImage.cgImage);
//            }
//            if (cel.pencilImage) {
//                CGContextDrawImage(context, CGRectMake(0, 0, img_size.width, img_size.height), cel.pencilImage.cgImage);
//            }
//        }
//    }
//    
//    CGContextRestoreGState(context);
//    UIImage* new_img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return new_img;
//}

- (UIImage *)compositedImageAtRow:(NSInteger)row
{
    FBXsheetStorage* storage = [self.document storage];
    return [storage compositeAtRow:row];
//    return [self compositedImageAtRow:row fromLevel:1 toLevel:[storage numberOfColumns]];
}

- (void) playScene:(id)inSender
{
    [self.drawingView saveChanges];

    [_transformingSceneView resetTransform:YES];

    NSData* soundData = [[self document] soundData];
    
    switch (self.state) {
        case FBSceneStateEditing: {
            NSInteger row = [self.xsheetController selectedItem].row;
            [self.drawingView playSequenceFromDocumentStorage:fDocument.storage soundData:soundData fromIndex:row-1];
            }
            break;
            
        case FBSceneStatePaused: {
            NSInteger row = (_playbackPositionSlider.value * ([self.document.storage numberOfRows] - 1)) + 1;
            NSInteger nextRow = row + 1;
            if (nextRow > [self.document.storage numberOfRows]) {
                nextRow = 1;
            }
            [self.drawingView playSequenceFromDocumentStorage:fDocument.storage soundData:soundData fromIndex:nextRow-1];
            }
            break;
            
        default:
            break;
    }
    
    self.state = FBSceneStatePlaying;
    
    // Hide toolbars
    [self.navigationToolbar hide];
    [self.toolsToolbar hide];
    
    [self updatePlayPauseButton];
    [self refreshPuck];
}

- (void) pauseScene:(id)inSender
{
    if (self.state == FBSceneStatePlaying) {
        [self.drawingView pauseSequenceWithFrameUpdate:YES];
    }
    self.state = FBSceneStatePaused;

    [self updatePlayPauseButton];
}

- (void)showToolbars
{
    [self.navigationToolbar show];
    [self.toolsToolbar show];
}

- (void)scenePlaybackPositionChangeStarted
{
    _FPS = (CGFloat)[self.document fps];
    //
    _soundOffset = [self.document soundOffset];
    //
    _numberOfRows = [self.document.storage numberOfRows];
    //
    _lastSliderPosition = _playbackPositionSlider.value * (_numberOfRows - 1);
    
    [self.drawingView saveChanges];
}

- (void)scenePlaybackPositionChanged:(UISlider *)sender {
    CGFloat position = _playbackPositionSlider.value * (_numberOfRows - 1);
    NSInteger index = (NSInteger)position;
    NSLog(@"Scrolled %li", (long)index);
    
    if (self.state == FBSceneStatePlaying) {
        [self.drawingView pauseSequenceWithFrameUpdate:YES];
    }

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    
    /// Time since last refresh
    CGFloat dFrames = position - _lastSliderPosition;
    NSTimeInterval dTimeSliderChange = now - _lastSliderPositionUpdateTimestamp;
    
    NSLog(@"!! ---");
    NSLog(@"!! %f / %f", dFrames, dTimeSliderChange);
    
    // If NOT enough time passed - return
    if (dTimeSliderChange < 0.05) {
        return;
    }
    
    _lastSliderPosition = position;
    _lastSliderPositionUpdateTimestamp = now;
    
    // Update playback
    // If not playing yet - check if need to play
    CGFloat singleFrameTime = 1.0 / _FPS;
    CGFloat soundOffset = _soundOffset * singleFrameTime;
    CGFloat targetTime = position * singleFrameTime;
            
    // Update position
    CGFloat audioTime = targetTime - soundOffset;
            
    CGFloat actualFPS = dFrames / dTimeSliderChange;
    
    NSLog(@"!! actualFPS: %f", actualFPS);
    NSLog(@"!! FPS: %f", _FPS);
    NSLog(@"!! Result: %f", actualFPS / _FPS);
    
    CGFloat newRate = actualFPS / _FPS;
            
        // TODO!!!
        // Set values to player
    if (_soundScrubPlayer) {
        if (fabs(newRate) >= 1.0) {
            [_soundScrubPlayer scrubUpdatedWithVelocity:newRate audioTime:audioTime];
        } else {
            CGFloat roundedTime = position * singleFrameTime;
            [_soundScrubPlayer scrubSlowlyUpdatedWithVelocity:newRate frameIndex:index frameStartAudioTime:roundedTime frameDuration:singleFrameTime];
        }
    }
    //
    
//    if (fXsheetController.selectedItem.row == (index + 1)) {
//        // Already selected
//        NSLog(@"Already selected");
//    } else {
        // Show cell
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showCompositedIndex:index];
        });
//    }
}

- (void)scenePlaybackPositionChangeEnded
{
    // Finish sound playback
    if (_soundScrubPlayer) {
        [_soundScrubPlayer stopPlayback];
    }
    //
    NSInteger index = _playbackPositionSlider.value * ([self.document.storage numberOfRows] - 1);
    [fXsheetController didPauseOnRow:index];
}

- (IBAction) loop:(id)inSender
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL is_looping = [defaults boolForKey:kLoopEnabledPrefKey];
    if (is_looping) {
        [defaults setBool:NO forKey:kLoopEnabledPrefKey];
    } else {
        [defaults setBool:YES forKey:kLoopEnabledPrefKey];
    }
    [self updateLoopButton];
}

#pragma mark -

- (void) processNextExportedFromImages:(NSMutableArray *)images
{
    FBExportedImage* info = [images firstObject];
    [images removeObject:info];
    
    [SDPhotosHelper requestPermissionsWithCompletion:^(BOOL success) {
        if (success) {
            [SDPhotosHelper createAlbumWithTitle:kPhotosAlbumName onResult:^(BOOL result, NSError * _Nullable error) {
                [SDPhotosHelper addNewImage:info.image toAlbum:kPhotosAlbumName onSuccess:^(NSString * _Nonnull localId) {
                    if ([images count] == 0) {
                        NSString* msg = @"You can access them in the \"FlipPad\" album in the Photos app on your iPad.";
                        [@"Finished saving images" rf_showInAlertWithMessage:msg];
                    } else {
                        fb_dispatch_main_async (^{
                            [self processNextExportedFromImages:images];
                        });
                    }
                } onFailure:^(NSError * _Nullable error) {
                    [@"Error saving photo asset" rf_showInAlertWithError:error];
                }];
            }];
        } else {
            [@"No Permissions" rf_showInAlertWithMessage:@"Give permissions to be able to save media"];
        }
    }];
}

- (void) exportFileToPhotos:(NSString *)inPath
{
    [SDPhotosHelper requestPermissionsWithCompletion:^(BOOL success) {
        if (success) {
            [SDPhotosHelper createAlbumWithTitle:kPhotosAlbumName onResult:^(BOOL result, NSError * _Nullable error) {
                NSURL* export_url = [NSURL fileURLWithPath:inPath];
                [SDPhotosHelper addNewVideoWithFileUrl:export_url inAlbum:kPhotosAlbumName onSuccess:^(NSString * _Nonnull localId) {
                    [@"Finished saving movie" rf_showInAlertWithMessage:@"You can access it in the \"FlipPad\" album in the Photos app on your iPad."];
                } onFailure:^(NSError * _Nullable error) {
                    NSLog (@"Error getting asset: %@", error);
                }];
            }];
        } else {
            [@"No Permissions" rf_showInAlertWithMessage:@"Give permissions to be able to save media"];
        }
    }];
}

- (IBAction) undo:(id)inSender
{
    if ([[self.drawingView undoManager] canUndo])
    {
        [[self.drawingView undoManager] undo];
        [FBHelpController showHelpPane:kHelpPaneUndo];
    }
}

- (IBAction) redo:(id)inSender
{
    if ([[self.drawingView undoManager] canRedo])
    {
        [[self.drawingView undoManager] redo];
    }
}

- (IBAction) changeZoom:(id)inSender
{
    [self hideAllPopovers];
    zoomSheet = [UIAlertController alertControllerWithTitle:@"Choose the option" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* zoom75 = [UIAlertAction
                                actionWithTitle:@"75%"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        [self zoom75];
                                }];
    UIAlertAction* zoom1 = [UIAlertAction
                                actionWithTitle:@"100%"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        [self zoom100];
                                }];
    UIAlertAction* zoom2 = [UIAlertAction
                                actionWithTitle:@"200%"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        [self zoom200];
                                }];
    UIAlertAction* zoomFullScreen = [UIAlertAction
                                     actionWithTitle:@"Zoom To Full Screen"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
        [self zoomToFill];
                                }];
    UIAlertAction* zoomToFit = [UIAlertAction
                                    actionWithTitle:@"Zoom To Fit"
                                    style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        [self zoomToFit];
                                }];
    UIAlertAction* cancel = [UIAlertAction
                                actionWithTitle:@"Cancel"
                                style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction * action) {
                                }];
    [zoomSheet addAction: zoom75];
    [zoomSheet addAction: zoom1];
    [zoomSheet addAction: zoom2];
    [zoomSheet addAction: zoomFullScreen];
    [zoomSheet addAction: zoomToFit];
    [zoomSheet addAction: cancel];
    [zoomSheet setModalPresentationStyle: UIModalPresentationPopover];
    zoomSheet.popoverPresentationController.barButtonItem = inSender;
    [self presentViewController:zoomSheet animated:YES completion:nil];
}

- (void)zoom75 {
    [_transformingSceneView zoomToScale:0.75f animated:YES];
}

- (void)zoom100 {
    [_transformingSceneView zoomToScale:1.00f animated:YES];
}

- (void)zoom200 {
    [_transformingSceneView zoomToScale:2.00f animated:YES];
}

- (void)zoomToFill {
    [_transformingSceneView zoomToFill:YES];
}

- (void)zoomToFit {
    [_transformingSceneView zoomToFit:YES];
}

- (void)importAudio {
    [fXsheetController importAudio];
}

- (void)importImage {
    [fXsheetController importImage];
}

- (void)importVideo {
    [fXsheetController importVideo];
}

- (void)makeExport {
    [fXsheetController makeExport];
}

#pragma mark -

- (void) refreshScene
{
    for (UIView* v in [self.view subviews]) {
        [v setNeedsDisplay];
    }
}

- (void) hideAllPopovers
{
    if (zoomSheet) {
        [zoomSheet dismissViewControllerAnimated:YES completion:nil];
        zoomSheet = nil;
    }
    
    if ([[self xsheetController] alertContoller]) {
        [[[self xsheetController] alertContoller] dismissViewControllerAnimated:true completion:nil];
        [self xsheetController].alertContoller = nil;
    }

    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

//- (void) hideXsheetNotification:(NSNotification *)inNotification
//{
//    [self hideXsheet];
//}

- (void) hideAllPopoversNotification:(NSNotification *)inNotification
{
    [self hideAllPopovers];
}

- (void) prefsDidChangeNotification:(NSNotification *)inNotification
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
    #if TARGET_OS_MACCATALYST
        if (![Config floatingToolbars]) {
            [weakSelf setToolbar:[ToolBarService drawingToolBar:weakSelf] isTitleVisible:NO];
            return;
        }
    #endif
        // Xsheet
//        UIView* xSheetView = [self->fXsheetController view];
//        BOOL wasXSheetLeading = [self->_edgeXSheetAnchor firstAnchor] == [xSheetView leadingAnchor];
//        BOOL isXSheetLeading = [SettingsBundleHelper xsheetLocation] == XSheetLocationLeading;
//        if (wasXSheetLeading != isXSheetLeading) {
//            [self updateSlideView];
//            [self configureXsheetConstraints];
//            if ([Config floatingToolbars]) {
//                [self configureFloatingToolbars];
//                //
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.view setNeedsLayout];
//                    [self.view layoutSubviews];
//                });
//            }
//        }
        //
        [weakSelf updateLightboxButton];
        [weakSelf updatePaletteButton];
        [weakSelf refreshToolbar];
//        if (self.isFullscreen) {
//            if (SettingsBundleHelper.xsheetAlwaysVisible) {
//                [self showXsheet];
//            } else {
//                [self hideXsheet];
//            }
//        }
        [weakSelf updateToolbarOrientation];
        [weakSelf updateToolButtons];
        [weakSelf updateSideSlideXSheetView];
        
        CGFloat sizeRatio;
        CGFloat alphaRatio;
        BOOL isEraser = [FBPrefs boolFor:kUsingEraserToolPrefKey];
        if (isEraser) {
            sizeRatio = ([[NSUserDefaults standardUserDefaults] floatForKey:kCurrentEraserWidthPrefKey] - kMinBrushSize) / (kMaxBrushSize - kMinBrushSize);
            alphaRatio = 1.0;
        } else {
            sizeRatio = (FBBrush.currentBrush.strokeWidth - kMinBrushSize) / (kMaxBrushSize - kMinBrushSize);
            alphaRatio = [[NSUserDefaults standardUserDefaults] floatForKey:kCurrentAlphaPrefKey];
        }
        weakSelf.brushCircleView.sizeRatio = sizeRatio;
        weakSelf.brushCircleView.alphaRatio = alphaRatio;
    });
}

- (void) shortcutButtonEraserNotification:(NSNotification *)inNotification
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:![defaults boolForKey:kUsingEraserToolPrefKey] forKey:kUsingEraserToolPrefKey];
    [defaults setBool:NO forKey:kUsingFillToolPrefKey];
    [self refreshToolbar];
}

- (void) shortcutButtonUndoNotification:(NSNotification *)inNotification
{
    [self undo:nil];
}

- (void) shortcutButtonRedoNotification:(NSNotification *)inNotification
{
    [self redo:nil];
}

- (void)configureBrushPuck {
    BOOL isRTL = [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
    CGRect frame;
    CGSize size = CGSizeMake(80.0f, 80.0f);
    if (SettingsBundleHelper.brushCircleViewPoint.x == -1.0f) {
        CGPoint ratio = CGPointMake(isRTL ? 0.1 : 0.9, 0.5);
        CGSize mainSize = UIScreen.mainScreen.bounds.size;
        CGPoint point = CGPointMake(ratio.x * mainSize.width, ratio.y * mainSize.height);
        frame = CGRectMake(point.x - 0.5 * size.width, point.y - 0.5 * size.height, size.width, size.height);
    } else {
        CGPoint point = SettingsBundleHelper.brushCircleViewPoint;
        frame = CGRectMake(point.x - 0.5 * size.width, point.y - 0.5 * size.height, size.width, size.height);
    }
    _brushCircleView = [[FBBrushCircleView alloc] initWithFrame:frame];
    _brushCircleView.delegate = self;
    UIColor *color = _colorsController.selectedColor.uiColor;
    if (color) {
        _brushCircleView.color = color;
    }
    [_brushCircleView addTarget:self
                         action:@selector(brushCircleViewValueChangedHandler:)
               forControlEvents:UIControlEventValueChanged];
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        [_transformingSceneView addSubview:_brushCircleView];
    }
}

#pragma mark - FBBrushCircleDelegate

- (void)brushCircleViewDidChangePosition:(FBBrushCircleView *)brushCircleView {
    SettingsBundleHelper.brushCircleViewPoint = _brushCircleView.layer.position;
}

- (void)brushCircleViewValueChangedHandler:(FBBrushCircleView *)sender {
    NSLog(@"Selector size: %f and alpha: %f;", sender.sizeRatio, sender.alphaRatio);
    BOOL isEraser = [FBPrefs boolFor:kUsingEraserToolPrefKey];
    if (isEraser) {
        CGFloat value = kMinBrushSize + sender.sizeRatio * (kMaxBrushSize - kMinBrushSize);
        [[NSUserDefaults standardUserDefaults] setFloat:value forKey:kCurrentEraserWidthPrefKey];
    } else {
        FBBrush.currentBrush.strokeWidth = kMinBrushSize + sender.sizeRatio * (kMaxBrushSize - kMinBrushSize);
        [[NSUserDefaults standardUserDefaults] setFloat:sender.alphaRatio forKey:kCurrentAlphaPrefKey];
    }
}

- (void)configureToolControllers
{
    // Pencil
    
    self.pencilOptionsController = [[FBPencilController alloc] init];
    
    // Eraser
    
    self.eraserOptionsController = [[FBEraserController alloc] init];
    self.eraserOptionsController.modalPresentationStyle = UIModalPresentationPopover;
    
    // Fill
    
    self.fillOptionsController = [[FBFillController alloc] init];
    [_fillOptionsController setDelegate:self];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.fillOptionsController.modalPresentationStyle = UIModalPresentationFullScreen;
    } else {
        self.fillOptionsController.modalPresentationStyle = UIModalPresentationPopover;
    }
    
}

#pragma mark - FBLassoViewDelegate

- (void)willStartSelecting
{
    NSLog(@"willStartSelecting");
    
    if (_pasteView) {
        if ([_pasteView isMoved]) {
            [_pasteView paste];
        } else {
            [self undo:nil];
            [_pasteView removeFromSuperview];
        }
        [self setPasteView:nil];
    }
}

- (void)cutRequestedWithPath:(UIBezierPath *)path fromPoint:(CGPoint)fromPoint
{
    
    SettingsBundleHelper.editModeDevice = YES;
    
    // Position
    NSInteger row = [self.xsheetController selectedItem].row;
    NSInteger column = [self.xsheetController selectedItem].item;
    
    // Save
    [self.drawingView saveChanges];
    // Reload cell
    FBCell* cell = [self.document.storage cellAtRow:row column:column];
    
    UIImage* previous_img = [self.xsheetController buildLightboxImageAtPreviousRow:row column:column];
    
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info rf_setObject:cell.pencilImage forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:cell.paintImage forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:cell.structureImage forKey:kUpdateCurrentCellStructureKey];
    [info rf_setObject:previous_img forKey:kUpdateCurrentLightboxImageKey];
    [info rf_setObject:@NO forKey:kUpdateIsCurrentlyPausedKey];
    
    [self.drawingView loadNewCelWithImages:info];
    [self.drawingView saveCurrentStateBeforeCutAndPaste];
    
    // Source images
    FBImage* pencilImage = [cell pencilImage];
    FBImage* fillImage = [cell paintImage];
    FBImage* structureImage = [cell structureImage];
    // Cutted image
    NSMutableArray* imagesToCompose = [NSMutableArray new];
    if (fillImage) {
        [imagesToCompose addObject:fillImage.previewUiImage];
    }
    if (pencilImage) {
        [imagesToCompose addObject:pencilImage.previewUiImage];
    }
    UIImage* compositedImage = [UIImage rf_imageByCompositingImages:imagesToCompose backgroundColor:[UIColor clearColor]];
    
    UIImage* cutImage = [compositedImage imageByApplyingClippingBezierPath:path];
    FBImage* cutPencilImage = [[pencilImage copyImage] imageByApplyingClippingBezierPath:path];
    FBImage* cutFillImage = [[fillImage copyImage] imageByApplyingClippingBezierPath:path];
    FBImage* cutStructureImage = [[structureImage copyImage] imageByApplyingClippingBezierPath:path];
    // Save
    
    info = [NSMutableDictionary dictionary];
    [info rf_setObject:[pencilImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:[fillImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:[structureImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellStructureKey];
    // Lightbox ?
    [self.drawingView updateCelWithImages:info];
    
    FBPasteView* pasteView = [FBPasteView new];
    [pasteView setDelegate:self];
    [pasteView setImage:cutImage];
    [pasteView setPencilImage:cutPencilImage];
    [pasteView setFillImage:cutFillImage];
    [pasteView setStructureImage:cutStructureImage];
    [pasteView setPath:path];
    [pasteView setFrame:CGRectMake(fromPoint.x - (cutImage.size.width / 2),
                                   fromPoint.y - (cutImage.size.height / 2),
                                   cutImage.size.width, cutImage.size.height)];
    [pasteView configure];
    [self setPasteView:pasteView];
    [self.contentView addSubview:pasteView];
}

- (void)copyRequestedWithPath:(UIBezierPath *)path fromPoint:(CGPoint)fromPoint
{
    
    SettingsBundleHelper.editModeDevice = YES;

    // Position
    NSInteger row = [self.xsheetController selectedItem].row;
    NSInteger column = [self.xsheetController selectedItem].item;
    
    // Save
    [self.drawingView saveChanges];
    // Reload cell
    FBCell* cell = [self.document.storage cellAtRow:row column:column];
    
    UIImage* previous_img = [self.xsheetController buildLightboxImageAtPreviousRow:row column:column];
    
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info rf_setObject:cell.pencilImage forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:cell.paintImage forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:cell.structureImage forKey:kUpdateCurrentCellStructureKey];
    [info rf_setObject:previous_img forKey:kUpdateCurrentLightboxImageKey];
    [info rf_setObject:@NO forKey:kUpdateIsCurrentlyPausedKey];
    
    [self.drawingView loadNewCelWithImages:info];
    [self.drawingView saveCurrentStateBeforeCutAndPaste];
    
    // Source images
    FBImage* pencilImage = [cell pencilImage];
    FBImage* fillImage = [cell paintImage];
    FBImage* structureImage = [cell structureImage];
    // Cutted image
    NSMutableArray* imagesToCompose = [NSMutableArray new];
    if (fillImage) {
        [imagesToCompose addObject:fillImage.previewUiImage];
    }
    if (pencilImage) {
        [imagesToCompose addObject:pencilImage.previewUiImage];
    }
    UIImage* compositedImage = [UIImage rf_imageByCompositingImages:imagesToCompose backgroundColor:[UIColor clearColor]];
    
    UIImage* cutImage = [compositedImage imageByApplyingClippingBezierPath:path];
    FBImage* cutPencilImage = [[pencilImage copyImage] imageByApplyingClippingBezierPath:path];
    FBImage* cutFillImage = [[fillImage copyImage] imageByApplyingClippingBezierPath:path];
    FBImage* cutStructureImage = [[structureImage copyImage] imageByApplyingClippingBezierPath:path];
    // Save
    
//    info = [NSMutableDictionary dictionary];
//    [info rf_setObject:[pencilImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellPencilKey];
//    [info rf_setObject:[fillImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellPaintKey];
//    [info rf_setObject:[structureImage imageByApplyingCuttingBezierPath:path] forKey:kUpdateCurrentCellStructureKey];
//    // Lightbox ?
//    [self.drawingView updateCelWithImages:info];
    
    FBPasteView* pasteView = [FBPasteView new];
    [pasteView setDelegate:self];
    [pasteView setImage:cutImage];
    [pasteView setPencilImage:cutPencilImage];
    [pasteView setFillImage:cutFillImage];
    [pasteView setStructureImage:cutStructureImage];
    [pasteView setPath:path];
    [pasteView setFrame:CGRectMake(fromPoint.x - (cutImage.size.width / 2),
                                   fromPoint.y - (cutImage.size.height / 2),
                                   cutImage.size.width, cutImage.size.height)];
    [pasteView configure];
    [self setPasteView:pasteView];
    [self.contentView addSubview:pasteView];
}

#pragma mark - FBPasteViewDelegate

- (void)pasteRequestedWithPencilImage:(FBImage *)pencilImage fillImage:(FBImage *)fillImage structureImage:(FBImage *)structureImage transform:(ImageTransform*)transform  shouldFinish:(BOOL)shouldFinish
{
    // Current images
    NSDictionary* images = [self.drawingView getCurrentImages];
    // Source images
    FBImage* old_pencilImage = [images objectForKey:kUpdateCurrentCellPencilKey];
    FBImage* old_fillImage = [images objectForKey:kUpdateCurrentCellPaintKey];
    FBImage* old_structureImage = [images objectForKey:kUpdateCurrentCellStructureKey];
    
    CGSize sceneSize = [fDocument resolutionSize];
    if (!old_pencilImage) {
        old_pencilImage = [[FBImage alloc] initWithPremultipliedImage:[UIImage rf_imageWithSize:sceneSize fillColor:[UIColor clearColor]]];
    }
    if (!old_fillImage) {
        old_fillImage = [[FBImage alloc] initWithPremultipliedImage:[UIImage rf_imageWithSize:sceneSize fillColor:[UIColor clearColor]]];
    }
    if (!old_structureImage) {
        old_structureImage = [[FBImage alloc] initWithPremultipliedImage:[UIImage rf_imageWithSize:sceneSize fillColor:[UIColor clearColor]]];
    }
    
    // Get position and save
    NSInteger row = [self.xsheetController selectedItem].row;
    NSInteger column = [self.xsheetController selectedItem].item;
    FBCell* cell = [self.document.storage cellAtRow:row column:column];
    
    FBImage* pastePencilImage = [[pencilImage copyImage] imageByApplyingWithTransform:transform];
    FBImage* pastePaintImage = [[fillImage copyImage] imageByApplyingWithTransform:transform];
    FBImage* pasteStructureImage = [[structureImage copyImage] imageByApplyingWithTransform:transform];
    
    FBImage* newPencilImage = [old_pencilImage imageByAdding:pastePencilImage];
    FBImage* newPaintImage = [old_fillImage imageByAdding:pastePaintImage];
    FBImage* newStructureImage = [old_structureImage imageByAdding:pasteStructureImage];
    
    [cell setPencilImage:newPencilImage];
    [cell setPaintImage:newPaintImage];
    [cell setStructureImage:newStructureImage];

    [self.document.storage storeCell:cell atRow:row column:column];
    [self.xsheetController selectRow:row item:column];
    
    if (shouldFinish) {
        [self setPasteView:nil];
    }
}

- (void)cancelRequested
{
    if ([self pasteView]) {
        [self.pasteView removeFromSuperview];
        [self setPasteView:nil];
    }
}


#pragma mark - Actions

- (void)refreshPuck
{
    BOOL isPencilEnabled = ![FBPrefs boolFor:kUsingFillToolPrefKey]
                        && ![FBPrefs boolFor:kUsingLassoToolPrefKey]
                        && ([self.xsheetController selectedItem].mode == Item);
    if (isPencilEnabled && !self.isPlaying) {
        BOOL isPuckInstalled = _brushCircleView && _brushCircleView.superview != nil;
        if (!isPuckInstalled) {
            [self configureBrushPuck];
        }
    } else {
        [_brushCircleView removeFromSuperview];
        _brushCircleView = nil;
    }
}

- (void)pencilPressed:(id)sender
{
    if (![FBPrefs boolFor:kPencilOptionsUsed]) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:kPencilOptionsUsed];
        [self pencilLongPressAction:nil];
        return;
    }
    
#if !TARGET_OS_MACCATALYST
    UIGestureRecognizerState state = [(UITapGestureRecognizer*)sender state];
    if (state != UIGestureRecognizerStateEnded) {
        return;
    }
#endif
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kUsingEraserToolPrefKey];
    [defaults setBool:NO forKey:kUsingFillToolPrefKey];
    
    [self forceDisableLasso];
    [self refreshPuck];
    
#if TARGET_OS_MACCATALYST
    if (![Config floatingToolbars]) {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
    }
#else
    [self refreshToolbar];
#endif
}

- (void)pencilLongPressAction:(id)sender
{
    [self pencilPressed:sender];
    
    NSNumber* state = [sender valueForKey:@"state"];
    if (sender != nil && ![state isEqual: @1]) {
        return;
    }
    
    [self showPencilOptions:sender];
    
    [self forceDisableLasso];
}

- (void)eraserPressed:(id)sender
{
#if !TARGET_OS_MACCATALYST
    UIGestureRecognizerState state = [(UITapGestureRecognizer*)sender state];
    if (state != UIGestureRecognizerStateEnded) {
        return;
    }
#endif
    
    [self toggleEraserTool];
    
    [self forceDisableLasso];
    [self refreshPuck];
    
#if TARGET_OS_MACCATALYST
    if (![Config floatingToolbars]) {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
    }
#else
    [self refreshToolbar];
#endif
}

- (void)eraserLongPressAction:(id)sender
{
    NSNumber* state = [sender valueForKey:@"state"];
    if (sender != nil && ![state isEqual: @1]) {
        return;
    }
    
    [self showEraserOptions:nil];
    
    [self forceDisableLasso];
}

- (IBAction)fillPressed:(id)sender
{
#if !TARGET_OS_MACCATALYST
    UIGestureRecognizerState state = [(UITapGestureRecognizer*)sender state];
    if (state != UIGestureRecognizerStateEnded) {
        return;
    }
#endif
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kUsingEraserToolPrefKey];
    [defaults setBool:YES forKey:kUsingFillToolPrefKey];
    
    [self forceDisableLasso];
    [self refreshPuck];
    
#if TARGET_OS_MACCATALYST
    if (![Config floatingToolbars]) {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
    }
#else
    [self refreshToolbar];
#endif
}

- (void)fillLongPressAction:(id)sender
{
    [self fillPressed:sender];
    
    NSNumber* state = [sender valueForKey:@"state"];
    if (sender != nil && ![state isEqual: @1]) {
        return;
    }
    
    [self showFillOptions:nil];
    
    [self forceDisableLasso];
}

- (void)lassoPressed:(id)sender
{
#if !TARGET_OS_MACCATALYST
    UIGestureRecognizerState state = [(UITapGestureRecognizer*)sender state];
    if (state != UIGestureRecognizerStateEnded) {
        return;
    }
#endif
    
    if (![self canEnableLasso]) {
        return;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kUsingLassoToolPrefKey];
    
    [self addLassoView];
    [self refreshPuck];
    
#if TARGET_OS_MACCATALYST
    if (![Config floatingToolbars]) {
        [self setToolbar:[ToolBarService drawingToolBar:self] isTitleVisible:NO];
    }
#else
    [self refreshToolbar];
#endif
}

- (void)forceDisableLasso
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kUsingLassoToolPrefKey];
    [self removeLassoView];
}

- (void)refreshToolbar
{
    UITraitCollection* traitCollection = nil;
    
    if (@available(iOS 12.0, *)) {
        traitCollection = [Config floatingToolbars] ? [self traitCollection] : [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    }
    
    if ([FBPrefs boolFor:kUsingLassoToolPrefKey]) {
        [self.lassoItemImageView setImage:[[UIImage imageNamed:@"toolbar_lasso_on" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        // Off all other
        [self.pencilItemImageView setImage:[[UIImage imageNamed:@"toolbar_pencil_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.fillItemImageView setImage:[[UIImage imageNamed:@"toolbar_fill_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.eraserItemImageView setImage:[[UIImage imageNamed:@"toolbar_erase_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    } else {
        [self.lassoItemImageView setImage:[[UIImage imageNamed:@"toolbar_lasso_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        //
        if ([FBPrefs boolFor:kUsingFillToolPrefKey]) {
            [self.pencilItemImageView setImage:[[UIImage imageNamed:@"toolbar_pencil_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [self.fillItemImageView setImage:[[UIImage imageNamed:@"toolbar_fill_on" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        } else {
            [self.pencilItemImageView setImage:[[UIImage imageNamed:@"toolbar_pencil_on" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            [self.fillItemImageView setImage:[[UIImage imageNamed:@"toolbar_fill_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }
        
        if ([FBPrefs boolFor:kUsingEraserToolPrefKey]) {
            [self.eraserItemImageView setImage:[[UIImage imageNamed:@"toolbar_erase_on" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        } else {
            [self.eraserItemImageView setImage:[[UIImage imageNamed:@"toolbar_erase_off" inBundle:nil compatibleWithTraitCollection:traitCollection] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }
    }
}

- (void)updateToolbarOrientation {
    BOOL isVertical = SettingsBundleHelper.verticalToolbar;
    Orientation orientation = isVertical ? OrientationVertical : OrientationHorizontal;
    self.navigationToolbar.orientation = orientation;
    self.toolsToolbar.orientation = orientation;
}

#pragma mark - Image capture

- (void)startImageCapture
{
    [self.bottomImageCaptureToolbar setHidden:NO];
    
    [self.imageCaptureController setSceneController:self];
    if (@available(iOS 10.0, macCatalyst 14.0, *)) {
        [self.imageCaptureController prepareWithCompletion:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageCaptureController resetFilter];
                [self installCapturePreviewView];
            });
        }];
    } else {
        
    }
}

- (IBAction)resolutionOptions:(id)sender
{
    
}

- (IBAction)colorOptions:(id)sender
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Color Mode" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* colorOption = [UIAlertAction actionWithTitle:@"Color" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.imageCaptureController setFilterWithEnabled:NO];
    }];
    UIAlertAction* grayScaleOption = [UIAlertAction actionWithTitle:@"Gray Scale" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.imageCaptureController setFilterWithEnabled:YES];
    }];
    UIAlertAction* cancelOption = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:colorOption];
    [alertController addAction:grayScaleOption];
    [alertController addAction:cancelOption];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    alertController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alertController animated:true completion:nil];
}

- (IBAction)exposureOptions:(id)sender
{
    CaptureExposureController* exposureController = [CaptureExposureController new];
    [exposureController setDelegate:self];
    
    exposureController.preferredContentSize = exposureController.view.bounds.size;
    exposureController.modalPresentationStyle = UIModalPresentationPopover;
        
    UIPopoverPresentationController* popover_controller = [exposureController popoverPresentationController];
    popover_controller.barButtonItem = sender;
    [popover_controller setDelegate: self];
    
    [self presentViewController:exposureController animated:true completion:nil];
}

- (IBAction)capture:(UIBarButtonItem *)sender
{
    [self.imageCaptureController capturePhotoWithCompletion:^(UIImage* image) {
        // MARK: - Save image to cell and step to next row
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.imageCaptureController isFilterEnabled]) {
                [self.xsheetController pasteWithCapturedPencilImage:image];
            } else {
                [self.xsheetController pasteWithImage:image];
            }
            [self.xsheetController.fTableView reloadData];
        });
    }];
}

- (IBAction)cancelImageCapture:(id)sender
{
    [self.bottomImageCaptureToolbar setHidden:YES];
    
    if (@available(iOS 10.0, macCatalyst 14.0, *)) {
        [self removeCapturePreviewView];
    }
}

#pragma mark - CaptureExposureControllerDelegate

- (void)didChangeWhiteWithValue:(float)value
{
    [self.imageCaptureController resetFilter];
}

- (void)didChangeGammaWithValue:(float)value
{
    [self.imageCaptureController resetFilter];
}

#pragma mark - FBFillControllerDelegate

- (void)didChangeFillModeTo:(enum FBFillMode)mode
{
    self.fillMode = mode;
}

- (void)didApplyAutoFillMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->fXsheetController applyAutoFill];
    });
}

#pragma mark - Mac Toolbar

#if TARGET_OS_MACCATALYST

- (UIImage *)imageFromColor
{
    UIColor* color = [_colorsController selectedColor].uiColor;
    
    CGRect rect = CGRectMake(0, 0, 20, 20);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillEllipseInRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - NSToolBarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
    if ([itemIdentifier  isEqual: kExitItem]) {
        UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"exitScene"] style:UIBarButtonItemStylePlain target:self action:@selector(closeScene:)];
        NSToolbarItem* item = [NSToolbarItem itemWithItemIdentifier:kExitItem barButtonItem:barButton];
        item.label = @"Close";
        return item;
    } else if ([itemIdentifier  isEqual: kHideXsheetItem]) {
        UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sidebar_off"] style:UIBarButtonItemStylePlain target:self action:@selector(showXsheet:)];
        NSToolbarItem* item = [NSToolbarItem itemWithItemIdentifier:kHideXsheetItem barButtonItem:barButton];
        item.label = @"Hide XSheet";
        return item;
    } else if ([itemIdentifier  isEqual: kTitleItem]) {
        UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithTitle:self.document.displayName style:UIBarButtonItemStylePlain target:nil action:nil];
        NSToolbarItem* item = [NSToolbarItem itemWithItemIdentifier:kTitleItem barButtonItem:barButton];
        item.label = @"";
        return item;
    } else if ([itemIdentifier  isEqual: kLightBoxItem]) {
        UIImage* lightBoxImage = [UIImage imageNamed:@"toolbar_lightbox_off"]; // gray
        if ([FBPrefs boolFor:kLightboxEnabledPrefKey]) {
            lightBoxImage = [UIImage imageNamed:@"toolbar_lightbox"]; // white
        }
        SRImageToolbarItem* item = [SRImageToolbarItem itemWithIdentifier:kLightBoxItem Image: lightBoxImage Target:self Action:@selector(showLightboxOptions)];
        item.action = @selector(toggleLightbox:);
        item.target = self;
        item.label = @"Light Box";
        return item;
    } else if ([itemIdentifier  isEqual: kUndoItem]) {
        NSToolbarItem* item = [NSToolbarItem itemWithItemIdentifier:kUndoItem barButtonItem:_undoCatalystButton];
        item.label = @"Undo";
        if (![[self.drawingView undoManager] canUndo]) {
            item.action = nil;
        }
        return item;
    } else if ([itemIdentifier  isEqual: kRedoItem]) {
        NSToolbarItem* item = [NSToolbarItem itemWithItemIdentifier:kRedoItem barButtonItem:_redoCatalystButton];
        if (![[self.drawingView undoManager] canRedo]) {
            item.action = nil;
        }
        item.label = @"Redo";
        return item;
    } else if ([itemIdentifier  isEqual: kPalleteItem]) {
        UIImage* circleImage = [self imageFromColor];
        SRImageToolbarItem* item = [SRImageToolbarItem itemWithIdentifier:kPalleteItem Image: circleImage];
        item.action = @selector(showColors:);
        item.target = self;
        item.label = @"Pallete";
        return item;
    } else if ([itemIdentifier  isEqual: kToolItem]) {
        SRToolsItemConfiguration* config = [SRToolsItemConfiguration new];
        [config setTarget:self];
        
        [config setPencilLongPressAction:[NSValue valueWithPointer:@selector(pencilLongPressAction:)]];
        [config setPencilAction:[NSValue valueWithPointer:@selector(pencilPressed:)]];
        [config setEraserAction:[NSValue valueWithPointer:@selector(eraserPressed:)]];
        [config setEraserLongPressAction:[NSValue valueWithPointer:@selector(eraserLongPressAction:)]];
        [config setFillAction:[NSValue valueWithPointer:@selector(fillPressed:)]];
        [config setFillLongPressAction:[NSValue valueWithPointer:@selector(fillLongPressAction:)]];
        [config setLassoAction:[NSValue valueWithPointer:@selector(lassoPressed:)]];
        
        [config setPencilImage:[[UIImage imageNamed:@"toolbar_pencil_off_catalyst"] imageByTintColor:UIColor.grayColor]];
        [config setEraserImage:[[UIImage imageNamed:@"toolbar_erase_off_catalyst"] imageByTintColor:UIColor.grayColor]];
        [config setFillImage:[[UIImage imageNamed:@"toolbar_fill_off_catalyst"] imageByTintColor:UIColor.grayColor]];
        [config setLassoImage:[[UIImage imageNamed:@"toolbar_lasso_off"] imageByTintColor:UIColor.grayColor]];
        
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        UIColor* accentColor = [UIColor colorWithRed:0.18 green:0.72 blue:1.00 alpha:1.00];
        
        if ([defaults boolForKey:kUsingLassoToolPrefKey]) {
            [config setLassoImage:[config.lassoImage imageByTintColor:accentColor]];
        } else {
            if ([defaults boolForKey:kUsingFillToolPrefKey]) {
                [config setFillImage:[config.fillImage imageByTintColor:accentColor]];
            } else {
                [config setPencilImage:[config.pencilImage imageByTintColor:accentColor]];
            }
            
            if ([defaults boolForKey:kUsingEraserToolPrefKey]) {
                [config setEraserImage:[config.eraserImage imageByTintColor:accentColor]];
            }
        }
        
        NSToolbarItemGroup* group = [SRImageToolbarItem toolItemWithButtonConfiguration:config];
        [group setSelectionMode:NSToolbarItemGroupSelectionModeSelectAny];
        
        return group;
    }
    return nil;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    if ([Config floatingToolbars]) {
        return @[kExitItem, kHideXsheetItem, kLightBoxItem,
                 NSToolbarFlexibleSpaceItemIdentifier,
                 kTitleItem,
                 NSToolbarFlexibleSpaceItemIdentifier
        ];
    } else {
        return @[kExitItem, kHideXsheetItem, kLightBoxItem,
                 NSToolbarFlexibleSpaceItemIdentifier,
                 kTitleItem,
                 NSToolbarFlexibleSpaceItemIdentifier,
                 kPalleteItem,
                 NSToolbarSpaceItemIdentifier,
                 kToolItem,
                 NSToolbarSpaceItemIdentifier,
                 kUndoItem, kRedoItem
        ];
    }
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

#endif

- (void)repositionFloatingViewIfNeededWithBlock:(void (^)(void))block {
    NSArray *views = @[
        _navigationToolbar,
        _toolsToolbar,
        _playbackToolbar
    ];
    CGRect selfFrame = self.view.frame;
    CGRect slideFrame = _sideSlideXSheetView.frame;
    CGRect allowedRect;
    if (_sideSlideXSheetView.side == SideLeft) {
        CGFloat x = slideFrame.size.width + slideFrame.origin.x;
        allowedRect = CGRectMake(x, 0.0f, selfFrame.size.width - x, selfFrame.size.height);
    } else {
        allowedRect = CGRectMake(0.0f, 0.0f, slideFrame.origin.x, selfFrame.size.height);
    }
    [UIView animateWithDuration:0.24f
                     animations:^{
        for (FloatingView *view in views) {
            if (CGRectIntersectsRect(self.sideSlideXSheetView.frame, view.frame)) {
                [view correctPositionFor:allowedRect];
            }
        }
    } completion:^(BOOL finished) {
        if (block) {
            block();
        }
    }];
}

#pragma mark - FBSlideViewDelegate

- (void)slideViewDidBakeConstraints:(FBSlideView *)slideView {
    __weak typeof(self) weakSelf = self;
    [self repositionFloatingViewIfNeededWithBlock:^{
        [weakSelf saveToolBarsPosition];
    }];
}

@end
