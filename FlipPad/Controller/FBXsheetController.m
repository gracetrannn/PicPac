//
//  FBXsheetController.m
//  FlipBookPad
//
//  Created by Manton Reece on 3/17/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBXsheetController.h"

#import "Header-Swift.h"
#import "FBDCFBSceneDatabase.h"
#import "FBCell.h"
#import "FBConstants.h"
#import "FBInsertRowsController.h"
#import "UIImage_Extras.h"
#import "FBImage_Extras.h"
#import "NSURL_Extras.h"
#import "FBMovieExporter.h"
#import "FBPrefs.h"
#import "FBTimingController.h"
#import "FBColumnsController.h"
#import "FBSceneController.h"
#import "FBSceneDocument.h"
#import "NSString_Extras.h"
#import "FBUtilities.h"
#import "FBCelStack.h"
#import "FBMacros.h"
#import "FBLimits.h"
#import "FBLightboxController.h"
#import "FBHelpController.h"
#import "NSDictionary_Extras.h"
#import "FBLandscapeImagePickerController.h"
#import "UUImage.h"
#import <QuartzCore/CALayer.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Bundle.h"
#import "FBSceneDatabase.h"

#define kDefaultGridCellHeight 60.0
#define kDefaultGridCellWidth 80.0
#define kDefaultGridRowNumberWidth 40.0
#define kDefaultGridViewWidth 200.0
#define kDefaultGridHeaderHeight 30.0

#define kSpacingLineSize 1.0
#define kXsheetCellIdentifier @"XSheetTableCell"
#define kXSheetHeaderView @"XSheetHeaderView"

#pragma mark -

@interface FBXsheetController ()

@property (strong, nonatomic) FBPreviewCache *previewCache;

@property (strong, nonatomic) SoundWaveViewController* soundWaveController;
@property (strong, nonatomic) NSLayoutConstraint* soundViewWidthConstraint;

@property (nonatomic) BOOL isPaste;

@property (assign, nonatomic) NSInteger tappedRow;
@property (assign, nonatomic) NSInteger tappedItem;

#if TARGET_OS_MACCATALYST

@property (assign, nonatomic) CGFloat originOffsetY;

#endif

@property (strong, nonatomic) FBImage* currentFillImage;

@end

@implementation FBXsheetController

@synthesize fTableView;

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _tappedRow = -1;
    _tappedItem = -1;
    
    _previewCache = [FBPreviewCache new];
    
    [_actionsButton setWidth:44];
    fStorage = [[self.sceneController document] storage];
    fNumUserColumns = [fStorage numberOfColumns];
    if (fNumUserColumns < 2) {
        fNumUserColumns = 2;
    }
    for (NSInteger level = 1; level <= fNumUserColumns; level++) {
        [fStorage getLevelWidthWithLevel:level twidth:80];
    }

    self.lightboxStack = [[FBCelStack alloc] init];
        
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOpacity = 0.7;
    self.view.layer.shadowOffset = CGSizeMake (1.0, 0.0);
    self.view.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor;
    self.view.layer.borderWidth = 1.0f;
    self.view.layer.cornerRadius = 6.0;

//    [self setupGestures];
    [self setupTableView];
    [self setupButtons];
    
    _selectedItem.item = 1;
    _isPaste = FALSE;
    
    [fTableView reloadData];
    
    [self selectSavedRow];
    [self updateRollButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveUpdateLightboxNotification:) name:kUpdateLightbox object:nil];

    [self setupNotifications];
    
#if TARGET_OS_MACCATALYST
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(panGestureRecognizerHandler:)];
    [fTableView addGestureRecognizer:panGestureRecognizer];
#endif
}

//- (void) setupGestures
//{
//    UISwipeGestureRecognizer* swipe_gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
//    swipe_gesture.direction = UISwipeGestureRecognizerDirectionLeft;
//    [self.view addGestureRecognizer:swipe_gesture];
//}

- (void) setupTableView
{
    selectedRow = [NSIndexPath indexPathForRow:0 inSection:0];

    fTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [fTableView registerNib:[UINib nibWithNibName:kXSheetHeaderView bundle:nil] forHeaderFooterViewReuseIdentifier:kXSheetHeaderView];
    [fTableView registerNib:[UINib nibWithNibName:kXsheetCellIdentifier bundle:nil] forCellReuseIdentifier: kXsheetCellIdentifier];
    //
    CGRect frame = CGRectZero;
    frame.size.height = CGFLOAT_MIN;
    [fTableView setTableHeaderView:[[UIView alloc] initWithFrame:frame]];
    //
//    if (@available(iOS 15.0, *)) {
//        fTableView.sectionHeaderTopPadding = 0.0;
//    }
    fTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:fTableView];
    
    _soundWaveController = [SoundWaveViewController new];
    [_soundWaveController setHeaderTitle:[[_sceneController.document database] levelNameAtIndex:-1]];
    [_soundWaveController setIsLocked:[[_sceneController.document database] isLevelLockedAtIndex:-1]];
    [_soundWaveController setDelegate:self];

    [self addChildViewController:_soundWaveController];
    UIView* soundView = _soundWaveController.view;
    soundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:soundView];
    [_soundWaveController didMoveToParentViewController:self];
    
    [[[fTableView leadingAnchor] constraintEqualToAnchor:[self.view leadingAnchor]] setActive:YES];
    [[[fTableView topAnchor] constraintEqualToAnchor:[self.view topAnchor]] setActive:YES];
    [[[fTableView bottomAnchor] constraintEqualToAnchor:[self.view.safeAreaLayoutGuide bottomAnchor] constant:-44.0] setActive:YES];
    
    [[[fTableView trailingAnchor] constraintEqualToAnchor:[soundView leadingAnchor]] setActive:YES];
    
    [[[soundView topAnchor] constraintEqualToAnchor:[self.view topAnchor]] setActive:YES];
    [[[soundView bottomAnchor] constraintEqualToAnchor:[self.view.safeAreaLayoutGuide bottomAnchor] constant:-44.0] setActive:YES];
    [[[soundView trailingAnchor] constraintEqualToAnchor:[self.view trailingAnchor]] setActive:YES];
    _soundViewWidthConstraint = [[soundView widthAnchor] constraintEqualToConstant:0.0];
    [_soundViewWidthConstraint setActive:YES];
    
    [self setupSoundWave];
    [self setupTableWidthConstraint];
    
    [fTableView setTableFooterView:[[UIView alloc]initWithFrame:CGRectZero]];
    [fTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    fTableView.backgroundColor = [UIColor lightGrayColor];
    fTableView.delegate = self;
    fTableView.dataSource = self;
    if (@available(iOS 10.0, *)) {
        fTableView.prefetchDataSource = self;
    }
    [fTableView setEstimatedRowHeight:60.0];
    [fTableView setRowHeight:60.0];
    
    [fTableView setEstimatedSectionHeaderHeight:30.0];
    [fTableView setSectionHeaderHeight:30.0];
}

- (void)setupTableWidthConstraint
{
    NSInteger visibleColumnsCount = 0;
    for (int i = 0; i < fNumUserColumns; i++) {
        if (![_sceneController.document.database isLevelHiddenAtIndex:i]) {
            visibleColumnsCount += 1;
        }
    }
    CGFloat width = (visibleColumnsCount * kDefaultGridCellWidth) + kDefaultGridRowNumberWidth;
    if (tableViewWidtchConstraint) {
        [tableViewWidtchConstraint setConstant:width];
    } else {
        tableViewWidtchConstraint = [[fTableView widthAnchor] constraintEqualToConstant:width];
        [tableViewWidtchConstraint setActive:YES];
    }
}

- (void)setupSoundWave
{
    // Audio
    NSData* audioData = [self.sceneController.document soundData];
    BOOL isSoundLocked = [self.sceneController.document.database isLevelLockedAtIndex:-1];
    BOOL isSoundHidden = [self.sceneController.document.database isLevelHiddenAtIndex:-1];
    if (audioData && !isSoundHidden)
    {
        NSString* tempAudioPath = [NSTemporaryDirectory() stringByAppendingString:@"TempAudio.m4a"];
        if ([NSFileManager.defaultManager fileExistsAtPath:tempAudioPath]) {
            [NSFileManager.defaultManager removeItemAtPath:tempAudioPath error:nil];
        }
        [NSFileManager.defaultManager createFileAtPath:tempAudioPath contents:audioData attributes:nil];
        NSURL* audioUrl = [NSURL fileURLWithPath:tempAudioPath isDirectory:NO];
        // FPS
        NSInteger fps = [self.sceneController.document fps];
        // Offset
        CGFloat offset = [self.sceneController.document soundOffset];
        //
        [_soundWaveController loadAudioWithUrl:audioUrl fps:fps offsetFrames:offset];
        //
        [_soundViewWidthConstraint setConstant:64.0];
        [_soundWaveController setIsLocked:isSoundLocked];
    } else {
        [_soundViewWidthConstraint setConstant:0.0];
    }
    [self.view layoutIfNeeded];
}

- (void) setupButtons
{
    UIStackView* stackview = [[UIStackView alloc] initWithFrame:CGRectZero];
    stackview.translatesAutoresizingMaskIntoConstraints = NO;
    stackview.alignment = UIStackViewAlignmentFill;
    stackview.axis = UILayoutConstraintAxisHorizontal;
    stackview.spacing = 0.0;
    stackview.distribution = UIStackViewDistributionFillEqually;
    UIVisualEffectView* backView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    backView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backView];
    [backView.contentView addSubview:stackview];
    
    [[[backView leadingAnchor] constraintEqualToAnchor:[self.view leadingAnchor]] setActive:YES];
    [[[backView trailingAnchor] constraintEqualToAnchor:[self.view trailingAnchor]] setActive:YES];
    [[[backView topAnchor] constraintEqualToAnchor:[fTableView bottomAnchor]] setActive:YES];
    [[[backView bottomAnchor] constraintEqualToAnchor:[self.view bottomAnchor]] setActive:YES];
    
    [[[stackview topAnchor] constraintEqualToAnchor:[backView topAnchor]] setActive:YES];
    [[[stackview leftAnchor] constraintEqualToAnchor:[backView leftAnchor]] setActive:YES];
    [[[stackview rightAnchor] constraintEqualToAnchor:[backView rightAnchor]] setActive:YES];
    [[[stackview bottomAnchor] constraintEqualToAnchor:[self.view.safeAreaLayoutGuide bottomAnchor]] setActive:YES];

//    fAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    fAddButton.translatesAutoresizingMaskIntoConstraints = NO;
//    [fAddButton setTitle:@">" forState:UIControlStateNormal];
//    [fAddButton addTarget:self action:@selector(addRow:) forControlEvents:UIControlEventTouchUpInside];
//    [stackview addArrangedSubview:fAddButton];
    
    fInsertButton = [UIButton buttonWithType:UIButtonTypeCustom];
    fInsertButton.translatesAutoresizingMaskIntoConstraints = NO;
    fInsertButton.tintColor = [UIColor lightTextColor];
    [fInsertButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [fInsertButton addTarget:self action:@selector(addRowBelowSelectedRow:) forControlEvents:UIControlEventTouchUpInside];
    [stackview addArrangedSubview:fInsertButton];
    
    fDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    fDeleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    fDeleteButton.tintColor = [UIColor lightTextColor];
    [fDeleteButton setImage:[UIImage imageNamed:@"minus"] forState:UIControlStateNormal];
    [fDeleteButton addTarget:self action:@selector(deleteRow:) forControlEvents:UIControlEventTouchUpInside];
    [stackview addArrangedSubview:fDeleteButton];
}

- (void) setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCurrentCellNotification:) name:kReloadCurrentCellNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideAllPopoversNotification:) name:kHideAllPopoversNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToPreviousFrameNotification:) name:kJumpXsheetPreviousNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToNextFrameNotification:) name:kJumpXsheetNextNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToLeftColumnNotification:) name:kJumpXsheetLeftNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToRightColumnNotification:) name:kJumpXsheetRightNotification object:nil];
}

