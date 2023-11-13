//
//  FBSceneController.h
//  FlipBookPad
//
//  Created by Manton Reece on 3/9/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class FBDrawingView;
@class FBLassoView;
@class FBPasteView;

@class FBColorsController;
@class FBXsheetController;
@class FBSceneDocument;
@class FBUndoStorage;
@class FBPencilController;
@class FBEraserController;
@class FBFillController;
@class FBInfoController;
@class FBStylusSettingsController;
@class FBHelpController;
@class FBLightboxController;
@class FBButton;
@class FBTransformingSceneView;
@class ToolsToolbarView;
@class PlaybackToolbarView;

@protocol FBLassoViewDelegate;
@protocol FBPasteViewDelegate;
@protocol FBFillControllerDelegate;
@protocol CaptureExposureControllerDelegate;

#define kToolSegmentPencil 0
#define kToolSegmentEraser 1
#define kToolSegmentFill 2
#define kToolSegmentLasso 3

@protocol FBSceneControllerDelegate <NSObject>

- (void)sceneControllerWillCloseForDocumentAtPath:(NSString* )path;

@end

typedef NS_ENUM(NSUInteger, FBFillMode) {
    FBFillModeNormal,
    FBFillModeAutoAdvance,
    FBFillModeAutoFillLevel,
    FBFillModeDragAndFill
};

typedef NS_ENUM(NSUInteger, FBCanvasTransformMode) {
    FBCanvasTransformModeNone,
    FBCanvasTransformModeMove,
    FBCanvasTransformModeZoom,
    FBCanvasTransformModeRotate
};

#if TARGET_OS_MACCATALYST
@interface FBSceneController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentPickerDelegate, FBLassoViewDelegate, FBPasteViewDelegate, NSToolbarDelegate>
#else
@interface FBSceneController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentPickerDelegate, FBLassoViewDelegate, FBPasteViewDelegate, FBFillControllerDelegate, CaptureExposureControllerDelegate>
#endif
{
    FBSceneDocument* fDocument;
    FBXsheetController* fXsheetController;
    
    UIButton* fExitFullscreenButton;
    NSMutableDictionary* fCels; // key is NSIndexPath, value is FBCell
    UIAlertController* zoomSheet;
    UIBarButtonItem* fTitleButton;

    UISwipeGestureRecognizer* fSwipePreviousGesture;
    UISwipeGestureRecognizer* fSwipeNextGesture;
    UISwipeGestureRecognizer* fSwipeLeftGesture;
    UISwipeGestureRecognizer* fSwipeRightGesture;
}

@property (weak, nonatomic) id<FBSceneControllerDelegate> delegate;


typedef NS_ENUM(NSUInteger, FBSceneState) {
    FBSceneStateEditing,
    FBSceneStatePlaying,
    FBSceneStatePaused,
};

#pragma mark - Drawing, Lasso views

@property (weak, nonatomic) IBOutlet FBTransformingSceneView *transformingSceneView;

@property (strong, nonatomic) UIView* containerView;
@property (strong, nonatomic) UIView* contentView;

@property (strong, nonatomic) FBDrawingView* drawingView;
@property (strong, nonatomic) FBLassoView* lassoView;
@property (strong, nonatomic) FBPasteView* pasteView;

#pragma mark - Controllers

@property (strong, nonatomic) IBOutlet FBXsheetController *xsheetController;

@property (strong, nonatomic) FBColorsController* colorsController;

@property (strong, nonatomic) FBPencilController* pencilOptionsController;
@property (strong, nonatomic) FBEraserController* eraserOptionsController;
@property (strong, nonatomic) FBFillController* fillOptionsController;

@property (strong, nonatomic) FBStylusSettingsController* jotSettingsController;
@property (strong, nonatomic) FBLightboxController* lightboxController;
@property (strong, nonatomic) FBHelpController* helpController;

#pragma mark - Toolbar

