//
//  FBInfoController.m
//  FlipPad
//
//  Created by Manton Reece on 7/12/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBInfoController.h"

#import "FBResolutionCell.h"
#import "FBConstants.h"
#import "FBMacros.h"
#import "FBHelpController.h"
#import "FBSceneController.h"
#import "FBXsheetController.h"
#import "Name.h"
#import "Header-Swift.h"

#define kResolutionCellIdentifier @"ResolutionCell"

@interface FBInfoController ()

@property (weak, nonatomic) IBOutlet RadioButton *verticalToolbarButton;
@property (weak, nonatomic) IBOutlet RadioButton *xsheetAlwaysVisible;
@property (weak, nonatomic) IBOutlet RadioButton *xsheetLeft;
@property (weak, nonatomic) IBOutlet RadioButton *xsheetRight;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UILabel *showHideScenesLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showHideScenesSwitch;
@property (weak, nonatomic) IBOutlet UIView *closeButtonView;


@property (assign, nonatomic) BOOL isSpeed;

@end

@implementation FBInfoController

- (id) init
{
    self = [super initWithNibName:@"Info" bundle:nil];
    if (self) {
        _isSpeed = NO;
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            self.modalPresentationStyle = UIModalPresentationFullScreen;
        } else {
            self.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverPresentationController.delegate = self;
        }
    }
    return self;
}

- (id) initForSpeed
{
    self = [super initWithNibName:@"Speed" bundle:nil];
    if (self) {
        _isSpeed = YES;
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            self.modalPresentationStyle = UIModalPresentationFullScreen;
        } else {
            self.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverPresentationController.delegate = self;
        }
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self setupResolutions];
    [self setupSpeed];
    [self setupInfo];
    [self setupCollectionView];
    [self setupHelp];
    
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        [self.closeButtonView setHidden: YES];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelpNotification:) name:kShowHelpNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHiddenResolutions) name:kShowHiddenResolutionsNotification object:nil];
    
#if FLIPBOOK
    [self.appNameLabel setText:@"DigiCel FlipBook"];
#endif
    
}

- (void) viewWillAppear:(BOOL)inAnimated
{
    [super viewWillAppear:inAnimated];
    _verticalToolbarButton.isChecked = SettingsBundleHelper.verticalToolbar;
    _xsheetLeft.isChecked = !SettingsBundleHelper.xsheetRightSide;
    _xsheetRight.isChecked = SettingsBundleHelper.xsheetRightSide;
    
    [self.continueButton setTitleColor: [UIColor.systemBlueColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    [self.continueButton setEnabled:NO];
    
    [self.showHideScenesSwitch setOn: [SettingsBundleHelper resolutionsCheatVisible]];

//    _xsheetAlwaysVisible.isChecked = SettingsBundleHelper.xsheetAlwaysVisible;
//    NSString* current_resolution = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentResolutionPrefKey];
//    for (NSInteger i = 0; i < [self.resolutions count]; i++) {
//        NSString* resolution_s = [self.resolutions objectAtIndex:i];
//        if ([current_resolution isEqualToString:resolution_s]) {
//            NSIndexPath* index_path = [NSIndexPath indexPathForRow:i inSection:0];
//            [self.resolutionCollectionView selectItemAtIndexPath:index_path animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
//            break;
//        }
//    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_sceneController) {
        [[_sceneController xsheetController] setupSoundWave];
    }
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}


- (void) setupSpeed
{
    NSInteger fps;
    if (_isSpeed) {
        fps = _sceneController.document.fps;
    } else {
        fps = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentFramesPerSecondPrefKey];
    }
    [self updateFieldWithFPS:fps];
}

- (void)setupInfo {
    
    BOOL isUpgraded = NO;
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *name = @"DigiCel FlipPad";
    NSString *suffix = isUpgraded ? @" (Pro)" : @"";
    CGSize size = _sceneController.document.resolutionSize;
    _resolutionField.text = [NSString stringWithFormat:@"%0.0f x %0.0f", size.width, size.height];
    _productLabel.text = [NSString stringWithFormat:@"%@%@", name, suffix];
    _versionField.text = appVersion;
    _buildField.text = [NSString stringWithFormat:@"(%@)", buildNumber];
}

- (void) setupCollectionView
{
    if (self.resolutionCollectionView) {
        [self.resolutionCollectionView registerNib:[UINib nibWithNibName:@"ResolutionCell" bundle:nil] forCellWithReuseIdentifier:kResolutionCellIdentifier];
    }
}

- (void) updateFieldWithFPS:(NSInteger)inFPS
{
    if (self.fpsField) {
        self.fpsField.text = [NSString stringWithFormat:@"%ld", (long)inFPS];
        [self.fpsSlider setValue:inFPS];
    }
}

- (void) setupResolutions
{
    NSString* resolutions_file = [[NSBundle mainBundle] pathForResource:@"Resolutions" ofType:@"plist"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT SELF CONTAINS '600' AND NOT SELF CONTAINS '640'"];
    
    if (SettingsBundleHelper.resolutionsCheatVisible == NO) {
        self.resolutions = [[NSArray arrayWithContentsOfFile:resolutions_file] filteredArrayUsingPredicate:(predicate)] ;
    } else {
        self.resolutions = [NSArray arrayWithContentsOfFile:resolutions_file] ;
    }
}

- (void) showHiddenResolutions
{
    SettingsBundleHelper.resolutionsCheatVisible = [SettingsBundleHelper resolutionsCheatVisible] == YES ? NO : YES;
    
    [self setupResolutions];
    [_resolutionCollectionView reloadData];
}

- (IBAction)switchChanged:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowHiddenResolutionsNotification object:self];
}

