//
//  FBDocumentsController.m
//  FlipBookPad
//
//  Created by Manton Reece on 7/25/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBDocumentsController.h"
#import "FBMacros.h"
#import "FBDocumentCell.h"
#import "FBSceneController.h"
#import "FBSceneDocument.h"
#import "FBHelpController.h"
#import "FBInfoController.h"
#import "NSString_Extras.h"
#import "UIToolbar_Extras.h"
#import "NSURL_Extras.h"
#import "FBConstants.h"
#import "Header-Swift.h"
#import "UIViewController_Extras.h"
#import "UIWindow+NSWindow.h"
#import "Bundle.h"
#import "Name.h"

#import <StoreKit/StoreKit.h>

#define kDocumentCellIdentifier @"DocumentCell"
//#define kDoneButtonTag 1
#define kImportButtonTag 2
#define kSettingsButtonTag 3
#define kStorageTypeUpdate @"kStorageTypeUpdate"
#define kLaunchCount @"LaunchCount"

#if TARGET_OS_MACCATALYST
#define kRenameItem @"RenameItem"
#define kDuplicateItem @"DuplicateItem"
#define kDeleteItem @"DeleteItem"
#define kExportItem @"ExportItem"
#define kDoneItem @"DoneItem"
#define kNewSceneItem @"NewSceneItem"
#define kImportItem @"ImportItem"
#define kRestorePurchesItem @"RestorePurchesItem"
#define kSelectItem @"SelectItem"
#define kPurchasesItem @"PurchasesItem"
#define kFinishedUpgradeNotification @"UIFocusDidUpdateNotification"
#endif

@interface FBDocumentsController()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property(nonatomic, assign) StorageType oldStorageType;
@property(nonatomic, strong) NSTimer* downloadTimer;
@property(strong, nonatomic) UIView* sourceSettingsView;
#if TARGET_OS_MACCATALYST
@property(strong, nonatomic) UIBarButtonItem* sceneCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* importCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* restorePurchaseCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* selectCatalystButton;

@property(strong, nonatomic) UIBarButtonItem* renameCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* duplicateCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* deleteCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* exportCatalystButton;
@property(strong, nonatomic) UIBarButtonItem* doneCatalystButton;
@property (strong, nonatomic) UIBarButtonItem *purchasesCatalystButton;
#endif

@property (assign, nonatomic) BOOL appeared;

@property (strong, nonatomic) NSIndexPath *latestIndexPath;

@property (assign, nonatomic) BOOL showAnimated;

@end

@implementation FBDocumentsController

- (id) init
{
    self = [super initWithNibName:@"Documents" bundle:nil];
    if (self) {
        _showAnimated = YES;
        [self clearThumbnailCache];
        [self setupDocuments];
        [self monitorDownloads];
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
    
    _oldStorageType = [SettingsBundleHelper storageType];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

//#if FLIPBOOK
//    [self.upgradeButton setTitle:@"Upgrade FlipBook"];
//#endif
    
#if !TARGET_OS_MACCATALYST
    self.currentToolbar.items = self.mainToolbar.items;
    
    self.mainToolbar.tintColor = [UIColor colorWithRed:0.899 green:0.936 blue:0.984 alpha:1.000];
    self.editingToolbar.tintColor = [UIColor colorWithRed:0.899 green:0.936 blue:0.984 alpha:1.000];
    self.demoToolbar.tintColor = [UIColor colorWithRed:0.899 green:0.936 blue:0.984 alpha:1.000];
#else
    [_collectionViewTopConstraint setConstant:-self.currentToolbar.frame.size.height];
    [self.currentToolbar setHidden:YES];
#endif
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"DocumentCell" bundle:nil] forCellWithReuseIdentifier:kDocumentCellIdentifier];
    [self.collectionView setAllowsMultipleSelection:NO];
    
    [self setupNotifications];
}

