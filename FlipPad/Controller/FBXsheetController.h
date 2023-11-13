//
//  FBXsheetController.h
//  FlipBookPad
//
//  Created by Manton Reece on 3/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "SelectedItem.h"
#import "FBCelDragDropModel.h"

@class FBXsheetStorage;
@class FBSceneController;
@class FBCelStack;
@class FBDrawingView;

@protocol FBSketchViewDelegate;
@protocol XSheetTableCellDelegate;
@protocol FBTimingControllerDelegate;
@protocol SoundWaveViewControllerDelegate;
@protocol XSheetHeaderViewDelegate;
@protocol FBColumnsControllerDelegate;
@protocol FBSlideViewDataSource;

@interface FBXsheetController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MPMediaPickerControllerDelegate, UIDocumentPickerDelegate, FBSketchViewDelegate, UIDragInteractionDelegate, UIDropInteractionDelegate, XSheetTableCellDelegate, FBTimingControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, SoundWaveViewControllerDelegate, XSheetHeaderViewDelegate, FBColumnsControllerDelegate, FBSlideViewDataSource>
{
    UIButton* fAddButton;
    UIButton* fDeleteButton;
    UIButton* fInsertButton;
    BOOL fRowIsSelectedForAction;
    NSInteger fNumUserColumns;
    FBXsheetStorage* fStorage;
    NSIndexPath* selectedRow;
    NSLayoutConstraint *tableViewWidtchConstraint;
}

@property (strong, nonatomic) UITableView* fTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *chooseImportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* rollButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* actionsButton;
@property (weak, nonatomic) IBOutlet FBSceneController* sceneController;
@property (weak, nonatomic) FBDrawingView* drawingView;
 
@property (strong, nonatomic) UIDocumentInteractionController* openInController;
@property (strong, nonatomic) MPMediaPickerController* mediaController;
@property (strong, nonatomic) FBCelStack* lightboxStack;

@property (assign, nonatomic) BOOL isAutomaticSelection;
@property (assign, nonatomic) BOOL isRollPrevious;
@property (assign, nonatomic) BOOL isPausing;

@property (strong, nonatomic) NSTimer* updateCellTimer;

@property (strong, nonatomic) UIAlertController *alertContoller;

@property (strong) SelectedItem *selectedItem;

typedef NS_ENUM(NSInteger, importType) {
    audio = 0,
    image = 1,
    video = 2
};

@property (nonatomic, assign) enum importType impType;

- (IBAction) showScenes:(id)inSender;
- (IBAction) takePicture:(id)inSender;
- (IBAction) addRow:(id)inSender;
- (IBAction) showTiming:(id)inSender;

- (void)selectRow:(NSInteger)row item:(NSInteger)item;

- (void) selectFirstRow;
- (void) selectLastRow;

- (void) selectPreviousRow;
- (void) selectNextRow;

- (void)selectPreviousColumn;
- (void)selectNextColumn;

- (void)selectPreviousCell;
- (void)selectNextCell;

- (void)setupSoundWave;

- (void) pauseCurrentRow;
- (void) pauseFirstRow;
- (void) pauseLastRow;
- (void) pausePreviousRow;
- (void) pauseNextRow;
- (void) imageFromUrl: (NSURL *) url;
- (void) receiveUpdateLightboxNotification: (NSNotification *) notification;

- (UIImage *)buildLightboxImageAtPreviousRow:(NSInteger)inRow column:(NSInteger)inColumn;

- (void) pasteWithCapturedPencilImage:(UIImage *)inImage;
- (void) pasteWithImage:(UIImage *)inImage;

- (void)applyAutoFill;

- (void)cut:(id)inSender;
- (void)copy:(id)inSender;
- (void)paste:(id)inSender;

- (void)importAudio;
- (void)importAudioWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem;

- (void)importImage;
- (void)importImageWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem;

- (void)importVideo;
- (void)importVideoWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem;

- (void)makeExport;

@end