#pragma mark - FBSketchViewDelegate

- (void)refreshCellPreviewWithImage:(FBImage *)image
{    
    NSLog(@"🖼 Refreshed preview");
    [_previewCache setPreviewImage:image withRow:_selectedItem.row item:_selectedItem.item];
    
    FBCell* cloneCell = [FBCell emptyCel];
    [cloneCell setPencilImage:image];
    
    if (_selectedItem.item == 1) {
        [_lightboxStack pushBackgroundCell:cloneCell withRow:_selectedItem.row column:_selectedItem.item];
    } else {
        [_lightboxStack push:cloneCell withRow:_selectedItem.row column:_selectedItem.item];
    }
    
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)updateWithPencilImage:(FBImage * _Nullable)pencilImage structureImage:(FBImage * _Nullable)structureImage fillImage:(FBImage * _Nullable)fillImage {
    NSLog(@"✏️ Updated Pencil & Structure img");
    FBCellOriginal* cell = [fStorage getCellOriginalAtRow:_selectedItem.row column:_selectedItem.item];
    if (cell != nil && ![cell isEmpty]) {
        [fStorage storeCellOriginal:cell atRow:_selectedItem.row column:_selectedItem.item];
    } else {
        FBCell* oldCel = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
        if (!oldCel) {
            oldCel = [[FBCell alloc] init];
        }
        oldCel.pencilImage = pencilImage;
        oldCel.structureImage = structureImage;
        oldCel.paintImage = fillImage;
        oldCel.isLoaded = YES;
        [fStorage storeCell:oldCel atRow:_selectedItem.row column:_selectedItem.item];
    }
}

- (void)applyAutoFill {
    [_drawingView saveChanges];
    [self fillLevelCellsAt:CGPointZero
                      size:_drawingView.size
           onlyCurrentCell:NO];
}

- (void)fillLevelCellsWithOnlyCurrentCell:(BOOL)onlyCurrentCell {
    [_drawingView saveChanges];
    [self fillLevelCellsAt:CGPointZero
                      size:_drawingView.size
           onlyCurrentCell:YES];
}

- (void)fillLevelCellsAt:(CGPoint)point
                    size:(CGSize)size
         onlyCurrentCell:(BOOL)onlyCurrentCell {
    
    if (onlyCurrentCell) {
        SettingsBundleHelper.editModeDevice = YES;
    }
    FBImage *previousFill = _drawingView.getCurrentImages[@"paint"];
            
        if (_currentFillImage == nil) {
            UIColor *ccolor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
            _currentFillImage = [[FBImage alloc] initWithSize:_drawingView.bounds.size
                                                    fillColor:ccolor];
        }
    
    CGFloat minX = 0.0f;
    CGFloat minY = 0.0f;
    CGFloat maxX = size.width - 1.0f;
    CGFloat maxY = size.height - 1.0f;
    NSArray *locations = @[
        [NSValue valueWithCGPoint:CGPointMake(minX, minY)],
        [NSValue valueWithCGPoint:CGPointMake(minX, maxY)],
        [NSValue valueWithCGPoint:CGPointMake(maxX, maxY)],
        [NSValue valueWithCGPoint:CGPointMake(maxX, minY)]
    ];
    NSArray *orderedLocations = [locations sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull lhs, id  _Nonnull rhs) {
        CGPoint p0 = [lhs CGPointValue];
        CGPoint p1 = [rhs CGPointValue];
        CGFloat d0 = hypotf((p0.x - point.x), (p0.y - point.y));
        CGFloat d1 = hypotf((p1.x - point.x), (p1.y - point.y));
        return d0 < d1;
    }];
    UIColor *color = [[_drawingView getCurrentColor] colorWithAlphaComponent:[_drawingView getCurrentAlpha]];
    NSInteger numberOfRows = [fStorage numberOfRows];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AutoFill Processing"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    if (onlyCurrentCell) {
        [alert setTitle:[NSString stringWithFormat:@"AutoFill Cell"]];
    } else {
        [alert setTitle:[NSString stringWithFormat:@"AutoFill Processing: 0 / %li", (long)numberOfRows]];
    }
    [_sceneController presentViewController:alert
                                   animated:YES
                                 completion:nil];
    NSInteger start = onlyCurrentCell ? _selectedItem.row : 1;
    NSInteger end = onlyCurrentCell ? _selectedItem.row : numberOfRows;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSInteger i = start; i <= end; i++) {
            @autoreleasepool {
                FBCell *cell = [self->fStorage cellAtRow:i
                                                  column:self->_selectedItem.item];
                FBImage *previousPaintImage = [cell paintImage];
                FBImage *newPaintImage = [[FBImage alloc] initWithSize:size
                                                             fillColor:color];
                [newPaintImage imageByAdding:previousPaintImage];
                BOOL isErased = NO;
                for (NSValue *locationValue in orderedLocations) {
                    CGPoint point = [locationValue CGPointValue];
                    UIImage *uiImage = [cell.structureImage previewUiImage];
                    UIColor *pixelColor = [uiImage pixelColorAtX:(int)point.x
                                                               y:(int)point.y];
                    BOOL isSame = [pixelColor isSameToColor:color];
                    if (isSame) {
                        isErased = YES;
                        [newPaintImage fillAt:point
                                    structure:[cell structureImage]
                                        color:[UIColor colorWithRed:0.0f
                                                              green:0.0f
                                                               blue:0.0f
                                                              alpha:0.0f].CGColor
                                    threshold:SettingsBundleHelper.threshold
                                 colorToErase:color.CGColor];
                        break;
                    }
                }
                if (isErased) {
                    [cell setPaintImage:newPaintImage];
                    [self->fStorage storeCell:cell
                                        atRow:i
                                       column:self->_selectedItem.item];
                }
                [self->_previewCache removeAll];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!onlyCurrentCell) {
                        [alert setTitle:[NSString stringWithFormat:@"AutoFill Processing: %li / %li", (long)i, (long)numberOfRows]];
                    }
                    [self->_drawingView redraw];
                    [self->fTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(i - 1)
                                                                                  inSection:0]]
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
                    if (i == end) {
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        [self selectRow:self->_selectedItem.row
                                   item:self->_selectedItem.item];
                        
                        if (onlyCurrentCell) {
                            [weakSelf.drawingView autofillCellFinishedWithPreviousImage: previousFill];
                            weakSelf.currentFillImage = nil;
                        }

                    }
                });
            }
        }
    });
    
    
}

- (void)selectNextRowWithContent
{
    NSInteger nextRow = _selectedItem.row + 1;
    
    for (NSInteger i = nextRow; i <= [fStorage numberOfRows]; i++)
    {
        // if next cell is not empty
        FBCell* nextCel = [fStorage cellAtRow:i column:_selectedItem.item];
        
        if (![nextCel isEmpty])
        {
            // Select
            [self selectRow:i item:_selectedItem.item];
            [self revealCurrentRow];
            break;
        }
    }
}

#pragma mark -

- (void) updateRollButton
{
    if (_selectedItem.row == 1) {
        [self.rollButton setEnabled:NO];
    } else {
        [self.rollButton setEnabled:YES];
    }
}

//- (void) swipeLeft
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:kHideXsheetNotification object:self];
//}

#pragma mark - Selection handling

- (void)reselectCurrent
{
    if (_selectedItem.mode == Item) {
        [_drawingView saveChanges];
        [self selectRow:_selectedItem.row item:_selectedItem.item];
    } else {
        [self selectEntireRow:_selectedItem.row];
    }
    
}

- (void)selectRow:(NSInteger)row item:(NSInteger)item
{
    [self->fStorage cellOriginalAtRow:row column:item];
    [self selectRow:row item:item ignoreDisplaying:NO];
}