- (void) viewWillAppear:(BOOL)inAnimated
{
    [super viewWillAppear:inAnimated];
#if TARGET_OS_MACCATALYST
    [self setupCatalystButtons];
    [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
#endif
}

- (void) viewDidAppear:(BOOL)inAnimated
{
    [super viewDidAppear:inAnimated];
    
    if (!_appeared) {
        [self showStartupError];
#if TARGET_OS_MACCATALYST
        [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
#endif
        
        NSInteger launchCount = [NSUserDefaults.standardUserDefaults integerForKey:kLaunchCount];
        if (launchCount == 1) {
            [self showOnboarding];
        }
        if (launchCount == 3) {
            [self showRatingAlert];
        }
        
        _appeared = YES;
        
        NSString *lastSceneFileName = [[NSUserDefaults standardUserDefaults] valueForKey:kLastSceneName];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", lastSceneFileName];
        NSArray *filteredArray = [_documents filteredArrayUsingPredicate:predicate];
        NSString *filePath = [filteredArray firstObject];
        
        if (filePath && ![filePath isEqual: @"none"])
        {
            [self openSceneWithFilePath:filePath];
        }
        
    }
    
//    if ([NSDate date].timeIntervalSince1970 > 1640901600) {
//        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Application expired" message:nil preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            exit(0);
//        }]];
//        [self presentViewController:alert animated:YES completion:nil];
//    }
    
#if TARGET_OS_MACCATALYST
    [MenuAssembler setState: StateDef];
    [MenuAssembler rebuild];
#endif
}

#if TARGET_OS_MACCATALYST
- (void)setupCatalystButtons
{
    _sourceSettingsView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 60, 90)];
    [_sourceSettingsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self view] addSubview:_sourceSettingsView];
    
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger versionNumber = version.majorVersion;
    CGFloat sourceSettingsViewOffset;
    if (versionNumber == 11) {
        sourceSettingsViewOffset = 100.0;
    } else {
        sourceSettingsViewOffset = 60.0;
    }
    
    [[[_sourceSettingsView widthAnchor] constraintEqualToConstant:sourceSettingsViewOffset] setActive:YES];
    [[[_sourceSettingsView topAnchor] constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    if (@available(iOS 11, *)) {
        UILayoutGuide * guide = self.view.safeAreaLayoutGuide;
        [[_sourceSettingsView.bottomAnchor constraintEqualToAnchor:guide.topAnchor] setActive:YES];
    }
    
    _sceneCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus"] style:UIBarButtonItemStyleDone target:self action:@selector(showSettings:)];
    _importCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"folder"] style:UIBarButtonItemStyleDone target:self action:@selector(importDocument:)];
    _restorePurchaseCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"cart"] style:UIBarButtonItemStyleDone target:self action:@selector(upgrade:)];
    _selectCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] style:UIBarButtonItemStyleDone target:self action:@selector(startEditing:)];
    
    _renameCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"pencil"] style:UIBarButtonItemStyleDone target:self action:@selector(renameDocument:)];
    _duplicateCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc"] style:UIBarButtonItemStyleDone target:self action:@selector(duplicateDocument:)];
    _deleteCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"] style:UIBarButtonItemStyleDone target:self action:@selector(deleteDocument:)];
    _exportCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"] style:UIBarButtonItemStyleDone target:self action:@selector(shareDocument:)];
    _doneCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.rectangle"] style:UIBarButtonItemStyleDone target:self action:@selector(finishEditing:)];
    _purchasesCatalystButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"cart"]
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(purchasesAction:)];
    [self.view layoutIfNeeded];
}
#endif

- (void)showStartupError
{
    NSError* startupError = [(AppDelegate*)UIApplication.sharedApplication.delegate startupError];
    
    if (startupError && startupError.code == FileErrorICloudDriveDocumentsNotAvailable) {
#if TARGET_OS_MACCATALYST
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:[kAppName stringByAppendingString:@" can save your scenes in your Apple iCloud account. Would you like to enable it?"] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString* path = @"x-apple.systempreferences:";
            NSString* pathEnding = @"com.apple.preferences.icloud";
            path = [path stringByAppendingString:pathEnding];
            NSURL* url = [NSURL URLWithString:path];
            [[UIApplication sharedApplication] openURL:url options:[NSDictionary new] completionHandler:^(BOOL success){}];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
#else
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:[kAppName stringByAppendingString:@" can save your scenes in your Apple iCloud account. You can enable iCloud Drive in Settings"] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
#endif
        return;
    }

    
    if (startupError) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:[startupError localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL) shouldAutorotate
{
    return YES;
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

- (void) showRatingAlert
{
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

- (void) setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedUpgradeNotification:) name:kFinishedUpgradeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefsChanged:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideAllPopoversNotification:) name:kHideAllPopoversNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpgradeNotification:) name:kShowUpgradeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewSceneNotification:) name:kAddNewSceneNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldMoveFiles:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openRecentlyHandler:)
                                                 name:kOpenRecently
                                               object:nil];
}

- (void) shouldMoveFiles:(NSNotification *)notification
{
    StorageType newValue = [SettingsBundleHelper storageType];
    if (_oldStorageType != newValue) {
        _oldStorageType = newValue;
        if (_currentSceneController) {
            [_currentSceneController dismissViewControllerAnimated:YES completion:^{
                [self moveFilesToActualFolder];
                self->_currentSceneController = nil;
            }];
        } else {
            [self moveFilesToActualFolder];
        }
    }
}

