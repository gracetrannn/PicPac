//
//  FBColumnsController.h
//  FlipPad
//
//  Created by Manton Reece on 10/6/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kChangeColumnsCountKey @"count"
#define kChangeColumnsAllowedKey @"allowed"
#define kChangeColumnsIndexKey @"index"

typedef NS_ENUM(NSUInteger, FBColumnsControllerMode) {
    FBColumnsControllerModeNormal,
    FBColumnsControllerModeSound,
};

@class FBStepperControl;
@class FBColumnsController;

@protocol FBSceneDatabase;

@protocol FBColumnsControllerDelegate <NSObject>

/*
- (void)didInsertLevelForIndex:(NSUInteger)index;
*/

- (void)didAddedLevelForIndex:(NSUInteger)index;

- (void)didDeleteLevelAtIndex:(NSUInteger)index;

- (void)didChangeLevelNameTo:(NSString*)newName atIndex:(NSInteger)index;

- (void)didChangeLevelLockedTo:(BOOL)isLocked atIndex:(NSInteger)index;

- (void)didChangeLevelHiddenTo:(BOOL)isHidden atIndex:(NSInteger)index;

- (void)didRequestShowAllLevels;

- (void)didRequestMoveLeftColumnsController:(FBColumnsController*)columnsController;

- (void)didRequestMoveRightColumnsController:(FBColumnsController*)columnsController;

- (void)didRequestLayoutRefreshByColumnsController:(FBColumnsController *)columnsController;

/// Change columns count
- (void)changeColumnsUserInfo:(NSMutableDictionary*)user_info;

- (void)reselectCurrent;

@end

@interface FBColumnsController : UIViewController <UIPopoverPresentationControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) id<FBColumnsControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextField *levelNameField;

@property (weak, nonatomic) IBOutlet UISwitch *lockSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *hideSwitch;
@property (weak, nonatomic) IBOutlet UIButton *leftArrowButton;
@property (weak, nonatomic) IBOutlet UIButton *rightArrowButton;

// Initial level properties
@property (assign, nonatomic) NSInteger levelIndex;
@property (assign, nonatomic) NSInteger totalLevelsCount;
@property (strong, nonatomic) NSString* levelName;
@property (assign, nonatomic) BOOL levelIsLocked;
@property (assign, nonatomic) BOOL levelIsHidden;

- (void)configureWithDatabase:(id<FBSceneDatabase>)database levelIndex:(NSInteger)levelIndex columnsCount:(NSInteger)columnsCount;

@end