- (void)selectRow:(NSInteger)row item:(NSInteger)item ignoreDisplaying:(BOOL)ignoreDisplaying
{
    _tappedRow = row;
    _tappedItem = item;
    
    NSInteger previouslySelectedRow = _selectedItem.row;
    FBStackInfo* lastLightboxInfo = [self lastLightboxInfo];
    
    _selectedItem = [[SelectedItem alloc] init];
    _selectedItem.row = row;
    _selectedItem.item = item;
    _selectedItem.mode = Item;

    /// Update lightbox
    [self updateLightboxStackAtCollectionRow:_selectedItem.row item:_selectedItem.item];
    
    /// Enable drawing when a SINGLE cell is selected
    if (!ignoreDisplaying) {
        [[[self sceneController] drawingView] setIsTouchEnabled:YES];
        [[self sceneController] showToolbars];
    }
    
    [self updateRollButton];
    [self deselectAllRows];
    fRowIsSelectedForAction = NO;
    
    if (!ignoreDisplaying) {
        UIImage* previous_img = [self buildLightboxImageAtPreviousRow:_selectedItem.row column:_selectedItem.item];
        FBCell* tapped_cel = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
        if([tapped_cel isBackground] && _selectedItem.row > 1) {
            tapped_cel = [FBCell emptyCel];
        }
        [self notifyLoadCel:tapped_cel previousImage:previous_img];
    }
    
    if (previouslySelectedRow >= 1) {
        NSLog(@"Reloading %i", (int)(previouslySelectedRow - 1));
        [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(previouslySelectedRow - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];

        if (lastLightboxInfo) {
            NSLog(@"Reloading %i", (int)(lastLightboxInfo.row - 1));
            [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(lastLightboxInfo.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    
    NSLog(@"Reloading %i", (int)(_selectedItem.row - 1));
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
    
    // Lock / Unlock
    BOOL isLocked = [_sceneController.document.database isLevelLockedAtIndex:(item - 1)];
    if (isLocked) {
        [self.sceneController lockDrawingView];
    } else {
        [self.sceneController unlockDrawingView];
    }
}

- (void)selectSavedRow {
    NSInteger row = 1;
    NSInteger item = 1;
    NSObject<FBSceneDatabase> *database = self.sceneController.document.database;
    [database getSelectedRow:&row
                selectedItem:&item];
    [self selectRow:row
               item:item];
}

- (void)selectFirstRow
{
    [self selectRow:1 item:1];
}

- (void)selectLastRow
{
    [self selectRow:[fStorage numberOfRows] item:1];
}

- (void)selectPreviousRow
{
    [self.drawingView saveChanges];
    if (_selectedItem.row > 1) {
        if (_selectedItem.mode == Item) {
            [self selectRow:_selectedItem.row - 1 item:_selectedItem.item];
        } else {
            [self selectEntireRow:_selectedItem.row - 1];
        }
        [self revealCurrentRow];
        [self.sceneController updateSliderForRow:_selectedItem.row];
    }
}

- (void)selectNextRow
{
    [self.drawingView saveChanges];
    if (_selectedItem.row < [fStorage numberOfRows]) {
        if (_selectedItem.mode == Item) {
            [self selectRow:_selectedItem.row + 1 item:_selectedItem.item];
        } else {
            [self selectEntireRow:_selectedItem.row + 1];
        }
        [self revealCurrentRow];
        [self.sceneController updateSliderForRow:_selectedItem.row];
    }
}

- (void)selectPreviousColumn
{
    [self.drawingView saveChanges];
    if (_selectedItem.item > 1) {
        [self selectRow:_selectedItem.row item:_selectedItem.item - 1];
        [self revealCurrentRow];
    }
}

- (void)selectNextColumn
{
    [self.drawingView saveChanges];
    if (_selectedItem.item < [fStorage numberOfColumns]) {
        [self selectRow:_selectedItem.row item:_selectedItem.item + 1];
        [self revealCurrentRow];
    }
}

- (void)selectPreviousCell
{
    NSInteger width = [fStorage numberOfColumns];
    
    if (_selectedItem.mode == Item) {
        if (_selectedItem.item == 1) {
            if (_selectedItem.row > 1) {
                [self selectRow:_selectedItem.row - 1 item:width];
            }
        } else {
            [self selectRow:_selectedItem.row item:_selectedItem.item - 1];
        }
    }
}

- (void)selectNextCell
{
    NSInteger width = [fStorage numberOfColumns];
    
    if (_selectedItem.mode == Item) {
        if (_selectedItem.item == width) {
            if (_selectedItem.row < [fStorage numberOfRows]) {
                [self selectRow:_selectedItem.row + 1 item:1];
            }
        } else {
            [self selectRow:_selectedItem.row item:_selectedItem.item + 1];
        }
    }
}

#pragma mark -

#if TARGET_OS_MACCATALYST

- (void)panGestureRecognizerHandler:(UIPanGestureRecognizer *)sender {
    CGFloat contentHeight = fStorage.numberOfRows * kDefaultGridCellHeight;
    CGFloat height = fTableView.frame.size.height;
    if (contentHeight <= height) {
        return;
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        _originOffsetY = fTableView.contentOffset.y;
        return;
    }
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat y = _originOffsetY - [sender translationInView:sender.view].y;
        if (y < -kDefaultGridHeaderHeight) {
            y = -kDefaultGridHeaderHeight;
        }
        CGFloat value = contentHeight - height + kDefaultGridHeaderHeight;
        if (y > value) {
            y = value;
        }
        [fTableView setContentOffset:CGPointMake(0.0f, y)
                            animated:NO];
        return;
    }
}

#endif

#pragma mark - Pause handling

- (void)pauseRow:(NSInteger)rowNumber
{
    [self pauseRow:rowNumber ignoreDisplaying:NO];
}

- (void)pauseRow:(NSInteger)rowNumber ignoreDisplaying:(BOOL)ignoreDisplaying
{
    if ((rowNumber >= 1) && (rowNumber <= [fStorage numberOfRows])) {
        NSInteger previouslySelectedRow = _selectedItem.row;
        FBStackInfo* lastLightboxInfo = [self lastLightboxInfo];
        
        _selectedItem = [[SelectedItem alloc] init];
        _selectedItem.item = -1;
        _selectedItem.row = rowNumber;
        _selectedItem.mode = Row;
        
        if (!ignoreDisplaying) {
            [_sceneController showCompositedIndex:rowNumber - 1];
        }
        
        if (previouslySelectedRow >= 1) {
            [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(previouslySelectedRow - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
            if (lastLightboxInfo) {
                [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(lastLightboxInfo.row) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)pauseCurrentRow
{
    [self pauseRow:_selectedItem.row];
}

- (void)pauseFirstRow
{
    [self pauseRow:1];
}

- (void)pauseLastRow
{
    [self pauseRow:[fStorage numberOfRows]];
}

- (void)pausePreviousRow
{
    if (_selectedItem.row > 1) {
        [self pauseRow:_selectedItem.row - 1];
        [self revealCurrentRow];
    }
    [self.sceneController didMoveToRelativePosition:(CGFloat)(_selectedItem.row) / (CGFloat)([self->fStorage numberOfRows])];
}

- (void)pauseNextRow
{
    if (_selectedItem.row < [fStorage numberOfRows]) {
        [self pauseRow:_selectedItem.row + 1];
        [self revealCurrentRow];
    }
    [self.sceneController didMoveToRelativePosition:(CGFloat)(_selectedItem.row) / (CGFloat)([self->fStorage numberOfRows])];
}

#pragma mark - Scrolling to row

- (void)revealCurrentRow
{
    if (_selectedItem.row < 1 || _selectedItem.row > [fStorage numberOfRows]) {
        return;
    }
    [fTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedItem.row - 1 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

#pragma mark - Notifications

- (void)reloadCurrentCellNotification:(NSNotification *)inNotification
{
    self.isAutomaticSelection = YES;
    
    [self.drawingView saveChanges];
    if (_selectedItem.mode == Row) {
        [self selectEntireRow:_selectedItem.row];
    } else {
        [self selectRow:_selectedItem.row item:_selectedItem.item];
    }
    [fTableView reloadData];
    
    self.isAutomaticSelection = NO;
}

- (void)hideAllPopoversNotification:(NSNotification *)inNotification
{
    if (_alertContoller) {
        [_alertContoller dismissViewControllerAnimated:true completion:nil];
        _alertContoller = nil;
    }
}

- (void)jumpToPreviousFrameNotification:(NSNotification *)inNotification
{
    [self selectPreviousRow];
}

- (void)jumpToNextFrameNotification:(NSNotification *)inNotification
{
    [self selectNextRow];
}

- (void)jumpToLeftColumnNotification:(NSNotification *)inNotification
{
    
}

- (void)jumpToRightColumnNotification:(NSNotification *)inNotification
{
    
}

//- (void)changeColumnsUserInfo:(NSMutableDictionary*)user_info
//{
//    BOOL allow_update = YES;
//    NSNumber* num = [user_info objectForKey:kChangeColumnsCountKey];
//    NSInteger numberColumns = [num integerValue];
//    NSNumber* ind = [user_info objectForKey:kChangeColumnsIndexKey];
//    NSInteger indexColumn = [ind integerValue];
//    
//    if (numberColumns > kLimitsMaxXsheetColumnsPlus) {
//        allow_update = NO;
//    } else if (numberColumns > kLimitsMaxXsheetColumnsFree) {
//        allow_update = [FBUpgradeController checkUpgrade];
//    }
//    
//    if (allow_update) {
//        // TODO: moving in other function; other interface for columns
//        if (numberColumns > fNumUserColumns) {
//            [self addColumn:indexColumn];
//        } else {
//            [self deleteColumn:indexColumn];
//        }
//        
//        fNumUserColumns = numberColumns;
//        [self->fStorage setNumberOfColumns:numberColumns];
//        
//        [fTableView reloadData];
//
//        [self setupTableWidthConstraint];
//    } else {
//        [user_info setObject:@NO forKey:kChangeColumnsAllowedKey];
//    }
//}

#pragma mark - Media actions (Import / Export / e t c)

- (IBAction)showScenes:(id)inSender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowScenesNotification object:self];
}

- (IBAction)chooseImport:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification
                                                        object:self];
    _alertContoller = [UIAlertController alertControllerWithTitle:@"Choose import type"
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* sound = [UIAlertAction actionWithTitle:@"Audio"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {
        self->_impType = audio;
        [self importAudioWithPopoverBarButonItem:self->_chooseImportButton];
    }];
    UIAlertAction* images = [UIAlertAction actionWithTitle:@"Images"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
        self->_impType = image;
        [self importImageWithPopoverBarButonItem:self->_chooseImportButton];
    }];
    UIAlertAction* movies = [UIAlertAction actionWithTitle:@"Movies"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
        self->_impType = video;
        [self importVideoWithPopoverBarButonItem:self->_chooseImportButton];
    }];
    /*
    UIAlertAction *capture = [UIAlertAction actionWithTitle:@"Capture"
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
        [self.sceneController startImageCapture];
    }];
     */
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [_alertContoller addAction:sound];
    [_alertContoller addAction:images];
    [_alertContoller addAction:movies];
    /*
     [_alertContoller addAction:capture];
     */
    [_alertContoller addAction:cancel];
    [_alertContoller setModalPresentationStyle:UIModalPresentationPopover];
    _alertContoller.popoverPresentationController.barButtonItem = sender;
    [[self sceneController] presentViewController:_alertContoller
                                         animated:true
                                       completion:nil];
}

- (void)authorizeMediaPickerWithCompletion:(void(^)(void))completion
{
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus authorizationStatus = MPMediaLibrary.authorizationStatus;
        
        switch (authorizationStatus) {
            case MPMediaLibraryAuthorizationStatusAuthorized:
            {
                completion();
                break;
            }
            case MPMediaLibraryAuthorizationStatusNotDetermined:
            {
                // Not yet authorized - request it from the system
                [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus authorizationStatus)
                 {
                    if ( authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion();
                        });
                    } else {
                        NSLog(@"The Media Library was not authorized by the user");
                    }
                }];
                break;
            }
                
            case MPMediaLibraryAuthorizationStatusRestricted:
            case MPMediaLibraryAuthorizationStatusDenied:
            {
                // user has previously denied access. Ask again with our own alert that is similar to the system alert
                // then take them to the System Settings so they can turn it on for the app
                
                break;
            }
        }
    } else {
        // Fallback on earlier versions
    }
}

- (IBAction)showActions:(id)inSender {
    [self makeExport];
}

- (IBAction) importStill:(id)inSender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    fb_dispatch_seconds (0.5, ^{
        FBLandscapeImagePickerController* picker_controller = [[FBLandscapeImagePickerController alloc] init];
        picker_controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker_controller.delegate = self;
        [self.sceneController presentViewController:picker_controller animated:YES completion:NULL];
        UIPopoverPresentationController* popover_controller = [picker_controller popoverPresentationController];
        popover_controller.barButtonItem = self->_chooseImportButton;
    });
}

- (IBAction) takePicture:(id)inSender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"This iPad does not have a camera" message:@"You can import still images from the actions menu." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction: cancel];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    fb_dispatch_seconds (0.5, ^{
        FBLandscapeImagePickerController* picker_controller = [[FBLandscapeImagePickerController alloc] init];
        picker_controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker_controller.delegate = self;
        [self.sceneController presentViewController:picker_controller animated:YES completion:NULL];
        
        UIPopoverPresentationController* popover_controller = [picker_controller popoverPresentationController];
        popover_controller.barButtonItem = self->_chooseImportButton;
    });
}

- (void)importAudio {
    [self importAudioWithPopoverBarButonItem:nil];
}

- (void)importAudioWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    UIAlertControllerStyle style = barButtonItem ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
    if ([[self.sceneController document] soundData] != nil) {
        _alertContoller = [UIAlertController alertControllerWithTitle:@"Clear sound?"
                                                              message:nil
                                                       preferredStyle:style];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Yes"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            [self clearSound:nil];
        }];
        UIAlertAction *noButton = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [_alertContoller addAction:yesButton];
        [_alertContoller addAction:noButton];
        [_alertContoller setModalPresentationStyle:UIModalPresentationPopover];
        _alertContoller.popoverPresentationController.barButtonItem = barButtonItem;
        [[self sceneController] presentViewController:_alertContoller
                                             animated:YES
                                           completion:nil];
    } else {
        _alertContoller = [UIAlertController alertControllerWithTitle:@"Choose Source"
                                                              message:nil
                                                       preferredStyle:style];
        
        UIAlertAction *fromMusic = [UIAlertAction actionWithTitle:@"From Music"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            self.mediaController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
            [self.mediaController setAllowsPickingMultipleItems:NO];
            [self.mediaController setShowsCloudItems:NO];
            [self.mediaController setPrompt:@"Select Music"];
            self.mediaController.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self.mediaController setDelegate:self];
            fb_dispatch_seconds (0.5, ^{
                [self authorizeMediaPickerWithCompletion:^{
                    [self.sceneController presentViewController:self.mediaController
                                                       animated:YES
                                                     completion:nil];
                }];
            });
        }];
        UIAlertAction *fromFiles = [UIAlertAction actionWithTitle:@"From Files"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
            fb_dispatch_seconds(0.3, ^{
                self->_impType = audio;
                UIDocumentPickerViewController *pickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"]
                                                                                                                          inMode:UIDocumentPickerModeImport];
                pickerController.delegate = self;
                [self.sceneController presentViewController:pickerController
                                                   animated:YES
                                                 completion:nil];
            });
        }];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
        
        [_alertContoller addAction:fromMusic];
        [_alertContoller addAction:fromFiles];
        [_alertContoller addAction:cancel];
        [_alertContoller setModalPresentationStyle:UIModalPresentationPopover];
        _alertContoller.popoverPresentationController.barButtonItem = barButtonItem;
        [[self sceneController] presentViewController:_alertContoller
                                             animated:true
                                           completion:nil];
    }
}