- (void) moveFilesToActualFolder {
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSError* error;
    [delegate moveFilesToActualFolderAndReturnError:&error];
    if (error) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self setupDocuments];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
}

- (void)setupDocuments
{
    NSMutableArray* new_docs = [NSMutableArray array];
    NSString* docs_folder = [NSURL documentsFolder].path;
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docs_folder error:nil];
    
    BOOL foundCloudFile = NO;
    for (NSString* filename in files)
    {
        for (NSString* extension in ([Config DGC] ? @[kDGC, kDCFB] : @[kDCFB]))
        {
            NSString* iCloudSuffix = [NSString stringWithFormat:@"%@.icloud", extension];
            if ([[[filename pathExtension] lowercaseString] isEqualToString:extension]) { /// Downloaded
//            if ([[filename pathExtension] isEqualToString:extension]) { /// Downloaded
                NSString* localFile = [docs_folder stringByAppendingPathComponent:filename];
                [new_docs addObject:localFile];
            } else if ([filename hasSuffix:iCloudSuffix]) { /// On iCloud
                foundCloudFile = YES;
                NSString* cloudFile = [docs_folder stringByAppendingPathComponent:filename];
                [new_docs addObject:cloudFile];
                /// Start loading file
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:[NSURL fileURLWithPath:cloudFile] error:nil];
            }
            // Else not .dcfb / .dgc
        }
        
        /// Maybe Palettes?
        if ([filename isEqualToString:@"Palettes"])
        {
            NSString* paletteFolder = [docs_folder stringByAppendingPathComponent:filename];
            NSArray* paletteFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:paletteFolder error:nil];
            for (NSString* palette in paletteFiles) {
                NSString* iCloudSuffix = [NSString stringWithFormat:@"%@.icloud", @"plist"];
                if ([palette hasSuffix:iCloudSuffix] && [palette hasPrefix:@"."]) { /// On iCloud
                    foundCloudFile = YES;
                    NSString* cloudFile = [palette substringFromIndex:1];
                    cloudFile = [cloudFile stringByReplacingOccurrencesOfString:@".icloud" withString:@""];
                    NSString* downloadFilePath = [paletteFolder stringByAppendingPathComponent:cloudFile];
                    /// Start loading file
                    [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:[NSURL fileURLWithPath:downloadFilePath] error:nil];
                }
            }
        }
    }
    
    if (!foundCloudFile) { // Stop monitor for files
        [_downloadTimer invalidate];
        _downloadTimer = nil;
    }
    
    if ([new_docs count] == 0) {
        NSArray* files_array = @[
            @"FlipPad Tutorial",
        ];
        
        for (NSString* file_name in files_array) {
            NSString* source_path = [[NSBundle mainBundle] pathForResource:file_name ofType:@"dcfb"];
            NSString* dest_path = [docs_folder stringByAppendingPathComponent:[source_path lastPathComponent]];
            
            [[NSFileManager defaultManager] copyItemAtPath:source_path toPath:dest_path error:nil];
            [new_docs addObject:dest_path];
        }
    }

    [new_docs sortUsingComparator:^NSComparisonResult (NSString* path1, NSString* path2) {
        NSDictionary* attrs1 = [[NSFileManager defaultManager] attributesOfItemAtPath:path1 error:nil];
        NSDictionary* attrs2 = [[NSFileManager defaultManager] attributesOfItemAtPath:path2 error:nil];
        return [[attrs2 objectForKey:NSFileModificationDate] compare:[attrs1 objectForKey:NSFileModificationDate]];
    }];

    self.documents = new_docs;
}

- (void)monitorDownloads
{
    _downloadTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(refreshDownloads) userInfo:nil repeats:YES];
}

