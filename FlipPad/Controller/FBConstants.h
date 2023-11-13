//
//  FBConstants.h
//  FlipPad
//
//  Created by Manton Reece on 10/28/15.
//  Copyright © 2015 DigiCel, Inc. All rights reserved.
//

// Palette color (DCFB)
#define kCurrentColorPrefKey @"CurrentColor"

// Tool usages
#define kLightboxOptionsUsed @"LightboxOptionsUsed"
#define kPencilOptionsUsed @"PencilOptionsUsed"

// Tool properties
#define kCurrentBrushPrefKey @"CurrentBrush"
#define kCurrentShapePrefKey @"CurrentShape"
#define kToolBarPositionChanged @"ToolBarPositionChanged"

// Tool sizes
#define kMinimumLineWidthsPrefKey @"MinimumLineWidths"
#define kMaximumLineWidthsPrefKey @"MaximumLineWidths"
#define kCurrentEraserWidthPrefKey @"CurrentEraserWidth"
#define kCurrentEraserHardnessPrefKey @"CurrentEraserHardness"
//
#define kCurrentSmoothingPrefKey @"CurrentSmoothing"
#define kCurrentAlphaPrefKey @"CurrentAlpha"

#define kLightboxEnabledPrefKey @"LightboxEnabled"
#define kLightboxBackgroundDisplayPrefKey @"LightboxBackgroundDisplayPrefKey"
#define kLightboxPreviousFramesPrefKey @"LightboxPreviousFrames"
// Tool selection
#define kUsingFillToolPrefKey @"UsingFillTool"
#define kUsingEraserToolPrefKey @"UsingEraserTool"
#define kUsingLassoToolPrefKey @"UsingLassoTool"

// Multiline
#define kMultilineVanishingPoint @"MultilineVanishingPoint"

#define kLoopEnabledPrefKey @"LoopEnabled"

#define kOpenRecently @"OpenRecently"

static NSString* const kExportingIncludeBlankCelsPrefKey = @"ExportingIncludeBlankCels";
static NSString* const kExportingIncludePencilOnlyPrefKey = @"ExportingIncludePencilOnly";
static NSString* const kExportingSplitLevelsPrefKey = @"ExportingSplitLevels";

#define kMinBrushSize (1.0f)
#define kMaxBrushSize (48.0f)

#define kBrushSelectedNotification @"FBBrushSelectedNotification"
#define kBrushSelectedBrushKey @"brush"
#define kBrushPressureSensitivityKey @"brush_pressure_sensitivity"
#define kBrushHardnessKey @"brush_hardness"
#define kBrushSmoothingKey @"brush_smoothing"

#define kShapeSelectedNotification @"FBShapeSelectedNotification"
#define kShapeSelectedShapeKey @"shape"

#define kReloadCurrentCellNotification @"FBReloadCurrentCellNotification"
#define kNewRowAddedCellNotification @"FBNewRowAddedCellNotification" // When New Row Added in Xsheet
#define kUpdateCurrentCellPencilKey @"pencil"
#define kUpdateCurrentCellPaintKey @"paint"
#define kUpdateCurrentCellStructureKey @"structure"
#define kUpdateCurrentCellBackgroundKey @"background"
#define kUpdateCurrentLightboxImageKey @"lightbox"
#define kUpdateIsCurrentlyPausedKey @"currently_paused"

#define kShowCompositedFrameImageKey @"image"

#define kShowCompositedIndexKey @"index"

#define kShowHelpNotification @"FBShowHelpNotification"
#define kShowHiddenResolutionsNotification @"FBShowHiddenResolutionsNotification"

#define kShowHelpPaneKey @"pane"

#define kSetupUndoSketchPencilKey @"pencil"
#define kSetupUndoSketchPaintKey @"paint"
#define kSetupUndoSketchStructureKey @"structure"
#define kSetupUndoSketchBackgroundKey @"background"

#define kUsingNonDrawableGesturePrefKey @"UsingNonDrawableGesture"

#define kCurrentFramesPerSecondPrefKey @"CurrentFPS"
#define kCurrentResolutionPrefKey @"CurrentResolution"
#define kSceneResolutionChangedNotification @"FBSceneResolutionChanged"

#define kAddNewSceneNotification @"FBAddNewScene"
#define kOpenSceneNotification @"FBOpenScene"
#define kShowScenesNotification @"FBShowScenes"

#define kLastSceneName @"FBLastSceneName"
#define kLastScenePath @"FBLastScenePath"
#define kLastSceneIndexPath @"FBLastSceneIndexPath"

#define kHideAllPopoversNotification @"FBHideAllPopovers"
#define kShowPencilOptionsNotification @"FBShowPencilOptions"

#define cutOrCopyRequestedWithPathNotification @"cutOrCopyRequestedWithPath"
#define kJumpXsheetPreviousNotification @"FBJumpXsheetPrevious"
#define kJumpXsheetNextNotification @"FBJumpXsheetNext"
#define kJumpXsheetLeftNotification @"FBJumpXsheetLeft"
#define kJumpXsheetRightNotification @"FBJumpXsheetRight"

#define kFinishedUpgradeNotification @"UIFocusDidUpdateNotification"

#ifdef FLIPBOOK
    #define kPhotosAlbumName @"FlipBook"
#else
    #define kPhotosAlbumName @"FlipPad"
#endif

#define kMinimumOpacityRange @"MinimumOpacityRange"
#define kMaximumOpacityRange @"MaximumOpacityRange"
#define kUpdateLightbox @"UpdateLightbox"

#define kDoneButtonTag 1

#define kDCFB @"dcfb"
#define kDGC @"dgc"

#define kUseThreshold @"useThreshold"
#define kThreshold @"threshold"