- (void)importImage {
    [self importImageWithPopoverBarButonItem:nil];
}

- (void)importImageWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification
                                                        object:self];
    UIAlertControllerStyle style = barButtonItem ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
    _alertContoller = [UIAlertController
                       alertControllerWithTitle:@"Choose Source"
                       message:nil
                       preferredStyle:style];
    UIAlertAction* takePhoto = [UIAlertAction
                                actionWithTitle:@"From Camera"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
        [self takePicture:nil];
    }];
    UIAlertAction* fromPhotos = [UIAlertAction
                                 actionWithTitle:@"From Photos"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *action) {
        [self importStill:nil];
    }];
    UIAlertAction* fromFiles = [UIAlertAction
                                actionWithTitle:@"From Files"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
        UIDocumentPickerViewController *pickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"]
                                                                                                                  inMode:UIDocumentPickerModeImport];
        pickerController.delegate = self;
        [self.sceneController presentViewController:pickerController
                                           animated:YES
                                         completion:NULL];
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [_alertContoller addAction:takePhoto];
    [_alertContoller addAction:fromPhotos];
    [_alertContoller addAction:fromFiles];
    [_alertContoller addAction:cancel];
    [_alertContoller setModalPresentationStyle:UIModalPresentationPopover];
    _alertContoller.popoverPresentationController.barButtonItem = barButtonItem;
    [[self sceneController] presentViewController:_alertContoller
                                         animated:true
                                       completion:nil];
}

- (void)importVideo {
    [self importVideoWithPopoverBarButonItem:nil];
}

- (void)importVideoWithPopoverBarButonItem:(UIBarButtonItem *)barButtonItem {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification
                                                        object:self];
    UIAlertControllerStyle style = barButtonItem ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
    _alertContoller = [UIAlertController alertControllerWithTitle:@"Choose Source"
                                                          message:nil
                                                   preferredStyle:style];
    UIAlertAction *fromPhotos = [UIAlertAction actionWithTitle:@"From Photos"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
        UIImagePickerController *imagePicker = [UIImagePickerController new];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [imagePicker setMediaTypes:@[@"public.movie"]];
        [imagePicker setDelegate:self];
        fb_dispatch_seconds (0.5, ^{
            self->_impType = video;
            [self.sceneController presentViewController:imagePicker animated:YES completion:NULL];
        });
    }];
    UIAlertAction *fromFiles = [UIAlertAction actionWithTitle:@"From Files"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        fb_dispatch_seconds(0.3, (^{
            self->_impType = video;
            NSArray* types = @[
                (NSString*)kUTTypeVideo,
                (NSString*)kUTTypeMPEG,
                (NSString*)kUTTypeQuickTimeMovie,
                (NSString*)kUTTypeMPEG4,
                (NSString*)kUTTypeAppleProtectedMPEG4Video,
                (NSString*)kUTTypeAVIMovie
            ];
            UIDocumentPickerViewController *pickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types
                                                                                                                      inMode:UIDocumentPickerModeImport];
            pickerController.delegate = self;
            [self.sceneController presentViewController:pickerController
                                               animated:YES
                                             completion:NULL];
        }));
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [_alertContoller addAction:fromPhotos];
    [_alertContoller addAction:fromFiles];
    [_alertContoller addAction:cancel];
    [_alertContoller setModalPresentationStyle:UIModalPresentationPopover];
    _alertContoller.popoverPresentationController.barButtonItem = barButtonItem;
    [[self sceneController] presentViewController:_alertContoller
                                         animated:true
                                       completion:nil];
}

- (void)makeExport {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification
                                                        object:self];
    FBExportController *exportController = [FBExportController new];
    [exportController setXSheetController:self];
    [exportController setSceneController:self.sceneController];
    if ([Config floatingToolbars]) {
        [exportController view];
        CGPoint point = CGPointMake(_sceneController.playbackToolbar.bounds.size.width, 44.0);
        CGPoint location = [_sceneController.view convertPoint:point fromView:_sceneController.playbackToolbar];
        CGPoint offset = CGPointMake(_sceneController.view.bounds.size.width - location.x,
                                     _sceneController.view.bounds.size.height - location.y);
        [exportController setOffsetWithX:offset.x + 8.0f
                                       y:offset.y];
    }
    exportController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    exportController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    exportController.popoverPresentationController.delegate = [self sceneController];
    exportController.preferredContentSize = CGSizeMake(300.0, 365.0);
    UIPopoverPresentationController *popoverController = [exportController popoverPresentationController];
    [popoverController setDelegate:[self sceneController]];
    [self.sceneController presentViewController:exportController
                                       animated:YES
                                     completion:NULL];
}

- (IBAction) clearSound:(id)inSender
{
    [[self.sceneController document] setSoundData:nil];
    [[self.sceneController document] setSoundOffset:0.0];
    [self setupSoundWave];
    [self.sceneController configureScrubSoundPlayers];
}

#pragma mark - Adding rows

// Insert
- (IBAction)addRow:(id)inSender
{
    [self inserRowAt:_selectedItem.row offsetPosition:0];
}

// Added
- (IBAction)addRowBelowSelectedRow:(id)inSender
{
    [self inserRowAt:_selectedItem.row offsetPosition:1];
}

- (void)inserRowAt:(NSInteger)rowPosition offsetPosition:(NSInteger)offsetPosition
{
    if ([self checkXsheetLimits]) { return; }
    
    [_lightboxStack removeAll];
    [_previewCache removeAll];
    
    [self.drawingView saveChanges];
    [self.drawingView loadNewCelWithImages:[NSDictionary new]];
    
    [self deselectAllRows];
    
    [fTableView reloadData];
    
    [fStorage insertRowAfterRow:rowPosition + offsetPosition];
    [_lightboxStack shiftContentFromRow:rowPosition + offsetPosition byOffset:1];
    
    NSInteger currentlySelectedRow = rowPosition + (offsetPosition == 0 ? 1 : 0);
    
    self->_selectedItem.row = rowPosition + (offsetPosition == 0 ? 1 : 0);
    
    [CATransaction begin];
    [fTableView beginUpdates];
    
    [CATransaction setCompletionBlock: ^{
        // Reload row that should deselect
        /*
        if (rowPosition == currentlySelectedRow) {
            [self->fTableView reloadRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:(currentlySelectedRow) inSection:0]
            ] withRowAnimation:UITableViewRowAnimationNone];
        } else {
            [self->fTableView reloadRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:(currentlySelectedRow - 1) inSection:0]
            ] withRowAnimation:UITableViewRowAnimationNone];
        }
         */
        [self select];
        
        if (currentlySelectedRow >= 1) {
            NSLog(@"Reloading %i", (int)(currentlySelectedRow - 1));
            [self->fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(currentlySelectedRow - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
        }
        
        NSLog(@"Reloading %i", (int)(self->_selectedItem.row - 1));
        [self->fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(self->_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
    }];
    // Insert new row
    [fTableView insertRowsAtIndexPaths:@[
        [NSIndexPath indexPathForRow:(rowPosition + offsetPosition - 1) inSection:0]
    ] withRowAnimation:UITableViewRowAnimationNone];
    
    [fTableView endUpdates];
    [CATransaction commit];
        
    [self updateRowNumbersStartingFromRow:(rowPosition + offsetPosition)];
    [self revealCurrentRow];
    [self selectRow:rowPosition + offsetPosition item:_selectedItem.item];
}

- (void)select
{
    if (_selectedItem.mode == Item) {
        /// Enable drawing when a SINGLE cell is selected
        [[[self sceneController] drawingView] setIsTouchEnabled:YES];
        /// Update lightbox
        [self updateLightboxStackAtCollectionRow:_selectedItem.row item:_selectedItem.item];
        
        [self updateRollButton];
        fRowIsSelectedForAction = NO;
        
        UIImage* previous_img = [self buildLightboxImageAtPreviousRow:_selectedItem.row column:_selectedItem.item];
        FBCell* tapped_cel = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
        [self notifyLoadCel:tapped_cel previousImage:previous_img];
    } else {
        /// Disable drawing when ALL row is selected
        [[[self sceneController] drawingView] setIsTouchEnabled:NO];
        
        fRowIsSelectedForAction = YES;
        
        [_sceneController showCompositedIndex:_selectedItem.row - 1];
    }
}

- (void) deleteRow:(id)inSender
{
    BOOL isCellEmpty = true;
    for (NSInteger i = 1; i <= [self->fStorage numberOfColumns] && isCellEmpty; i++)
    {
        FBCell* cell = [fStorage cellAtRow:_selectedItem.row column:i];
        isCellEmpty &= ((cell == nil) || ([cell isEmpty]));
    }

    if (isCellEmpty) {
        [self deleteSelectedRow];
        return;
    }

    UIAlertController*alert = [UIAlertController alertControllerWithTitle:nil message:@"Do you really want to delete this frame?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction*delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteSelectedRow];
    }];
    UIAlertAction*cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:delete];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)deleteSelectedRow
{
    if ([self->fStorage numberOfRows] == 1) {
        /// clear it instead if only 1 row left
        for (NSInteger i = 1; i <= [self->fStorage numberOfColumns]; i++)
        {
            [self->fStorage storeCell:[FBCell emptyCel] atRow:self->_selectedItem.row column:i];
            [self clearAtRow:self->_selectedItem.row column:i];
        }
        [[[self sceneController] drawingView] setIsTouchEnabled:YES];
        [self-> fTableView reloadData];
    } else {
        
        [_lightboxStack removeAll];
        [_previewCache removeAll];

        [fTableView reloadData];
        
        // Delete row from datadase, lightbox and clear cache
        [self->fStorage deleteWithRow:self->_selectedItem.row];
        
        if (self->_selectedItem.row > [self->fStorage numberOfRows]) {
            self->_selectedItem.row--;
        }
        
        if (self->fRowIsSelectedForAction) {
            self->fRowIsSelectedForAction = NO;
        }
        
        
        [CATransaction begin];
        [fTableView beginUpdates];
        
        [CATransaction setCompletionBlock: ^{
            // Reload row that should become selected
            [self select];
            
            [self->fTableView reloadRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:(self->_selectedItem.row - 1) inSection:0]
            ] withRowAnimation:UITableViewRowAnimationNone];
        }];
        
        // Delete row
        [fTableView deleteRowsAtIndexPaths:@[
            [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0]
        ] withRowAnimation:UITableViewRowAnimationTop];
        
        [fTableView endUpdates];
        [CATransaction commit];
                        
        [self updateRowNumbersStartingFromRow:_selectedItem.row];
        [self revealCurrentRow];
    }
}

- (IBAction) rollPrevious:(id)inSender
{
    [self.drawingView saveChanges];
    
    NSInteger current_row = _selectedItem.row;
    NSInteger found_row = 0;
    
    FBCell* rolled_cel = [fStorage previousCellAtRow:_selectedItem.row column:_selectedItem.item resultingRow:&found_row];
    if (rolled_cel) {
        self.isRollPrevious = YES;

        if (_selectedItem.mode == Row) {
            [self selectEntireRow:found_row];
        } else {
            [self selectRow:found_row item:_selectedItem.item];
        }

        [FBUtilities performBlock:^{

            if (self->_selectedItem.mode == Row) {
                [self selectEntireRow:current_row];
            } else {
                [self selectRow:current_row item:self->_selectedItem.item];
            }
            
            self.isRollPrevious = NO;
        } afterDelay:0.1];
    }
    
    [FBHelpController showHelpPane:kHelpPaneFlip];
}

- (void) cut:(id)inSender
{
    _isPaste = TRUE;
    FBCell* cell = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
    FBCellOriginal* cellOriginal = [fStorage getCellOriginalAtRow:_selectedItem.row column:_selectedItem.item];
    
    [fStorage.database cutCell:cell cellOriginal:cellOriginal row:_selectedItem.row column:_selectedItem.item];
    [self clear:inSender];
}