- (void)refreshDownloads
{
    [self setupDocuments];
    NSIndexPath* selected = [_collectionView indexPathsForSelectedItems].firstObject;
    [self.collectionView reloadData];
    if (selected) {
        [self.collectionView selectItemAtIndexPath:selected animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

#pragma mark -

- (void) prefsChanged:(NSNotification *)notification
{
}

- (void) finishedUpgradeNotification:(NSNotification *)notification
{
#if TARGET_OS_MACCATALYST
    [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
#else
    [self replaceToolbarWith:self.mainToolbar];
#endif
}

- (void) hideAllPopoversNotification:(NSNotification *)notification
{
//    if (self.helpPopover) {
//        [self.helpPopover dismissPopoverAnimated:YES];
//        self.helpController = nil;
//        self.helpPopover = nil;
//    }
    
    /*if ([notification.userInfo valueForKey:@"fromUpgradeController"])
    {
        if (self.presentedViewController) {
            // FIXME: what was this dismissing?
            [self.presentedViewController dismissViewControllerAnimated:NO completion:NULL];
        }
        else if (self.popoverPresentationController)
        {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }*/
}

//- (void) showUpgradeNotification:(NSNotification *)notification
//{
//    if (self.currentSceneController == nil) {
//        [self upgrade:nil];
//    }
//}

- (void) addNewSceneNotification:(NSNotification *)notification
{
    [self continueNewScene];
}

#pragma -

- (NSString *) pathForNewUntitledDocument
{
    return [self pathForNewDocumentNamed:@"Untitled"];
}

- (NSString *) pathForNewDocumentNamed:(NSString *)baseName
{
    NSString* s = baseName;
    NSString* path = nil;
    BOOL found_unique = NO;
    int num = 1;

    do {
        NSString* filename = [NSString stringWithFormat:@"%@.%@", s, kDCFB];
        NSString* docs_folder = [NSURL documentsFolder].path;
        path = [docs_folder stringByAppendingPathComponent:filename];
        if ([path pathExists]) {
            num++;
            s = [NSString stringWithFormat:@"%@ %d", baseName, num];
        }
        else {
            found_unique = YES;
        }
    }
    while (!found_unique);
    
    return path;
}

- (void) deselectAll
{
    NSArray* item_paths = [self.collectionView indexPathsForSelectedItems];
    for (NSIndexPath* index_path in item_paths) {
        [self.collectionView deselectItemAtIndexPath:index_path animated:NO];
        [self collectionView:self.collectionView didDeselectItemAtIndexPath:index_path];
    }
}

- (void)closeCurrentDocument {
    [self closeCurrentDocumentAnimated:NO];
}

- (void)closeCurrentDocumentAnimated:(BOOL)animated {
    [self closeCurrentDocumentAnimated:animated withBlock:nil];
}

- (void)closeCurrentDocumentAnimated:(BOOL)animated withBlock:(void(^)(void))block {
    [self.currentToolbar setHidden:NO];
    [self deselectAll];
    [self setupDocuments];
    [self.collectionView reloadData];
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:animated
                             completion:^{
        weakSelf.currentSceneController = nil;
        if (block) {
            block();
        }
    }];
}

- (void) continueNewScene
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }

    NSMutableArray* new_documents = [self.documents mutableCopy];
    [new_documents insertObject:[self pathForNewUntitledDocument] atIndex:0];
    self.documents = new_documents;

    NSIndexPath* index_path = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView insertItemsAtIndexPaths:@[ index_path ]];

    [self performSelector:@selector(openSceneAtIndexPath:) withObject:index_path afterDelay:0.5];
}

