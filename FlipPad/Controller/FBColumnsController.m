//
//  FBColumnsController.m
//  FlipPad
//
//  Created by Manton Reece on 10/6/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBColumnsController.h"
#import "FBSceneDatabase.h"
#import "FBStepperControl.h"

@interface FBColumnsController ()

/*
@property (weak, nonatomic) IBOutlet UIButton *insertButton;
 */
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (assign, nonatomic) BOOL hasSound;

@property (assign, nonatomic) NSInteger hiddenLevelsCount;
@property (assign, nonatomic) NSInteger columnsCount;

@end

@implementation FBColumnsController

- (id) init
{
	self = [super initWithNibName:@"Columns" bundle:nil];
	if (self) {
		self.modalPresentationStyle = UIModalPresentationPopover;
        if (self.popoverPresentationController) {
            self.popoverPresentationController.delegate = self;
        }
	}

	return self;
}

- (void)setLevelIndex:(NSInteger)levelIndex {
    _levelIndex = levelIndex;
    [self updateUi];
}

- (void)setTotalLevelsCount:(NSInteger)totalLevelsCount {
    _totalLevelsCount = totalLevelsCount;
    [self updateUi];
}

- (void)updateUi {
    if (_levelIndex == 0) {
        /*
        _insertButton.enabled = false;
         */
        _addButton.enabled = NO;
        _deleteButton.enabled = NO;
    } else {
        BOOL isCanDelete = _totalLevelsCount > 2;
        /*
        _insertButton.enabled = true;
         */
        _addButton.enabled = YES;
        _deleteButton.enabled = isCanDelete;
    }
}

- (void)configureWithDatabase:(id<FBSceneDatabase>)database levelIndex:(NSInteger)levelIndex columnsCount:(NSInteger)columnsCount
{
    NSString* levelName = [database levelNameAtIndex:levelIndex];
    if (!levelName) {
        if (levelIndex == -1) {
            levelName = @"Sound";
        } else if (levelIndex == 0) {
            levelName = @"Background";
        } else {
            levelName = [NSString stringWithFormat:@"Foreground %li", (long)levelIndex];
        }
    }
    BOOL levelIsLocked = [database isLevelLockedAtIndex:levelIndex];
    BOOL levelIsHidden = [database isLevelHiddenAtIndex:levelIndex];
    
    NSInteger hiddenLevelsCount = 0;
    NSInteger lowerHiddenLevelsCount = 0;
    for (int i = 0; i < columnsCount; i++) {
        BOOL isHidden = [database isLevelHiddenAtIndex:i];
        if (isHidden) {
            hiddenLevelsCount += 1;
            if (i <= levelIndex) {
                lowerHiddenLevelsCount += 1;
            }
        }
    }
    
    _levelIndex = levelIndex;
    _totalLevelsCount = columnsCount;
    _levelName = levelName;
    _levelIsLocked = levelIsLocked;
    _levelIsHidden = levelIsHidden;
    _hiddenLevelsCount = hiddenLevelsCount;
    _hasSound = [database soundData] != nil;
    _columnsCount = columnsCount;
    
    [self fill];
}

- (void)fill {
    _levelNameField.text = _levelName;
    [_hideSwitch setOn:_levelIsHidden];
    [_lockSwitch setOn:_levelIsLocked];
    BOOL isLastNotHidden = _hiddenLevelsCount + 1 >= _columnsCount;
    BOOL canNotHide = isLastNotHidden && !_levelIsHidden;
    [_hideSwitch setEnabled:!canNotHide];
    [_leftArrowButton setEnabled:_levelIndex != _totalLevelsCount - 1];
    [_rightArrowButton setEnabled:_levelIndex != (_hasSound ? -1 : 0)];
}

- (void) viewDidLoad
{
	[super viewDidLoad];
    [self.levelNameField setOverrideUserInterfaceStyle:UIUserInterfaceStyleLight];
    self.levelNameField.delegate = self;
    self.levelNameField.layer.borderColor = UIColor.lightGrayColor.CGColor;
    self.levelNameField.layer.borderWidth = 1.0;
    self.levelNameField.layer.cornerRadius = 4.0;
    self.levelNameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.levelNameField.placeholder attributes:@{
        NSForegroundColorAttributeName: [UIColor lightGrayColor]
    }];
    
    [self fill];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
	return UIModalPresentationNone;
}

- (IBAction)leftLevel:(UIButton *)sender
{
    [_delegate didRequestMoveLeftColumnsController:self];
}

- (IBAction)rightLevel:(UIButton *)sender
{
    [_delegate didRequestMoveRightColumnsController:self];
}

//- (IBAction) numColumnsChanged:(id)inSender
//{
//	NSInteger num = [(FBStepperControl *)inSender value];
//
//	NSMutableDictionary* user_info = [NSMutableDictionary dictionary];
//	[user_info setObject:@(num) forKey:kChangeColumnsCountKey];
//	[user_info setObject:@(self.levelIndex + 1) forKey:kChangeColumnsIndexKey];
//    [user_info setObject:@YES forKey:kChangeColumnsAllowedKey];
//
//    [_delegate changeColumnsUserInfo:user_info];
//    [_delegate didRequestLayoutRefreshByColumnsController:self];
//}

/*
- (IBAction)insertButtonAction:(UIButton *)sender {
    [_delegate didInsertLevelForIndex:(_levelIndex + 1)];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}
 */

- (IBAction)addButtonAction:(UIButton *)sender {
    [_delegate didAddedLevelForIndex:(_levelIndex + 1)];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

- (IBAction)deleteButtonAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
    [_delegate didDeleteLevelAtIndex:(_levelIndex + 1)];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

- (IBAction)lockSwitched:(UISwitch *)sender
{
    [_delegate didChangeLevelLockedTo:[sender isOn] atIndex:_levelIndex];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
    [_delegate reselectCurrent];
}

- (IBAction)hideSwitched:(UISwitch *)sender
{
    [_delegate didChangeLevelHiddenTo:[sender isOn] atIndex:_levelIndex];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

- (IBAction)showAllLevels:(UIButton *)sender
{
    [_delegate didRequestShowAllLevels];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    [_delegate didChangeLevelNameTo:textField.text atIndex:_levelIndex];
    [_delegate didRequestLayoutRefreshByColumnsController:self];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [_delegate didChangeLevelNameTo:textField.text atIndex:_levelIndex];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

- (IBAction)levelNameEditingChanged:(UITextField *)sender {
    [_delegate didChangeLevelNameTo:sender.text atIndex:_levelIndex];
    [_delegate didRequestLayoutRefreshByColumnsController:self];
}

@end