- (void) copy:(id)inSender
{
    _isPaste = TRUE;
    FBCell* cell = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
    FBCellOriginal* cellOriginal = [fStorage getCellOriginalAtRow:_selectedItem.row column:_selectedItem.item];
    
    [fStorage.database copyCell:cell cellOriginal:cellOriginal row:_selectedItem.row column:_selectedItem.item];
}

- (void) paste:(id)inSender
{
    [fStorage.database pasteCellAtRow:_selectedItem.row column:_selectedItem.item];
    
    [_previewCache removePreviewImageWithRow:_selectedItem.row item:_selectedItem.item];
    
    FBCell* cell = [fStorage reloadCellAtRow:_selectedItem.row column:_selectedItem.item];
    cell.isLoaded = YES;
    [fStorage reloadCellOriginalAtRow:_selectedItem.row column:_selectedItem.item];
    [fStorage compositeUpdateCacheForRow:_selectedItem.row column:_selectedItem.item];
    
    [_lightboxStack push:cell withRow:_selectedItem.row column:_selectedItem.item];
    UIImage* previous_img = [self buildLightboxImageAtPreviousRow:_selectedItem.row column:_selectedItem.item];
    
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info rf_setObject:cell.pencilImage forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:cell.paintImage forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:cell.structureImage forKey:kUpdateCurrentCellStructureKey];
    [info rf_setObject:previous_img forKey:kUpdateCurrentLightboxImageKey];
    [info rf_setObject:@NO forKey:kUpdateIsCurrentlyPausedKey];
    
    NSLog(@"🔥 Save pasted images (silent?)");
    [_drawingView loadNewCelWithImages:info];
    
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) pasteWithCapturedPencilImage:(UIImage *)inImage
{
    CGSize scene_size = [self.sceneController.document resolutionSize];
    UIImage* new_img = //[UIImage rf_imageByResizingImage:inImage size:scene_size ratioMode:FBImageRatioModeAspectFill];
    [UIImage rf_imageByResizingImageAndApplyingPencilEffect:inImage size:scene_size ratioMode:FBImageRatioModeAspectFill threshold:0.3];
    
//    [UIImagePNGRepresentation(new_img) writeToURL:[[NSURL documentsFolder] URLByAppendingPathComponent:@"preview.png"] atomically:YES];
    
    [self pasteWithPencilImage:nil structureImage:nil paintImage:[[FBImage alloc] initWithPremultipliedImage:new_img]];
}

- (void) pasteWithImage:(UIImage *)inImage
{
    CGSize scene_size = [self.sceneController.document resolutionSize];
    UIImage* new_img = [UIImage rf_imageByResizingImage:inImage size:scene_size ratioMode:FBImageRatioModeAspectFill];
    
//    [UIImagePNGRepresentation(new_img) writeToURL:[[NSURL documentsFolder] URLByAppendingPathComponent:@"preview.png"] atomically:YES];
    
    [self pasteWithPencilImage:nil structureImage:nil paintImage:[[FBImage alloc] initWithPremultipliedImage:new_img]];
}

- (void)importFrame:(UIImage *)frame row:(int)row isPencil:(BOOL)isPencil ratioMode:(FBImageRatioMode)ratioMode
{
    UIImage* resizedImage = [UIImage rf_imageByResizingImage:frame size:self.sceneController.document.resolutionSize ratioMode:ratioMode];
    
    NSInteger currRows = [fStorage numberOfRows];
    NSInteger diff = (row - currRows);
    if (diff > 0) {
        for (int i = 0; i < diff; i++) {
            [fStorage insertRowAfterRow:row + i];
        }
    }
    _selectedItem.row = row;
    
    FBCell* oldCel = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
    if (!oldCel) {
        oldCel = [FBCell emptyCel];
    }
    
    if (isPencil) {
        oldCel.pencilImage = [[FBImage alloc] initWithPremultipliedImage:[FBPencil pencilImageFrom:resizedImage]];
        oldCel.structureImage = [[FBImage alloc] initWithPremultipliedImage:[FBStructure structureImageFrom:resizedImage]];
    } else {
        oldCel.paintImage = [[FBImage alloc] initWithPremultipliedImage:resizedImage];
    }
    
    oldCel.isLoaded = YES;
    [fStorage storeCell:oldCel atRow:_selectedItem.row column:_selectedItem.item];
}

- (void) pasteWithPencilImage:(FBImage *)inPencilImage structureImage:(FBImage*)inStructureImage paintImage:(FBImage *)inPaintImage
{
    if (_selectedItem.row == 0) {
        return;
    }
    
    FBCell* cel = [fStorage cellAtRow:_selectedItem.row column:_selectedItem.item];
    if (!cel) {
        cel = [FBCell emptyCel];
    }
    if (inPencilImage) {
        cel.pencilImage = inPencilImage;
    }
    if (inStructureImage) {
        cel.structureImage = inStructureImage;
    }
    if (inPaintImage) {
        cel.paintImage = inPaintImage;
    }
    cel.isLoaded = YES;
    
    [_previewCache removePreviewImageWithRow:_selectedItem.row item:_selectedItem.item];
    
    [fStorage storeCell:cel atRow:_selectedItem.row column:_selectedItem.item];
    
    [_lightboxStack push:cel withRow:_selectedItem.row column:_selectedItem.item];
    UIImage* previous_img = [self buildLightboxImageAtPreviousRow:_selectedItem.row column:_selectedItem.item];
    
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info rf_setObject:cel.pencilImage forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:cel.paintImage forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:cel.structureImage forKey:kUpdateCurrentCellStructureKey];
    [info rf_setObject:previous_img forKey:kUpdateCurrentLightboxImageKey];
    [info rf_setObject:@NO forKey:kUpdateIsCurrentlyPausedKey];
    
    NSLog(@"🔥 Save pasted images (silent?)");
    [_drawingView loadNewCelWithImages:info];
    
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) clearAtRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    if (inRow == 0) {
        return;
    }
    
    [_previewCache removePreviewImageWithRow:_selectedItem.row item:_selectedItem.item];
    [_lightboxStack deleteCellWithRow:_selectedItem.row column:_selectedItem.item];
    [_drawingView clearCurrentCellLeavingLightbox:[self buildLightboxImageAtPreviousRow:_selectedItem.row column:_selectedItem.item]];
    NSLog(@"🔥 Clear images at row (silent?)");
}

- (void) clear:(id)inSender
{
    [fStorage storeCell:[FBCell emptyCel] atRow:_selectedItem.row column:_selectedItem.item];
    FBCell* cell = [fStorage reloadCellAtRow:_selectedItem.row column:_selectedItem.item];
    [self clearAtRow:_selectedItem.row column:_selectedItem.item];
    [fStorage compositeUpdateCacheForRow:_selectedItem.row column:_selectedItem.item];
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction) resetBlank:(id)sender
{
    [fStorage storeCell:[FBCell clearCel] atRow:_selectedItem.row column:_selectedItem.item];
    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(_selectedItem.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction) showTiming:(id)inSender
{
    NSInteger count = [fStorage getHoldForRow:_selectedItem.row column:_selectedItem.item];
    
    FBTimingController* timing_controller = [[FBTimingController alloc] initWithFrameCount:count];
    [timing_controller setDelegate:self];
    [self presentViewController:timing_controller animated:YES completion:NULL];
    
    UIPopoverPresentationController* popover_controller = [timing_controller popoverPresentationController];
    popover_controller.sourceView = fTableView;
    popover_controller.sourceRect = CGRectMake (0, (_selectedItem.row * kDefaultGridCellHeight) - kDefaultGridHeaderHeight, 200, kDefaultGridCellHeight);
}

- (BOOL)checkXsheetLimits {
    BOOL exceeded = [fStorage numberOfRows] >= [FeatureManager shared].maxFrames;
    
    if (exceeded) { [UIAlertController showBlockedAlertControllerFor:self.sceneController feature:@"Adding more frames" level:@""]; }
//        if (self.presentedViewController) {
//            [self.presentedViewController dismissViewControllerAnimated:YES
//                                                              completion:^{
//                [UIAlertController showBlockedAlertControllerFor:self.sceneController];
//            }];
//        } else {
//            [UIAlertController showBlockedAlertControllerFor:self.sceneController];
//        }
//    }
    return exceeded;
}

#pragma mark - Table Updates Without Reloading

- (void)updateRowNumbersStartingFromRow:(NSInteger)fromRow {
    for (NSIndexPath* indexPath in [fTableView indexPathsForVisibleRows]) {
        NSUInteger row = indexPath.row + 1;
        if (fromRow <= row) {
            XSheetTableCell *cell = [fTableView cellForRowAtIndexPath:indexPath];
            cell.numberLabel.text = [NSString stringWithFormat:@"%ld", row];
        }
    }
}

- (void)deselectAllRows {
    for (XSheetTableCell *cell in fTableView.visibleCells) {
        [cell deselectAll];
    }
}

#pragma mark -

- (NSInteger) defaultAddButtonHeight
{
    return 44;
}

- (NSInteger) defaultCellWidth
{
    return 200;
}


- (void) imagePickerController:(UIImagePickerController *)inPicker didFinishPickingMediaWithInfo:(NSDictionary *)inInfo
{
    [self.sceneController dismissViewControllerAnimated:YES completion:^{
        switch (self->_impType) {
            case video: {
                NSURL* url = [inInfo objectForKey:UIImagePickerControllerMediaURL];
                [self getFramesFromURL:url];
            }
            case image: {
                UIImage* img = [inInfo objectForKey:UIImagePickerControllerOriginalImage];
                if (img) {
                    img = [img uuRemoveOrientation];
                    [self pasteWithImage:img];
                }
            }
            default:
                break;
        }
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)inPicker
{
    [self.sceneController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    NSURL* url = urls.firstObject;
    switch (_impType) {
        case audio: {
            NSData* data = [NSData dataWithContentsOfURL:url];
            [[self.sceneController document] setSoundData:data];
            [self setupSoundWave];
            [self.sceneController configureScrubSoundPlayers];
            break;
        }
        case image:
            [self imageFromUrl:url];
            break;
        case video:
            [self getFramesFromURL:url];
            break;
    }
}

- (void)getFramesFromURL:(NSURL *)url asPencil:(BOOL)isPencil
{
    ProgressBarViewController*progressController=[[ProgressBarViewController alloc] initWithNibName:@"ProgressBarViewController" bundle:nil];
    [progressController setModalPresentationStyle : UIModalPresentationFormSheet];
    
    __weak FBXsheetController *weakSelf = self;
    VideoImporterHelper *helper = [[VideoImporterHelper alloc] init:url fps:[self.sceneController.document fps]];
    [helper extractAudioWithCompletion:^(NSData * _Nullable audioFileData) {
        [[self.sceneController document] setSoundData:audioFileData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupSoundWave];
            [self.sceneController configureScrubSoundPlayers];
        });
    }];
    
    NSInteger expectedFramesCount = [helper expectedFramesCount];
    NSInteger currentCountOfFrames = [fStorage numberOfRows];
    NSInteger difference = expectedFramesCount - currentCountOfFrames;
    
    void (^importFrames)(NSInteger count, FBImageRatioMode ratioMode) = ^void(NSInteger count, FBImageRatioMode ratioMode) {
        [self.sceneController presentViewController:progressController animated:YES completion:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [helper getFramesWithLimit:count progressHandler:^(UIImage * _Nonnull image, NSInteger processed, NSInteger total) {
                NSLog(@"%li / %li", (long)processed, (long)total);
                
                [self importFrame:image row:(int)processed isPencil:isPencil ratioMode:ratioMode];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = (float)processed / (float)total;
                    [progressController setProgressWithProgress:progress];
                    
                    if (processed == total) {
                        [self->_previewCache removeAll];
                        [self->fTableView reloadData];
//                        [self didTapOnFrame:[NSIndexPath indexPathForRow:0 inSection:0] item:1];
                        [progressController dismissViewControllerAnimated:YES completion:nil];
                    }
                });
            }];
        });
    };
    
    if (difference > 0) {
        UIAlertController *showMsgAlertController = [UIAlertController alertControllerWithTitle: @"Do you want to expand frame count to fit video?" message: nil preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle: @"Yes"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Start import 'expectedFramesCount' frames
            importFrames(expectedFramesCount, FBImageRatioModeAspectFit);
        }];
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // Start import (only 'currentCountOfFrames')
            importFrames(currentCountOfFrames, FBImageRatioModeAspectFit);
        }];
        [showMsgAlertController addAction: noAction];
        [showMsgAlertController addAction: okAction];
        [[weakSelf sceneController] presentViewController:showMsgAlertController animated:true completion:nil];
    } else {
        // Start import 'expectedFramesCount' frames
        importFrames(expectedFramesCount, FBImageRatioModeAspectFit);
    }
}