- (IBAction) showSettings:(UIBarButtonItem *)sender
{
    UIBarButtonItem* settings_button = nil;
    for (UIBarButtonItem* button in self.currentToolbar.items) {
        if (button.tag == kSettingsButtonTag) {
            settings_button = button;
            break;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    
    FBInfoController* info_controller = [[FBInfoController alloc] init];
    info_controller.preferredContentSize = info_controller.view.frame.size;
    [self presentViewController:info_controller animated:YES completion:^{
        [FBHelpController showHelpPane:kHelpPaneHD];
    }];

    UIPopoverPresentationController* popover_controller = [info_controller popoverPresentationController];
#if TARGET_OS_MACCATALYST
    popover_controller.sourceView = _sourceSettingsView;
    popover_controller.sourceRect = _sourceSettingsView.frame;
#else
    popover_controller.barButtonItem = settings_button;
#endif

}

#if !TARGET_OS_MACCATALYST
- (void) replaceToolbarWith:(UIToolbar *)inToolbar
{
    self.currentToolbar.items = inToolbar.items;
}
#endif

//- (IBAction) upgrade:(id)inSender
//{
//    [FeatureManager.shared toPurchase: self];
//}

- (IBAction) startEditing:(id)inSender
{
#if TARGET_OS_MACCATALYST
    if (!_currentSceneController) {
        self.isEditing = YES;
        [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
        [MenuAssembler setState: StateEdit];
        [MenuAssembler rebuild];
    }
#else
    self.isEditing = YES;
    [self replaceToolbarWith:self.editingToolbar];
    [self.currentToolbar rf_enableButtonsWithTags:@[ @kDoneButtonTag ]];
#endif
}

- (IBAction) finishEditing:(id)inSender
{
    [self deselectAll];
#if TARGET_OS_MACCATALYST
    if (!_currentSceneController) {
        self.isEditing = NO;
        [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
        [MenuAssembler setState: StateDef];
        [MenuAssembler rebuild];
    }
#else
    self.isEditing = NO;
        [self replaceToolbarWith:self.demoToolbar];
#endif
}

- (IBAction)importDocument:(id)sender {
    if (_currentSceneController) {
        __weak typeof(self) weakSelf = self;
        [self closeCurrentDocumentAnimated:YES withBlock:^{
            [weakSelf showImportDialog];
        }];
    } else {
        [self showImportDialog];
    }
}

- (IBAction)purchasesAction:(id)sender {
    [FeatureManager.shared toPurchase:self ];
}

- (void)showImportDialog {
    UIDocumentPickerViewController* picker;
    if (@available(iOS 14.0, *)) {
        NSArray<UTType *> *types = @[
            [UTType typeWithFilenameExtension:@"dgc"],
            [UTType typeWithFilenameExtension:@"dcfb"]
        ];
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types];
    } else {
        NSArray<NSString *> *types = @[
            [kBundleName stringByAppendingString:@".dgc"],
            [kBundleName stringByAppendingString:@".dcfb"]
        ];
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types
                                                                        inMode:UIDocumentPickerModeImport];
    }
    [picker setAllowsMultipleSelection:YES];
    [picker setDelegate:self];
    [self presentViewController:picker
                       animated:YES
                     completion:nil];
}

- (IBAction) renameDocument:(id)inSender
{
    NSIndexPath* selected = [_collectionView indexPathsForSelectedItems].firstObject;
    if (selected) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Rename Scene" message:@"Enter a new name for this scene:" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"New scene name";
        }];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString* path = [self.documents objectAtIndex:selected.item];
            FBSceneDocument* doc = [[FBSceneDocument alloc] initWithPath:path];

            NSString* s = [[alert textFields][0] text];
            if ([s length] > 0) {
                NSError* error = nil;
                if ([doc rename:s error:&error]) {
                    [self deleteCachedThumbnailForDocumentAtPath:path];
                    [self.currentToolbar rf_disableButtonsWithTags:@[ @kDoneButtonTag ]];
                    [self deselectAll];
                    [self setupDocuments];
                    [self.collectionView reloadData];
                }
                else {
                    [@"Could not rename file" rf_showInAlertWithError:error];
                }
            }
        }];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

        [alert addAction:confirmAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)duplicateDocument:(id)inSender
{
    NSIndexPath* selected = [[self.collectionView indexPathsForSelectedItems] lastObject];
    if (selected) {
        NSString* orig_path = [self.documents objectAtIndex:selected.item];
        NSString* base_name = [[[orig_path lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" copy"];
        NSString* new_path = [self pathForNewDocumentNamed:base_name];
        [[NSFileManager defaultManager] copyItemAtPath:orig_path toPath:new_path error:nil];

        NSMutableArray* new_documents = [self.documents mutableCopy];
        [new_documents insertObject:new_path atIndex:0];
        self.documents = new_documents;

        NSIndexPath* index_path = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[ index_path ]];
    }
}

- (IBAction) deleteDocument:(id)inSender
{
    NSIndexPath* selected = [_collectionView indexPathsForSelectedItems].firstObject;
    if (selected) {
        NSString* path = [self.documents objectAtIndex:selected.item];
        NSString* title = [NSString stringWithFormat:@"Delete “%@”", [[path lastPathComponent] stringByDeletingPathExtension]];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:@"Are you sure you want to delete this scene and all of its images?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            NSMutableArray* new_paths = [self.documents mutableCopy];
            [new_paths removeObjectAtIndex:selected.item];
            self.documents = new_paths;
            [self.collectionView deleteItemsAtIndexPaths:@[ selected ]];
            [self.currentToolbar rf_enableButtonsWithTags:@[ @kDoneButtonTag ]];
            [self deleteCachedThumbnailForDocumentAtPath:path];
        }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:okAction];
        [alert addAction:cancelAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction) shareDocument:(id)inSender
{
    NSIndexPath* selected = [_collectionView indexPathsForSelectedItems].firstObject;
    if (selected) {
        NSString* path = [self.documents objectAtIndex:selected.item];
        NSURL* url = [NSURL fileURLWithPath:path];
        UIDocumentPickerViewController* picker_controller = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeExportToService];
        [self presentViewController:picker_controller animated:YES completion:NULL];

        [self finishEditing:nil];
    }
}

- (void)openRecentlyHandler:(NSNotification *)notification {
    NSString *path = notification.userInfo[@"path"];
    if (_currentSceneController) {
        __weak typeof(self) weakSelf = self;
        [self closeCurrentDocumentAnimated:YES withBlock:^{
            if (path) {
                [weakSelf openSceneWithFilePath:path];
            }
        }];
    } else {
        [self openSceneWithFilePath:path];
    }
}

