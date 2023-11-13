//
//  FBDocumentsController.h
//  FlipBookPad
//
//  Created by Manton Reece on 7/25/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBSceneController.h"

@class FBSceneController;
//@class FBUpgradeController;
@class FBHelpController;

@protocol OnboardingDelegate;

#if TARGET_OS_MACCATALYST
@interface FBDocumentsController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverControllerDelegate, UIDocumentPickerDelegate, FBSceneControllerDelegate, NSToolbarDelegate>
#else
@interface FBDocumentsController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverControllerDelegate, UIDocumentPickerDelegate, FBSceneControllerDelegate, OnboardingDelegate>
#endif

//@property (weak, nonatomic) IBOutlet UIBarButtonItem *upgradeButton;

@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet UIToolbar* currentToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar* mainToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar* editingToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar* demoToolbar;

@property (strong, nonatomic) NSArray* documents; // file paths
@property (strong, nonatomic) FBSceneController* currentSceneController;
@property (assign, nonatomic) BOOL isEditing;
@property (strong, nonatomic) FBHelpController* helpController;

- (void)closeCurrentDocument;
- (void)closeCurrentDocumentAnimated:(BOOL)animated;

#if !TARGET_OS_MACCATALYST
- (void) replaceToolbarWith:(UIToolbar *)inToolbar;
#endif
- (void) deselectAll;
- (NSString *) pathForNewDocumentNamed:(NSString *)baseName;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createSceneButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTopConstraint;

- (IBAction) showSettings:(UIBarButtonItem *)sender;
- (IBAction) deleteDocument:(id)inSender;
- (IBAction) shareDocument:(id)inSender;
- (IBAction) importDocument:(id)sender;
- (IBAction) renameDocument:(id)inSender;
- (IBAction) finishEditing:(id)inSender;
- (IBAction) startEditing:(id)inSender;
- (IBAction)purchasesAction:(id)sender;

#pragma mark -

- (void)restoreDocument;

@end