- (void)getFramesFromURL:(NSURL *)url
{
//    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Import image as ..." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    [alert addAction:[UIAlertAction actionWithTitle:@"Pencil Lines" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self getFramesFromURL:url asPencil:YES];
//    }]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"Paint" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self getFramesFromURL:url asPencil:NO];
//    }]];
    
//    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
//    popPresenter.sourceView = _sceneController.view;
//    popPresenter.sourceRect = _sceneController.view.bounds;
//    popPresenter.permittedArrowDirections = 0;
//
//    [self.sceneController presentViewController:alert animated:YES completion:nil];
}

- (void) imageFromUrl:(NSURL *)url
{
    NSData* data = [NSData dataWithContentsOfURL:url];
    UIImage* img = [[UIImage alloc] initWithData:data];
    if (img) {
        img = [img uuRemoveOrientation];
        CGSize scene_size = [self.sceneController.document resolutionSize];
        img = [img imageByScalingToSize:scene_size];
        [self pasteWithImage:img];
    }
}

- (void) documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
}

#pragma mark - MPMediaPickerController Delegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    MPMediaItem* item = mediaItemCollection.representativeItem;
    NSURL* library_url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    switch (_impType) {
        case audio: {
            AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:library_url options:nil];
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName: AVAssetExportPresetAppleM4A];
            exporter.outputFileType = AVFileTypeAppleM4A;
            
            NSString *exportFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/exported.mp4"];
            exporter.outputURL = [NSURL fileURLWithPath:exportFile];

            // do the export
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                NSData *data = [NSData dataWithContentsOfFile:exportFile];
                [[self.sceneController document] setSoundData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupSoundWave];
                    [self.sceneController configureScrubSoundPlayers];
                });
            }];
            
            break;
        }
        case video:
            break;
        default:
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sceneController dismissViewControllerAnimated:YES completion:^{
            self.mediaController = nil;
        }];
    });
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *)inMediaPicker
{
    [self.sceneController dismissViewControllerAnimated:YES completion:^{
        self.mediaController = nil;
    }];
}

#pragma mark -

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (BOOL) canPerformAction:(SEL)inAction withSender:(id)inSender
{
    if (inAction == @selector(addRow:)) {
        return YES;
    } else if (inAction == @selector(addRowBelowSelectedRow:)) {
        return YES;
    } else if (inAction == @selector(deleteRow:)) {
        return YES;
    } else if (inAction == @selector(cut:)) {
        if (fRowIsSelectedForAction) {
            return NO;
        } else {
            return (![fStorage isHoldAtRow:_selectedItem.row column:_selectedItem.item] || [self.drawingView hasChanges]);
        }
    } else if (inAction == @selector(copy:)) {
        if (fRowIsSelectedForAction) {
            return NO;
        } else {
            return (![fStorage isHoldAtRow:_selectedItem.row column:_selectedItem.item] || [self.drawingView hasChanges]);
        }
    } else if (inAction == @selector(paste:)) {
        if (fRowIsSelectedForAction) {
            return NO;
        } else {
            return _isPaste;
//            NSArray* pdTypes = [[UIPasteboard generalPasteboard] pasteboardTypes];
//            return [pdTypes containsObject:@"public.png"];
        }
    } else if (inAction == @selector(showTiming:)) {
        return YES;
    } else if (inAction == @selector(resetBlank:)) {
        return YES;
    } else {
        return NO;
    }
}

- (UIImage *)buildLightboxImageAtPreviousRow:(NSInteger)inRow column:(NSInteger)inColumn
{
    NSMutableArray* previous_and_neighbor_images = [[NSMutableArray alloc] init];
    
    NSLog (@"🌈 lightbox at row: %ld, column: %ld", (long)inRow, (long)inColumn);
    
    float min = [[NSUserDefaults standardUserDefaults] floatForKey:kMinimumOpacityRange];
    float max = [[NSUserDefaults standardUserDefaults] floatForKey:kMaximumOpacityRange];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:kMultilineVanishingPoint];
    if (max == 0) max = 1.0;
    
    if ([FBLightboxController shouldDisplayBackground]) {
        NSLog(@"Calculating background");
        NSInteger lightboxDepth = [FBLightboxController previousFramesCount];
        float delta = 1.0 / lightboxDepth;
        float new_alpha = 1.0;
        
        /// background cells
        if (_selectedItem.item == 1) {
            for (FBCell* previous_cel in [self.lightboxStack allBackgroundCelsSkipping:inRow]) {
                if (previous_cel && previous_cel.paintImage) {
                    [previous_and_neighbor_images addObject:previous_cel.paintImage.previewUiImage];
                    [previous_cel.paintImage fb_setAssociatedAlpha:new_alpha];
                }
                if (previous_cel && previous_cel.pencilImage) {
                    [previous_and_neighbor_images addObject:previous_cel.pencilImage.previewUiImage];
                    [previous_cel.pencilImage fb_setAssociatedAlpha:new_alpha];
                }
                new_alpha -= delta;
            }
        } else {
            for (FBCell* previous_cel in [self.lightboxStack singleBackgroundCelsSkipping:(inRow)]) {
                if (previous_cel && previous_cel.paintImage) {
                    [previous_and_neighbor_images addObject:previous_cel.paintImage.previewUiImage];
                    [previous_cel.paintImage fb_setAssociatedAlpha:new_alpha];
                }
                if (previous_cel && previous_cel.pencilImage) {
                    [previous_and_neighbor_images addObject:previous_cel.pencilImage.previewUiImage];
                    [previous_cel.pencilImage fb_setAssociatedAlpha:new_alpha];
                }
                new_alpha -= delta;
            }
        }
    
        new_alpha = max;
        /// Opacity step
        delta = (max - min) / [FBLightboxController previousFramesCount];
        
        for (FBCell* previous_cel in [self.lightboxStack allForegroundCelsSkipping:inRow column:_selectedItem.item]) {
            if (previous_cel && previous_cel.paintImage) {
                [previous_and_neighbor_images addObject:previous_cel.paintImage.previewUiImage];
                [previous_cel.paintImage fb_setAssociatedAlpha:new_alpha];
            }
            if (previous_cel && previous_cel.pencilImage) {
                [previous_and_neighbor_images addObject:previous_cel.pencilImage.previewUiImage];
                [previous_cel.pencilImage fb_setAssociatedAlpha:new_alpha];
            }
            new_alpha -= delta;
        }
        
        UIImage* previous_img = nil;
        
        if ([previous_and_neighbor_images count] > 0) {
            previous_img = [UIImage rf_imageByCompositingImages:previous_and_neighbor_images backgroundColor:nil];
        }
        NSLog(@"Onion Image Founded Count : %lu",(unsigned long)previous_and_neighbor_images.count);
        return previous_img;
    } else {
        float new_alpha = max;
        /// Opacity step
        float delta = (max - min) / [FBLightboxController previousFramesCount];
        
        for (FBCell* previous_cel in [self.lightboxStack allMixedCelsSkipping:inRow column:_selectedItem.item]) {
            if (previous_cel && previous_cel.paintImage) {
                [previous_and_neighbor_images addObject:previous_cel.paintImage.previewUiImage];
                [previous_cel.paintImage fb_setAssociatedAlpha:new_alpha];
            }
            if (previous_cel && previous_cel.pencilImage) {
                [previous_and_neighbor_images addObject:previous_cel.pencilImage.previewUiImage];
                [previous_cel.pencilImage fb_setAssociatedAlpha:new_alpha];
            }
            new_alpha -= delta;
        }
        
        UIImage* previous_img = nil;
        
        if ([previous_and_neighbor_images count] > 0) {
            previous_img = [UIImage rf_imageByCompositingImages:previous_and_neighbor_images backgroundColor:nil];
        }
        NSLog(@"Onion Image Founded Count : %lu",(unsigned long)previous_and_neighbor_images.count);
        return previous_img;
    }
}

- (FBStackInfo*)lastLightboxInfo
{
    if ([FBPrefs boolFor:kLightboxEnabledPrefKey]) {
        NSInteger lightboxCount = [NSUserDefaults.standardUserDefaults integerForKey:kLightboxPreviousFramesPrefKey];
        NSArray* mixedCells = self.lightboxStack.mixedCells;
        FBStackInfo* info = [mixedCells subarrayWithRange:NSMakeRange(0, MIN([mixedCells count], lightboxCount + 1))].lastObject;
        return info;
    } else {
        return nil;
    }
}

- (void) receiveUpdateLightboxNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:kUpdateLightbox]) {
        if (_selectedItem.item == 2) {
            UIImage* previous_img = [self buildLightboxImageAtPreviousRow:_selectedItem.row column:2];
            
            [self.drawingView updateLightboxWithImage:previous_img];
        }
    }
}

- (void)selectEntireRow:(NSInteger)inRow
{
    [self selectEntireRow:inRow ignoreDisplaying:NO];
}

- (void)selectEntireRow:(NSInteger)inRow ignoreDisplaying:(BOOL)ignoreDisplaying
{
    /// Disable drawing when ALL row is selected
    [[[self sceneController] drawingView] setIsTouchEnabled:NO];
    
    fRowIsSelectedForAction = YES;

    [self pauseRow:inRow];
      
    [self.sceneController updatePause];
}

#pragma mark - Menus

- (void)showRowMenuAtRow:(NSInteger)inRow
{
    [self becomeFirstResponder];
    XSheetTableCell* cell = (XSheetTableCell *)[fTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:inRow-1 inSection:0]];

    UIMenuController* menu = [UIMenuController sharedMenuController];
    [menu setArrowDirection:UIMenuControllerArrowLeft];
    
//    UIMenuItem* insert_item = [[UIMenuItem alloc] initWithTitle:@"Insert" action:@selector(addRow:)];
    UIMenuItem* delete_item = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteRow:)];
    UIMenuItem* add_row = [[UIMenuItem alloc] initWithTitle:@"Add" action:@selector(addRowBelowSelectedRow:)];
    
    [menu setMenuItems:@[ /*insert_item,*/ delete_item, add_row ]];

    if (@available(iOS 13.0, *)) {
        [menu showMenuFromView:cell.numberLabel rect:cell.numberLabel.bounds];
    } else {
        [menu setTargetRect:cell.numberLabel.bounds inView:cell.numberLabel];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (void)showCelMenuForRow:(NSInteger)row item:(NSInteger)item
{
    [self becomeFirstResponder];
    XSheetTableCell* cell = (XSheetTableCell *)[fTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row-1 inSection:0]];

    UIMenuController* menu = [UIMenuController sharedMenuController];
    CGFloat contentWidth = fTableView.frame.size.width - kDefaultGridRowNumberWidth;
    NSInteger lockedLevelsCount = 0;
    for (int i = 0; i < item; i++) {
        BOOL isHidden = [_sceneController.document.database isLevelHiddenAtIndex:i];
        if (isHidden) {
            lockedLevelsCount += 1;
        }
    }
    CGFloat width = contentWidth - (item - lockedLevelsCount)*(kDefaultGridCellWidth) + (kDefaultGridCellWidth/2);
    CGRect r = CGRectMake (width, kDefaultGridCellHeight/2, kDefaultGridCellWidth, kDefaultGridCellHeight);
    [menu setArrowDirection:UIMenuControllerArrowDefault];
    [menu setTargetRect:r inView:cell];
    
    UIMenuItem* timing_item = [[UIMenuItem alloc] initWithTitle:@"Timing" action:@selector(showTiming:)];
    UIMenuItem* blank_item = [[UIMenuItem alloc] initWithTitle:@"Stop Hold" action:@selector(resetBlank:)];
    NSArray* items;
    FBCell* tapped_cel = [fStorage cellAtRow:row column:item];
    if ([tapped_cel isEmpty]) {
        items = @[ blank_item ];
    } else {
        items = @[ timing_item ];
    }
    [menu setMenuItems:items];
    [menu setMenuVisible:YES animated:YES];
}