- (void)showOnboarding
{
    OnboardingController* onboarding = [OnboardingController new];
    [onboarding setDelegate:self];
    [self addChildViewController:onboarding];
    
    UIView* onboardingView = onboarding.view;
    [onboardingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:onboardingView];
    [[self.view.leftAnchor constraintEqualToAnchor:onboardingView.leftAnchor] setActive:YES];
    [[self.view.rightAnchor constraintEqualToAnchor:onboardingView.rightAnchor] setActive:YES];
    [[self.view.topAnchor constraintEqualToAnchor:onboardingView.topAnchor] setActive:YES];
    [[self.view.bottomAnchor constraintEqualToAnchor:onboardingView.bottomAnchor] setActive:YES];
    
    [onboarding didMoveToParentViewController:self];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    BOOL isExists = NO;
    for (NSURL *url in urls) {
        if ([url.pathExtension.lowercaseString isEqualToString:kDCFB] || [url.pathExtension.lowercaseString isEqualToString:kDGC]) {
            NSURL *localUrl = [NSURL.documentsFolder URLByAppendingPathComponent:url.lastPathComponent];
            if ([NSFileManager.defaultManager fileExistsAtPath:localUrl.path]) {
                isExists = YES;
                continue;
            }
            [NSFileManager.defaultManager copyItemAtURL:url
                                                  toURL:localUrl
                                                  error:nil];
        }
    }
    [self deselectAll];
    [self setupDocuments];
    [self.collectionView reloadData];
    if (isExists) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Some file(s) with this name already exists"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [controller dismissViewControllerAnimated:YES
                                       completion:^{
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
        }];
    }
}

- (void)openSceneAtIndexPath:(NSIndexPath *)indexPath {
    _latestIndexPath = indexPath;
    NSString *filePath = [self.documents objectAtIndex:indexPath.item];
    [self openSceneWithFilePath:filePath];
}

- (void)openSceneWithFilePath:(NSString *)filePath {
#if TARGET_OS_MACCATALYST
    id iGPU = MTLCreateSystemDefaultDevice();
#else
    id iGPU = MTLCreateSystemDefaultDevice();
#endif
    
    if (iGPU == nil) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Device unsupported" message:@"It looks like your device's GPU does not support Metal API" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
#if TARGET_OS_MACCATALYST
    [[RecentlyManager shared] addRecentlyPath:filePath];
    [MenuAssembler rebuild];
#endif
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication.sharedApplication delegate];
    [delegate makeIncrementalCloudBackupForDocumentAtPath:filePath];
    
    FBSceneDocument *doc = [[FBSceneDocument alloc] initWithPath:filePath];
    
    
    CGFloat res = (doc.resolutionSize.height);
    NSInteger frames = (doc.storage.numberOfRows);
    NSInteger levels = (doc.storage.numberOfColumns - 2);

    NSLog(@"%f", res);
    NSLog(@"%ld", (long)frames);
    NSLog(@"%ld", (long)levels);
    
    if ( res > [FeatureManager shared].maxResolution || frames > [FeatureManager shared].maxFrames || levels > [FeatureManager shared].maxLevels - 2 ) {
        
        // TODO: String alert message
        
        NSString *resstr = res > [FeatureManager shared].maxResolution ? @"a" : @"b";
        NSString *framstr = frames > [FeatureManager shared].maxFrames ? @"a" : @"b";
        NSString *levstr = levels > [FeatureManager shared].maxLevels ? @"a" : @"b";

        [UIAlertController showBlockedAlertControllerFor:self feature:@"Opening this document" level:@""];
        return;
        
    }

    void (^openScene)(void) = ^void() {
        self.currentSceneController = [[FBSceneController alloc] initWithDocument:doc];
        [self.currentSceneController setDelegate:self];
//        [self.currentSceneController view]; // load it

//        self.currentSceneController.transitioningDelegate = self.sceneTransition;
        self.currentSceneController.modalPresentationStyle = UIModalPresentationFullScreen;

        [self presentViewController:self.currentSceneController
                           animated:self.showAnimated
                         completion:nil];
        self.showAnimated = YES;
    };
    
    BOOL isNotStraight = ![doc.database isStraightAlpha];
    if (isNotStraight)
    {
        // SHow progress alert
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Updating File Format.\n Please do not close the app" message:[NSString stringWithFormat:@"%i/%li", 1, (long)[doc.storage numberOfRows]] preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        
        // Start conversion
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (int row = 1; row <= [doc.storage numberOfRows]; row++)
            {
                for (int column = 1; column <= [doc.storage numberOfColumns]; column++)
                {
                    @autoreleasepool {
                        FBOldCell* old_cel = [doc.storage old_cellAtRow:row column:column];
                        FBCell* cel = [FBCell emptyCel];
                        
                        UIImage* pencilImage = [old_cel pencilImage];
                        UIImage* paintImage = [old_cel paintImage];
                        UIImage* structureImage = [old_cel structureImage];
                        
                        FBImage* straightPencilImage = [[FBImage alloc] initWithPremultipliedImage:pencilImage];
                        FBImage* straightPaintImage = [[FBImage alloc] initWithPremultipliedImage:paintImage];
                        FBImage* straightStructureImage = [[FBImage alloc] initWithPremultipliedImage:structureImage];
                                                
                        [cel setPencilImage:straightPencilImage];
                        [cel setPaintImage:straightPaintImage];
                        [cel setStructureImage:straightStructureImage];
                        
                        [doc.storage storeCell:cel atRow:row column:column];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alert setMessage:[NSString stringWithFormat:@"%i/%li", 1, (long)[doc.storage numberOfRows]]];
                        });
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:^{
                    openScene();
                }];
            });
            [doc.database setIsStraightAlpha];
        });
    } else {
        openScene();
    }
}