@property (strong, nonatomic) ToolsToolbarView* navigationToolbar;
@property (strong, nonatomic) ToolsToolbarView* toolsToolbar;
@property (strong, nonatomic) PlaybackToolbarView* playbackToolbar;

@property (strong, nonatomic) IBOutlet UIToolbar* topToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar* bottomPlaybackToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar* bottomImageCaptureToolbar;
@property (weak, nonatomic) IBOutlet UIStackView *bottomToolbarStackView;

@property (strong, nonatomic) UIImageView *pencilItemImageView;
@property (strong, nonatomic) UIImageView *eraserItemImageView;
@property (strong, nonatomic) UIImageView *fillItemImageView;
@property (strong, nonatomic) UIImageView *lassoItemImageView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *pencilItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *eraserItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fillItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *lassoItem;

#pragma mark -

@property (weak, nonatomic) IBOutlet UIBarButtonItem *scenesButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* titleButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* xsheetButton;
@property (strong, nonatomic) IBOutlet UIView* helpView;
@property (strong, nonatomic) IBOutlet UILabel* helpField;
@property (strong, nonatomic) IBOutlet UIScrollView* helpScrollView;
@property (strong, nonatomic) IBOutlet UIView* helpScrollViewBackground;
@property (strong, nonatomic) IBOutlet UILabel* lightBoxRefranceView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topToolBarConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomToolbarConstraint;

//@property(nonatomic, strong) NSLayoutConstraint *edgeXSheetAnchor;
//@property(nonatomic, strong) NSLayoutConstraint *edgeScrollViewAnchor;
//@property(nonatomic, strong) NSLayoutConstraint *edgeMediumAnchor;

@property (strong, nonatomic) FBSceneDocument* document;
@property (strong, nonatomic) UINavigationController* colorsNavigationController;
@property (strong, nonatomic) FBUndoStorage* undoHistory;

@property (assign) BOOL isFullscreen;
@property (assign, nonatomic) FBFillMode fillMode;
@property (assign, nonatomic) FBSceneState state;

@property (strong, nonatomic) UINavigationController* lightboxNavigationController;

@property (strong, nonatomic) FBButton* lightboxButton;
@property (strong, nonatomic) UIButton* paletteButton;
@property (strong, nonatomic) UILongPressGestureRecognizer* lightboxHoldGesture;
@property (strong, nonatomic) UIBarButtonItem* paletteItem;
@property (assign, nonatomic) BOOL isEditingEnabled;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rewindButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *fastForwardButtonItem;

- (BOOL)isPlaying;

- (id) initWithDocument:(FBSceneDocument *)inDocument;
- (IBAction) closeScene:(id)inSender;
- (IBAction) showXsheet:(id)inSender;
- (IBAction) showColors:(id)inSender;

- (IBAction) undo:(id)inSender;
- (IBAction) redo:(id)inSender;

- (void) playScene:(id)inSender;
- (void) pauseScene:(id)inSender;

- (void)showToolbars;

- (IBAction) toggleEraserTool;
- (void)updateUndoButtons;

- (void) showCompositedIndex:(NSInteger)index;
- (UIImage *)compositedImageAtRow:(NSInteger)row fromLevel:(NSInteger)fromLevel toLevel:(NSInteger)toLevel;
- (void) switchToDrawingState;

- (void)updateSliderForRow:(NSInteger)row;

- (void)didMoveToRelativePosition:(CGFloat)position;
- (void)updatePause;

- (void) enterFullscreen;
- (void) exitFullscreen;

- (void)startImageCapture;

- (void)refreshPuck;

- (void)lockDrawingView;
- (void)unlockDrawingView;

- (void)configureScrubSoundPlayers;

- (void)zoom75;
- (void)zoom100;
- (void)zoom200;
- (void)zoomToFill;
- (void)zoomToFit;

- (void)importAudio;
- (void)importImage;
- (void)importVideo;

- (void)makeExport;

@end