#pragma mark - Lightbox

- (void)updateLightboxStackAtCollectionRow:(NSInteger)inRow item:(NSInteger)item
{
    FBCell* neighbour_cel = [fStorage cellAtRow:inRow column:item]; /// Foreground for selected row
    [self.lightboxStack push:neighbour_cel withRow:inRow column: item]; /// Add current foreground to lightbox STACK
    
    /// Go from current row up to the first row
    for (long i = _selectedItem.row ; i > 0; i--) {
        /// Take every background
        FBCell* backgroundCell = [fStorage cellAtRow:i column:1];
        /// If background cell has someting - add it to the STACK
        if (![backgroundCell isEmpty]) {
            [self.lightboxStack pushBackgroundCell:backgroundCell withRow:i column:1];
            return;
        }
    }
}

- (void) notifyLoadCel:(FBCell *)inCel previousImage:(UIImage *)inPreviousImage
{
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info rf_setObject:inCel.pencilImage forKey:kUpdateCurrentCellPencilKey];
    [info rf_setObject:inCel.paintImage forKey:kUpdateCurrentCellPaintKey];
    [info rf_setObject:inCel.structureImage forKey:kUpdateCurrentCellStructureKey];
    [info rf_setObject:inCel.backgroundImage forKey:kUpdateCurrentCellBackgroundKey];
    [info rf_setObject:inPreviousImage forKey:kUpdateCurrentLightboxImageKey];
    
    [self.drawingView loadNewCelWithImages:info];
    NSLog(@"💫 Loaded new cell with images %@", info);
}

#pragma mark - XSheetTableCellDelegate

- (void)xSheetTableViewCellDidTap:(XSheetTableCell *)xSheetTableViewCell {
    NSIndexPath *indexPath = [fTableView indexPathForCell:xSheetTableViewCell];
    NSInteger row = indexPath.row + 1;
    if ([_sceneController pasteView]) {
        [[_sceneController pasteView] paste];
    }
    if ([_sceneController isPlaying]) {
        [self selectEntireRow:row ignoreDisplaying:YES];
    } else {
        [_drawingView saveChanges];
        [self selectEntireRow:row];
    }
    [_sceneController updateSliderForRow:row];
    [_sceneController refreshPuck];
    if (_tappedRow == row) {
        // Empty.
    }
    _tappedRow = row;
    _tappedItem = -1;
}

- (void)xSheetTableViewCell:(XSheetTableCell *)xSheetTableViewCell didTapOnItem:(NSInteger)index {
    NSIndexPath *indexPath = [fTableView indexPathForCell:xSheetTableViewCell];
    NSInteger row = indexPath.row + 1;
    if ([_sceneController pasteView]) {
        [[_sceneController pasteView] setIsMoved:YES];
    }
    if ((_tappedRow == row) && (_tappedItem == index)){
        [_drawingView saveChangesSilently];
        [self showCelMenuForRow:indexPath.row + 1 item:index];
    }
    if ([_sceneController isPlaying]) {
        [self selectRow:row item:index ignoreDisplaying:YES];
    } else {
        [_sceneController switchToDrawingState];
        [_drawingView saveChanges];
        [self selectRow:row item:index];
    }
    [_sceneController updateSliderForRow:_selectedItem.row];
    [_sceneController refreshPuck];
}

#pragma mark -

- (void)didPauseOnRow:(NSInteger)row
{
    _selectedItem.row = row + 1;
    _selectedItem.item = -1;
    _selectedItem.mode = Row;
    [fTableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.fTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self selectEntireRow:(row + 1)];
    });
}

#pragma mark - Timing Controller Delegate

- (void)timingController:(FBTimingController *)timingController didChangeFrameHoldCountTo:(NSInteger)holdCount
{
    NSInteger currentHold = [fStorage getHoldForRow:_selectedItem.row column:_selectedItem.item];
    [fStorage setHoldForRow:_selectedItem.row column:_selectedItem.item toValue:holdCount];
    
    NSInteger diff = holdCount - currentHold;
    [_lightboxStack shiftContentFromRow:_selectedItem.row byOffset:diff];
    
    [_previewCache removeAll];
    [fTableView reloadData];
}

#pragma mark - UITableView Delegate & DataSource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    XSheetHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kXSheetHeaderView];
    UIView* backgroundView = [[UIView alloc] initWithFrame:view.bounds];
    backgroundView.backgroundColor = [[UIColor alloc] initWithRed:0.667 green:0.667 blue:0.667 alpha:1.0];
    view.backgroundView = backgroundView;
    [view setDelegate:self];
    
    NSMutableArray<NSString*>* levelNames = [NSMutableArray new];
    NSMutableArray<NSNumber*>* isHiddenMap = [NSMutableArray new];
    
    for (int i = 0; i < fNumUserColumns; i++)
    {
        NSString* name = [_sceneController.document.database levelNameAtIndex:i];
        if (!name) {
            name = @"";
        }
        [levelNames addObject:name];
        //
        BOOL isHidden = [_sceneController.document.database isLevelHiddenAtIndex:i];
        [isHiddenMap addObject:[NSNumber numberWithBool:isHidden]];
    }
    
    [view setup:fNumUserColumns levelNames:levelNames isHiddenMap:isHiddenMap];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [fStorage numberOfRows];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XSheetTableCell* cell = [tableView dequeueReusableCellWithIdentifier:kXsheetCellIdentifier forIndexPath:indexPath];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSMutableArray *cels = [[NSMutableArray alloc] init];
        for (int i = (int)self->fNumUserColumns; i > 0; i--) {
            FBImage *preview = [weakSelf.previewCache getPreviewImageWithRow:indexPath.row + 1 item:i];
            if (preview) {
                // Preview available
                FBCell* blank = [FBCell emptyCel];
                [blank setPencilImage:preview];
                [cels addObject:blank];
            } else {
                // No preview - reuest cell from storage
                FBCell* cel = [self->fStorage cellAtRow:indexPath.row + 1 column:i];
                if (cel && ![cel isBackground]) {
                    [cels addObject:cel];
                } else {
                    [cels addObject:[FBCell emptyCel]];
                }
            }
        }
        
        NSMutableArray<NSNumber *>* isLockedMap = [NSMutableArray new];
        NSMutableArray<NSNumber *>* isHiddenMap = [NSMutableArray new];
        
        for (int i = (int)self->fNumUserColumns - 1; i >= 0; i--) {
            BOOL isLocked = [weakSelf.sceneController.document.database isLevelLockedAtIndex:i];
            BOOL isHidden = [weakSelf.sceneController.document.database isLevelHiddenAtIndex:i];
            [isLockedMap addObject:[NSNumber numberWithBool:isLocked]];
            [isHiddenMap addObject:[NSNumber numberWithBool:isHidden]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [cell configureWithCells:cels
                         isLockedMap:isLockedMap
                         isHiddenMap:isHiddenMap
                            delegate:weakSelf];
            
            cell.delegate = weakSelf;
            [cell numberLabel].text = [NSString stringWithFormat:@"%i", (int)(indexPath.row + 1)];
            
            if (weakSelf.selectedItem.row == indexPath.row + 1 && weakSelf.selectedItem.mode == Item) {
                [cell deselectRow];
                [cell selectRowItemAt:weakSelf.selectedItem.item];
            } else if (weakSelf.selectedItem.row == indexPath.row + 1 && weakSelf.selectedItem.mode == Row) {
                [cell selectRow];
            } else {
                [cell deselectRow];
            }
            
            NSInteger lightboxCount = [NSUserDefaults.standardUserDefaults integerForKey:kLightboxPreviousFramesPrefKey];
            NSArray* mixedCells = weakSelf.lightboxStack.mixedCells;
            for (FBStackInfo* celInfo in [mixedCells subarrayWithRange:NSMakeRange(0, MIN([mixedCells count], lightboxCount + 1))]) {
                if ((celInfo.row == indexPath.row + 1) && [FBPrefs boolFor:kLightboxEnabledPrefKey]) {
                    [cell highlightRowItemAt:celInfo.column];
                }
            }
            
        });
        
    });
    
    return cell;
}

#pragma mark - UITableViewDataSourcePrefetching

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    // OPTIONAL: Add prefetching?
    NSMutableIndexSet* rows;
    for (NSIndexPath* indexPath in [tableView indexPathsForVisibleRows]) {
        [rows addIndex:indexPath.row + 1];
    }
    // Add selected row
    [rows addIndex:_selectedItem.row];
//    [fStorage updateCacheForRows:rows];
}

- (void)tableView:(UITableView *)tableView cancelPrefetchingForRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    // OPTIONAL: Add prefetching?
}

#pragma mark - Scrollview

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_soundWaveController updateScrollOffset:scrollView.contentOffset.y];
}

#pragma mark - Drag & Drop

- (NSArray<UIDragItem *> *)dragInteraction:(UIDragInteraction *)interaction itemsForBeginningSession:(id<UIDragSession>)session
API_AVAILABLE(ios(11.0)){
    CGPoint location = [session locationInView:fTableView];
    NSIndexPath* indexPath = [fTableView indexPathForRowAtPoint:location];
    XSheetTableCell* cell = [fTableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [_drawingView saveChanges];
        
        int column = (int)[cell getItemIndexAt:location];
        int row = (int)indexPath.row + 1;
        FBCell* cel = [fStorage cellAtRow:row column:column];
        
        if (cel.isEmpty) {
            return @[];
        }
        
        NSMutableArray* imageArray = [NSMutableArray new];
        if (cel.paintImage) {
            [imageArray addObject:cel.paintImage.previewUiImage];
        }
        if (cel.pencilImage) {
            [imageArray addObject:cel.pencilImage.previewUiImage];
        }
        UIImage* compositedImage = [UIImage rf_imageByCompositingImages:imageArray backgroundColor:[UIColor whiteColor]];
        NSItemProvider* provider = [[NSItemProvider alloc] initWithObject:compositedImage];
        UIDragItem* dragItem = [[UIDragItem alloc] initWithItemProvider:provider];
        
        FBCelDragDropModel* dragDropModel = [[FBCelDragDropModel alloc] initWithPencil:cel.pencilImage paint:cel.paintImage structure:cel.structureImage row:row column:column];
        [dragItem setLocalObject:dragDropModel];
        
        return @[dragItem];
    } else {
         return @[];
    }
}

- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session
API_AVAILABLE(ios(11.0)){
    return [session canLoadObjectsOfClass:[UIImage self]];
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session
API_AVAILABLE(ios(11.0)){
    CGPoint location = [session locationInView:fTableView];
    NSIndexPath* indexPath = [fTableView indexPathForRowAtPoint:location];
    XSheetTableCell* cell = [fTableView cellForRowAtIndexPath:indexPath];
    
    int targetColumn = (int)[cell getItemIndexAt:location];
    int targetRow = (int)indexPath.row + 1;

    FBCelDragDropModel* dragDropModel = session.items.firstObject.localObject;
    
    /// Remove old images and preview
    [_previewCache removePreviewImageWithRow:dragDropModel.row item:dragDropModel.column];
    [_lightboxStack removeAll];
    [_drawingView clearCurrentCellLeavingLightbox:nil];
    
    [fStorage storeCell:[FBCell emptyCel] atRow:dragDropModel.row column:dragDropModel.column];

    /// Save the new one
    FBCell* new_cel = [[FBCell alloc] init];
    new_cel.paintImage = dragDropModel.paintImage;
    new_cel.pencilImage = dragDropModel.pencilImage;
    new_cel.structureImage = dragDropModel.structureImage;
    new_cel.isLoaded = YES;
    [fStorage storeCell:new_cel atRow:targetRow column:targetColumn];
    
//    [fTableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:(dragDropModel.row - 1) inSection:0] ] withRowAnimation:UITableViewRowAnimationNone];
    [fTableView reloadData];
    
    [self selectRow:targetRow item:targetColumn];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session
API_AVAILABLE(ios(11.0)){
    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationMove];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.updateCellTimer invalidate];
    self.updateCellTimer = nil;
}

#pragma mark - SoundWaveViewControllerDelegate

- (void)didChangeOffsetTo:(CGFloat)newOffset
{
    [self.sceneController.document setSoundOffset:newOffset];
}

- (void)didLongPressSoundHeaderWithView:(UIView *)view rect:(CGRect)rect
{
    [_drawingView saveChanges];
    FBColumnsController* columns_controller = [[FBColumnsController alloc] init];
    [columns_controller configureWithDatabase:[_sceneController.document database] levelIndex:-1 columnsCount:fNumUserColumns];
    [columns_controller setLevelIndex:-1];
    [columns_controller setDelegate:self];
    columns_controller.preferredContentSize = CGSizeMake(256.0f, 315.0f);

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        // Phone popover adapter
        PhoneSheetContainerController* container_controller = [PhoneSheetContainerController new];
        [container_controller view];
        [container_controller setContainedController:columns_controller];
        [self presentViewController:container_controller animated:YES completion:nil];
    } else {
        // Normal popover
        UIPopoverPresentationController *popover_controller = [columns_controller popoverPresentationController];
        popover_controller.sourceView = view;
        popover_controller.sourceRect = rect;
        [popover_controller setPermittedArrowDirections:UIPopoverArrowDirectionUp];
        [self presentViewController:columns_controller animated:YES completion:NULL];
    }

    [FBHelpController showHelpPane:kHelpPaneLevels];
}

#pragma mark - XSheetHeaderViewDelegate

- (void)sheetHeaderViewDidClickEditButton:(XSheetHeaderView *)sheetHeaderView {
    //
}

- (void)didLongPressInLevelAtIndex:(NSInteger)index sourceView:(UIView*)sourceView
{
    [_drawingView saveChanges];
    FBColumnsController* columns_controller = [[FBColumnsController alloc] init];
    [columns_controller configureWithDatabase:[_sceneController.document database] levelIndex:index columnsCount:fNumUserColumns];
    [columns_controller setLevelIndex:index];
    [columns_controller setDelegate:self];
    // 315.0 is 328.0 - 13.0;
    // where 328.0 height in xib;
    // where 13.0 is arrow height for popover;
    columns_controller.preferredContentSize = CGSizeMake(256.0f, 315.0f);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        // Phone popover adapter
        PhoneSheetContainerController* container_controller = [PhoneSheetContainerController new];
        [container_controller view];
        [container_controller setContainedController:columns_controller];
        [self presentViewController:container_controller animated:YES completion:nil];
    } else {
        // Normal popover
        UIPopoverPresentationController *popover_controller = [columns_controller popoverPresentationController];
        popover_controller.sourceView = sourceView;
        popover_controller.sourceRect = sourceView.bounds;
        [popover_controller setPermittedArrowDirections:UIPopoverArrowDirectionUp];
        [self presentViewController:columns_controller animated:YES completion:nil];
    }
    
    [FBHelpController showHelpPane:kHelpPaneLevels];
}

#pragma mark - Adding / delete Columns

- (void) insertColumn:(NSInteger)index
{
    [self insertColumnAt:index offsetPosition:1];
}

- (void) insertColumnAt:(NSInteger)columnPosition offsetPosition:(NSInteger)offsetPosition
{
    [fStorage insertColumnAfterColumn:(columnPosition + offsetPosition)];
}

- (void) deleteColumn:(NSInteger)index
{
    [self deleteColumnAt:index];
    
//    BOOL isCellEmpty = true;
//    for (NSInteger i = 1; i <= [self->fStorage numberOfRows] && isCellEmpty; i++)
//    {
//        FBCell* cell = [fStorage cellAtRow:i column:index];
//        isCellEmpty &= ((cell == nil) || ([cell isEmpty]));
//    }
//
//    if (isCellEmpty) {
//        [self deleteColumnAt:index];
//        return;
//    }
//
//    UIAlertController*alert = [UIAlertController alertControllerWithTitle:nil message:@"Do you really want to delete this column?" preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction*delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//        [self deleteColumnAt:index];
//    }];
//    UIAlertAction*cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
//    [alert addAction:delete];
//    [alert addAction:cancel];
//    [self presentViewController:alert animated:YES completion:nil];
}

-(void) deleteColumnAt:(NSInteger)columnPosition
{
    [fStorage deleteWithColumn:columnPosition];
}

#pragma mark - FBColumnsControllerDelegate

- (bool)checkXsheetLevelLimits:(NSUInteger)numberColumns {
    
    BOOL exceeded = fStorage.numberOfColumns >= [FeatureManager.shared maxLevels];
    
    if (exceeded) {
        
                if (self.presentedViewController) {
                    [self.presentedViewController dismissViewControllerAnimated:YES
                                                                      completion:^{
                        [UIAlertController showBlockedAlertControllerFor:self.sceneController feature:@"Adding more levels" level:@""];
                    }];
                } else {
                    [UIAlertController showBlockedAlertControllerFor:self feature:@"Adding more levels" level:@""];
                }
        
    }

    return exceeded;

    
//    BOOL result = numberColumns < [FeatureManager shared].maxLevels;
//    if (!result) {
//        if (self.presentedViewController) {
//            [self.presentedViewController dismissViewControllerAnimated:YES
//                                                              completion:^{
//                [UIAlertController showBlockedAlertControllerFor:self.sceneController feature:@"Add more levels" level:@""];
//            }];
//        } else {
//            [UIAlertController showBlockedAlertControllerFor:self.sceneController];
//        }
//    }
//    return result;
}

/*
- (void)didInsertLevelForIndex:(NSUInteger)index {
    if (![self checkXsheetLevelLimits:(fNumUserColumns + 1)]) {
        return;
    }
    
    [self insertColumn:index];
    
    fNumUserColumns += 1;
    [self->fStorage setNumberOfColumns:fNumUserColumns];
    
    [fTableView reloadData];

    [self setupTableWidthConstraint];
}
*/

- (void)didAddedLevelForIndex:(NSUInteger)index {
    
    BOOL exceed = [self checkXsheetLevelLimits:(fNumUserColumns + 1)] == NO;
    
    if (!exceed) {
        return;
    }
    
    [_lightboxStack removeAll];
    
    [self insertColumn:index];
    
    fNumUserColumns += 1;
    [self->fStorage setNumberOfColumns:fNumUserColumns];
    [_previewCache removeAll];
    
    [fTableView reloadData];

    [self setupTableWidthConstraint];
    [self selectRow:1 item:index + 1];
}

- (void)didDeleteLevelAtIndex:(NSUInteger)index {
    
    if (fNumUserColumns <= 2) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Do you really want to delete this column?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction*delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        [self.lightboxStack removeAll];
        [self.previewCache removeAll];

        [self deleteColumn:index];
        
        self->fNumUserColumns -= 1;
        [self->fStorage setNumberOfColumns:self->fNumUserColumns];
        
        [self->fTableView reloadData];

        [self setupTableWidthConstraint];

        [self selectFirstRow];
    }];
    UIAlertAction*cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:delete];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didChangeLevelNameTo:(NSString *)newName atIndex:(NSInteger)index
{
    [_sceneController.document.database setLevelName:newName atIndex:index];
    [self.fTableView reloadData];
    
    if (index == -1) {
        [_soundWaveController setHeaderTitle:[[_sceneController.document database] levelNameAtIndex:-1]];
    }
}

- (void)didChangeLevelLockedTo:(BOOL)isLocked atIndex:(NSInteger)index
{
    [_sceneController.document.database setLevelIsLocked:isLocked atIndex:index];
    [self.fTableView reloadData];
    
    if (index == -1) {
        [self setupSoundWave];
    }
}

- (void)didChangeLevelHiddenTo:(BOOL)isHidden atIndex:(NSInteger)index
{
    [_sceneController.document.database setLevelIsHidden:isHidden atIndex:index];
    [self.fTableView reloadData];
    [self setupTableWidthConstraint];
    
    if (index == -1) {
        [self setupSoundWave];
    }
}

- (void)didRequestShowAllLevels
{
    for (int i = -1; i < fNumUserColumns; i++)
    {
        [_sceneController.document.database setLevelIsHidden:NO atIndex:i];
    }
    [self.fTableView reloadData];
    [self setupTableWidthConstraint];
    [self setupSoundWave];
}

- (void)didRequestMoveLeftColumnsController:(FBColumnsController *)columnsController {
    NSInteger newIndex = columnsController.levelIndex + 1;
    if ([fStorage.database isLevelHiddenAtIndex:newIndex]) {
        NSInteger next = newIndex + 1;
        if (next >= fNumUserColumns) {
            return;
        }
        columnsController.levelIndex = next;
        [self didRequestMoveLeftColumnsController:columnsController];
        return;
    }
    [self refreshColumnsController:columnsController newIndex:newIndex];
}

- (void)didRequestMoveRightColumnsController:(FBColumnsController *)columnsController
{
    NSInteger newIndex = columnsController.levelIndex - 1;
    if ([fStorage.database isLevelHiddenAtIndex:newIndex]) {
        NSInteger next = newIndex - 1;
        if (next < -1) {
            return;
        }
        columnsController.levelIndex = next;
        [self didRequestMoveRightColumnsController:columnsController];
        return;
    }
    [self refreshColumnsController:columnsController newIndex:newIndex];
}

- (void)didRequestLayoutRefreshByColumnsController:(FBColumnsController *)columnsController
{
    [self.fTableView layoutIfNeeded];
    
    NSInteger newIndex = columnsController.levelIndex;
    
    [self refreshColumnsController:columnsController newIndex:newIndex];
}

- (void)refreshColumnsController:(FBColumnsController *)columnsController newIndex:(NSInteger)newIndex
{
    NSInteger newSafeIndex = MIN(newIndex, fNumUserColumns - 1);
    XSheetHeaderView* headerView = (XSheetHeaderView*)[fTableView headerViewForSection:0];
    if (newSafeIndex == -1) {
        UIView* sourceView = _soundWaveController.view;
        CGRect sourceRect = [_soundWaveController titleRect];
        [columnsController.popoverPresentationController setSourceView:sourceView];
        [columnsController.popoverPresentationController setSourceRect:sourceRect];
    } else {
        UIView* sourceView = [headerView headerOfColumnAt:newSafeIndex];
        CGRect sourceRect = [sourceView convertRect:sourceView.bounds toView:headerView];
        [columnsController.popoverPresentationController setSourceView:headerView];
        [columnsController.popoverPresentationController setSourceRect:sourceRect];
    }
    columnsController.preferredContentSize = CGSizeMake(256.0f, 315.1f);
    columnsController.preferredContentSize = CGSizeMake(256.0f, 315.0f);
    [columnsController configureWithDatabase:[_sceneController.document database] levelIndex:newSafeIndex columnsCount:fNumUserColumns];
}

#pragma mark - FBSlideViewDelegate

- (NSInteger)numberOfColumndsForSlideView:(FBSlideView *)slideView {
    return (tableViewWidtchConstraint.constant - kDefaultGridRowNumberWidth) / kDefaultGridCellWidth;
}

@end