- (NSString *) cachedThumbnailPathForDocumentPath:(NSString *)inPath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cache_folder = [paths objectAtIndex:0];
    NSString* thumbnails_folder = [cache_folder stringByAppendingPathComponent:@"Thumbnails"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnails_folder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:thumbnails_folder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString* path = [thumbnails_folder stringByAppendingPathComponent:[inPath lastPathComponent]];
    return [path stringByAppendingPathExtension:@"png"];
}

- (void)deleteCachedThumbnailForDocumentAtPath:(NSString *)inPath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cache_folder = [paths objectAtIndex:0];
    NSString* thumbnails_folder = [cache_folder stringByAppendingPathComponent:@"Thumbnails"];
    NSString* path = [thumbnails_folder stringByAppendingPathComponent:[inPath lastPathComponent]];
    path = [path stringByAppendingPathExtension:@"png"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)clearThumbnailCache
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cache_folder = [paths objectAtIndex:0];
    NSString* thumbnails_folder = [cache_folder stringByAppendingPathComponent:@"Thumbnails"];
    for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:thumbnails_folder error:nil]) {
        NSString* path = [thumbnails_folder stringByAppendingPathComponent:subpath];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

#pragma mark - UICollectionView Delegate & DataSource

- (NSInteger) collectionView:(UICollectionView *)inCollectionView numberOfItemsInSection:(NSInteger)inSection
{
    return [self.documents count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)inCollectionView cellForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    NSString* file_path = [self.documents objectAtIndex:inIndexPath.item];
    
    FBDocumentCell* cell = [inCollectionView dequeueReusableCellWithReuseIdentifier:kDocumentCellIdentifier forIndexPath:inIndexPath];
    cell.layer.cornerRadius = 5.0;
    cell.previewImageView.layer.cornerRadius = 5.0;
    cell.previewImageView.layer.masksToBounds = YES;
    
    if ([[file_path pathExtension] isEqualToString:@"icloud"]) { /// If file on iCloud
        [cell.activityIndicator startAnimating];
        cell.nameField.text = [[[file_path lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension];
        [cell.previewImageView setImage:nil];
    } else {
        [cell.activityIndicator stopAnimating];
        cell.nameField.text = [[file_path lastPathComponent] stringByDeletingPathExtension];
        NSString* thumbnail_path = [self cachedThumbnailPathForDocumentPath:file_path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnail_path]) {
            /// Preview exists
            [cell.previewImageView setImage:[UIImage imageWithContentsOfFile:thumbnail_path]];
        } else {
            /// Need to create preview
            FBSceneDocument* doc = [[FBSceneDocument alloc] initWithPath:file_path];
            UIImage* thumbnail_img = [doc thumbnailImage];
            if (thumbnail_img) {
                NSData* thumbnail_data = UIImagePNGRepresentation (thumbnail_img);
                [thumbnail_data writeToFile:thumbnail_path atomically:NO];
            }
            [cell.previewImageView setImage:thumbnail_img];
        }
    }
    
    // Handle hightlighting
    NSIndexPath* selected = [_collectionView indexPathsForSelectedItems].firstObject;
    if (selected) {
        cell.backgroundColor = (selected.item == inIndexPath.item) ? UIColor.darkGrayColor : UIColor.clearColor;
    } else {
        cell.backgroundColor = UIColor.clearColor;
    }
    
    return cell;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout insetForSectionAtIndex:(NSInteger)inSection
{
    return UIEdgeInsetsMake (5.0, 5.0, 5.0, 5.0);
}

- (CGSize) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (FBIsPhone()) {
        return CGSizeMake (150.0, 150.0);
    }
    else {
        return CGSizeMake (160.0, 160.0);
    }
}

- (void) collectionView:(UICollectionView *)inCollectionView didSelectItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    NSString* documentPath = [_documents objectAtIndex:inIndexPath.item];
    if ([[documentPath pathExtension] isEqualToString:@"icloud"]) {
        return; /// Don't allow users to open iCloud files
    }
        
    if (!self.isEditing) {
        [self openSceneAtIndexPath:inIndexPath];
    } else {
        FBDocumentCell* cell = (FBDocumentCell *)[self.collectionView cellForItemAtIndexPath:inIndexPath];
        cell.backgroundColor = [UIColor darkGrayColor];
        [self.currentToolbar rf_enableAllButtons];
        if (TARGET_OS_MACCATALYST) {
            [MenuAssembler setState: StateEditSelected];
            [MenuAssembler rebuild];
        }
    }
}

- (void) collectionView:(UICollectionView *)inCollectionView didDeselectItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    FBDocumentCell* cell = (FBDocumentCell *)[self.collectionView cellForItemAtIndexPath:inIndexPath];
    cell.backgroundColor = [UIColor clearColor];
}