#pragma mark - IB ACTIONS

- (IBAction) fpsChanged:(id)inSender
{
    NSInteger fps = [self.fpsSlider value];
    [[NSUserDefaults standardUserDefaults] setInteger:fps forKey:kCurrentFramesPerSecondPrefKey];
    [self updateFieldWithFPS:fps];
}

- (IBAction) continueNewScene:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddNewSceneNotification object:self];
}

- (IBAction) pressCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL) isLowResolutionAtIndexPath:(NSIndexPath *)inIndexPath
{
    NSString* resolution_s = [self.resolutions objectAtIndex:inIndexPath.row];
    NSInteger height = [[[resolution_s componentsSeparatedByString:@"x"] lastObject] integerValue];
    return (height < 720);
}

#pragma mark -

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
        if ([character isEqualToString:@"l"] && isCommand && isShift) { // Cheat-code: show hidden resolutions
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowHiddenResolutionsNotification object:self];
        }
    }
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)inCollectionView numberOfItemsInSection:(NSInteger)inSection
{
    return [self.resolutions count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)inCollectionView cellForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    FBResolutionCell* cell = [inCollectionView dequeueReusableCellWithReuseIdentifier:kResolutionCellIdentifier forIndexPath:inIndexPath];
    
    NSString* resolution_s = [self.resolutions objectAtIndex:inIndexPath.row];
    cell.resolutionTitle.text = resolution_s;
    
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout*)inLayout sizeForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    if (FBIsPhone()) {
        return CGSizeMake (120.0, 50.0);
    }
    else {
        return CGSizeMake (120.0, 100.0);
    }
}

- (UIEdgeInsets) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout insetForSectionAtIndex:(NSInteger)inSection
{
    return UIEdgeInsetsMake (20.0, 20.0, 20.0, 20.0);
}

- (CGFloat) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)inSection
{
    return 10.0;
}

- (CGFloat) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout*)inCollectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)inSection
{
    return 10.0;
}

- (BOOL) collectionView:(UICollectionView *)inCollectionView shouldSelectItemAtIndexPath:(NSIndexPath *)inIndexPath
{
    
    BOOL isUpgraded = [SettingsBundleHelper resolutionsCheatVisible] == NO
    ?
    ( ((inIndexPath.row <= 0) && [FeatureManager.shared checkSubscribtion: 0])  ||   // checking for FREE
      ((inIndexPath.row <= 1) && [FeatureManager.shared checkSubscribtion: 2])  ||   // checking for STUDIO
      ((inIndexPath.row <= 2) && [FeatureManager.shared checkSubscribtion: 3]) )     // checking for PRO
    :
    ( ((inIndexPath.row <= 1) && [FeatureManager.shared checkSubscribtion: 0])  ||   // checking for FREE
      ((inIndexPath.row <= 3) && [FeatureManager.shared checkSubscribtion: 2])  ||   // checking for STUDIO
      ((inIndexPath.row <= 4) && [FeatureManager.shared checkSubscribtion: 3]) )     // checking for PRO

    ;

    if (isUpgraded == NO)
    {
        [UIAlertController showBlockedAlertControllerFor:self feature:@"This resolution" level: @""];
        
    }
    return (isUpgraded);
}

- (void) collectionView:(UICollectionView *)inCollectionView didSelectItemAtIndexPath:(NSIndexPath *)inIndexPath

{
    [self.continueButton setEnabled:YES];

        NSString* resolution_s = [self.resolutions objectAtIndex:inIndexPath.row];
        [[NSUserDefaults standardUserDefaults] setObject:resolution_s forKey:kCurrentResolutionPrefKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSceneResolutionChangedNotification object:self];
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
        self.helpViewHeightConstrnt.constant = 100;
        [UIView animateWithDuration:0.3 animations:^{
            self.helpView.alpha = 1.0;
            self.helpScrollView.alpha = 1.0;
            self.helpScrollViewBackground.alpha = 1.0;
            [self.view layoutIfNeeded];
        }];
    }
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
    self.helpViewHeightConstrnt.constant = 0;
    [self.view layoutIfNeeded];
}

- (IBAction) hideHelp:(id)inSender
{
    self.helpViewHeightConstrnt.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.helpView.alpha = 0.0;
        self.helpScrollView.alpha = 0.0;
        self.helpScrollViewBackground.alpha = 1.0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.helpView.hidden = YES;
        self.helpScrollView.hidden = YES;
        self.helpScrollViewBackground.hidden = YES;
    }];
}

- (IBAction)verticalToolbarAction:(RadioButton *)sender {
    SettingsBundleHelper.verticalToolbar = sender.isChecked;
}

- (IBAction) sideSelectionAction: (RadioButton *)sender {
    SettingsBundleHelper.xsheetRightSide = sender.tag == 2;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)xsheetAlwaysVisibleAction:(RadioButton *)sender {
//    SettingsBundleHelper.xsheetAlwaysVisible = sender.isChecked;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