- (void) collectionView:(UICollectionView *)inCollectionView didHighlightItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    FBDocumentCell* cell = (FBDocumentCell *)[self.collectionView cellForItemAtIndexPath:inIndexPath];
    cell.backgroundColor = [UIColor darkGrayColor];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    FBDocumentCell* cell = (FBDocumentCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - FBSceneControllerDelegate

- (void)sceneControllerWillCloseForDocumentAtPath:(NSString *)path {
    [self deleteCachedThumbnailForDocumentAtPath:path];
#if TARGET_OS_MACCATALYST
    [self setToolbar:[ToolBarService mainToolBar:self] isTitleVisible:YES];
#endif
}

#pragma mark - OnboardingDelegate

- (void)onboardingDidHide
{
    [self openSceneAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
}

#pragma mark - NSToolBarDelegate

#if TARGET_OS_MACCATALYST
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
    if (_isEditing) {
        if ([itemIdentifier  isEqual: kRenameItem]) {
            NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kRenameItem barButtonItem:_renameCatalystButton];
            newItem.label = @"Rename";
            return newItem;
        } else if ([itemIdentifier  isEqual: kDuplicateItem]) {
            NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kDuplicateItem barButtonItem:_duplicateCatalystButton];
            newItem.label = @"Duplicate";
            return newItem;
        } else if ([itemIdentifier  isEqual: kDeleteItem]) {
            NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kDeleteItem barButtonItem:_deleteCatalystButton];
            newItem.label = @"Delete";
            return newItem;
        } else if ([itemIdentifier  isEqual: kExportItem]) {
            NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kExportItem barButtonItem:_exportCatalystButton];
            newItem.label = @"Export";
            return newItem;
        } else if ([itemIdentifier  isEqual: kDoneItem]) {
            NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:@"DoneItem" barButtonItem:_doneCatalystButton];
            newItem.label = @"Done";
            return newItem;
        }
    }
    if ([itemIdentifier  isEqual: kNewSceneItem]) {
        NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kNewSceneItem barButtonItem:_sceneCatalystButton];
        newItem.label = @"New scene";
        return newItem;
    } else if ([itemIdentifier  isEqual: kImportItem]) {
        NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kImportItem barButtonItem:_importCatalystButton];
        newItem.label = @"Open";
        return newItem;
    } else if ([itemIdentifier  isEqual: kRestorePurchesItem]) {
        NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kRestorePurchesItem barButtonItem:_restorePurchaseCatalystButton];
        newItem.label = @"Restore purchase";
        return newItem;
    } else if ([itemIdentifier  isEqual: kSelectItem]) {
        NSToolbarItem* newItem = [NSToolbarItem itemWithItemIdentifier:kSelectItem barButtonItem:_selectCatalystButton];
        newItem.label = @"Select";
        return newItem;
    } else if ([itemIdentifier isEqual:kPurchasesItem]) {
        NSToolbarItem *item = [NSToolbarItem itemWithItemIdentifier:kPurchasesItem
                                                      barButtonItem:_purchasesCatalystButton];
        item.label = @"Purchases";
        return item;
    }
    return nil;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    if (_isEditing) {
        return @[kRenameItem, kDuplicateItem, kDeleteItem, kExportItem, NSToolbarFlexibleSpaceItemIdentifier, kDoneItem];
    }
        return @[kNewSceneItem, kImportItem, kPurchasesItem, NSToolbarFlexibleSpaceItemIdentifier, kSelectItem];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarDefaultItemIdentifiers:toolbar];
}
#endif

#pragma mark -

- (void)restoreDocument {
    if (_latestIndexPath) {
        _showAnimated = NO;
        [self collectionView:_collectionView didSelectItemAtIndexPath:_latestIndexPath];
    }
}

@end
