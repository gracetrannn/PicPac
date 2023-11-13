//
//  FBPalettesController.m
//  FlipPad
//
//  Created by Manton Reece on 7/10/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBPalettesController.h"
#import "FBMacros.h"
#import "FBPaletteCell.h"
#import "NSString_Extras.h"
#import "NSURL_Extras.h"
#import "FBColorsController.h"
#import "FBColorPaletteView.h"
#import "FBUtilities.h"
#import "UIColor_Extras.h"
#import "Header-Swift.h"

#define kPaletteCellIdentifier @"PaletteCell"
#define kPaletteFilenameExtension @"plist"
#define kLastPaletteFilenamePrefKey @"LastPaletteFilename"

@implementation FBPalettesController

- (id) init
{
	self = [super initWithNibName:@"Palettes" bundle:nil];
	if (self) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
		self.preferredContentSize = self.view.bounds.size;
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.delegate = self;

		[self setupPalettes];
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationItem.title = @"Palettes";
	self.navigationItem.leftBarButtonItem = [self editButtonItem];
	
	if (FBIsPhone()) {
		self.navigationItem.rightBarButtonItems = @[
			[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(close:)],
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPalette:)]
		];
	} else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPalette:)];
	}
	
	[self.collectionView registerNib:[UINib nibWithNibName:@"PaletteCell" bundle:nil] forCellWithReuseIdentifier:kPaletteCellIdentifier];
}

- (void) viewWillAppear:(BOOL)inAnimated
{
	[super viewWillAppear:inAnimated];

	[self setupPalettes];
	[self.collectionView reloadData];
}

+ (NSString *) palettesFolder
{
    NSString* docs_folder = [NSURL documentsFolder].path;
	NSString* palettes_folder = [docs_folder stringByAppendingPathComponent:@"Palettes"];
	[palettes_folder safelyMakeDirectory];
	return palettes_folder;
}

- (NSString *) pathForDocumentNamed:(NSString *)inName
{
	NSString* filename = [NSString stringWithFormat:@"%@.%@", inName, kPaletteFilenameExtension];
	NSString* palettes_folder = [FBPalettesController palettesFolder];
	return [palettes_folder stringByAppendingPathComponent:filename];
}

- (NSString *) pathForNewUntitledDocument
{
	NSString* s = @"Palette";
	NSString* path = nil;
	BOOL found_unique = NO;
	int num = 1;
	
	do {
		path = [self pathForDocumentNamed:s];
		if ([path pathExists]) {
			num++;
			s = [NSString stringWithFormat:@"Palette %d", num];
		}
		else {
			found_unique = YES;
		}
	}
	while (!found_unique);
	
	return path;
}

- (void) setupPalettes
{
	self.palettes = [FBPalettesController getPallets];
}

+ (NSArray*)getPallets
{
    NSMutableArray* new_palettes = [NSMutableArray array];
    
    NSString* palettes_folder = [self palettesFolder];
    
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:palettes_folder error:nil];
    for (NSString* filename in files) {
        NSString* f = [palettes_folder stringByAppendingPathComponent:filename];
        [new_palettes addObject:f];
    }

    if ([new_palettes count] == 0) {
        NSString* colors_file = [[NSBundle mainBundle] pathForResource:@"SmallPalette" ofType:kPaletteFilenameExtension];
        NSString* default_file = [palettes_folder stringByAppendingPathComponent:@"Default.plist"];
        [[NSFileManager defaultManager] copyItemAtPath:colors_file toPath:default_file error:nil];
        [new_palettes addObject:default_file];
    }
    
    return new_palettes;
}

- (NSArray *) defaultColorsArray
{
	return @[ @"#FFFFFF", @"#C0C0C0", @"#000000" ];
}

- (void) addPalette:(id)inSender
{
	if ([self isAvailable]) {
		NSString* new_path = [self pathForNewUntitledDocument];
		[[self defaultColorsArray] writeToFile:new_path atomically:YES];
		
		NSMutableArray* new_palettes = [self.palettes mutableCopy];
		[new_palettes insertObject:new_path atIndex:0];
		self.palettes = new_palettes;
		
		NSIndexPath* index_path = [NSIndexPath indexPathForItem:0 inSection:0];
		[self.collectionView insertItemsAtIndexPaths:@[ index_path ]];

		[FBUtilities performBlock:^{
			[self openPaletteAtIndex:0 animated:YES];
		} afterDelay:0.5];
	}
}

- (BOOL)isAvailable {
    BOOL result = [FeatureManager.shared checkSubscribtion: 2];
    if (!result) {
        __weak UIViewController *weakController = self.presentingViewController;
        [self dismissViewControllerAnimated:YES
                                 completion:^{
            [UIAlertController showBlockedAlertControllerFor:weakController feature:@"Multiple palettees" level:@"Studio or higher"];
        }];
    }
    return result;
}

- (void) close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

+ (NSString*)getLastPalette
{
    NSString* last_filename = [[NSUserDefaults standardUserDefaults] objectForKey:kLastPaletteFilenamePrefKey];
    if (last_filename) {
        return last_filename;
    } else {
        return [[self getPallets] firstObject];
    }
}

- (void) openLastPaletteAnimated:(BOOL)inAnimated
{
	NSString* last_filename = [[NSUserDefaults standardUserDefaults] objectForKey:kLastPaletteFilenamePrefKey];
	if (last_filename) {
		int i = 0;
		for (NSString* path in self.palettes) {
			if ([[path lastPathComponent] isEqualToString:last_filename]) {
				[self openPaletteAtIndex:i animated:inAnimated];
				return;
			}
			i++;
		}
	}
	else {
		[self openPaletteAtIndex:0 animated:inAnimated];
	}
}

- (void) openPaletteAtIndex:(NSUInteger)inIndex animated:(BOOL)inAnimated
{
	NSString* file_path = [self.palettes objectAtIndex:inIndex];

	FBColorsController* colors_controller = [[FBColorsController alloc] initWithPaletteFile:file_path];
	[self.navigationController pushViewController:colors_controller animated:inAnimated];
	
	[[NSUserDefaults standardUserDefaults] setObject:[file_path lastPathComponent] forKey:kLastPaletteFilenamePrefKey];
}

#pragma mark -

- (void) updateEditingButtonsEnabled:(BOOL)inEnabled
{
	for (UIBarButtonItem* button in self.navigationItem.rightBarButtonItems) {
		button.enabled = inEnabled;
	}
}

- (void) setEditing:(BOOL)inEditing animated:(BOOL)inAnimated
{
	[super setEditing:inEditing animated:inAnimated];
	
	if (inEditing) {
		self.navigationItem.rightBarButtonItems = @[
			[[UIBarButtonItem alloc] initWithTitle:@"Rename" style:UIBarButtonItemStylePlain target:self action:@selector(renamePalette:)],
			[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deletePalette:)]
		];
		
		[self updateEditingButtonsEnabled:NO];
	}
	else {
		if (FBIsPhone()) {
			self.navigationItem.rightBarButtonItems = @[
				[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(close:)],
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPalette:)]
			];
		}
		else {
			self.navigationItem.rightBarButtonItems = @[
				[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPalette:)]
			];
		}
	}
}

- (void) renamePalette:(id)inSender
{
	NSIndexPath* selected = [[self.collectionView indexPathsForSelectedItems] lastObject];
	if (selected) {
		NSString* file_path = [self.palettes objectAtIndex:selected.item];
		NSString* name = [[file_path lastPathComponent] stringByDeletingPathExtension];
		
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Rename Palette" message:@"Enter a new name for this color palette:" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = name;
        }];
           
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString* s = [[alert textFields][0] text];
            if ([s length] > 0) {
                NSString* old_path = [self.palettes objectAtIndex:selected.item];
                NSString* new_path = [[[old_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:s] stringByAppendingPathExtension:kPaletteFilenameExtension];
                NSError* error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:old_path toPath:new_path error:&error];
                if (!error) {
                    [FBUtilities performBlock:^{
                        // give popover enough time to resize after keyboard is hidden
                        [self setupPalettes];
                        [self.collectionView reloadData];
                    } afterDelay:1.0];
                }
                else {
                    [@"Could not rename palette" rf_showInAlertWithError:error];
                }
            }
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction: confirmAction];
        [alert addAction: cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
	}
}

- (void) deletePalette:(id)inSender
{
	NSIndexPath* selected = [[self.collectionView indexPathsForSelectedItems] lastObject];
	if (selected) {
		[self.collectionView deselectItemAtIndexPath:selected animated:NO];
		[self updateEditingButtonsEnabled:NO];
		
		NSString* file_path = [self.palettes objectAtIndex:selected.item];
		[[NSFileManager defaultManager] removeItemAtPath:file_path error:nil];

		[self setupPalettes];
		[self.collectionView deleteItemsAtIndexPaths:@[ selected ]];
	}
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)inCollectionView numberOfItemsInSection:(NSInteger)inSection
{
	return [self.palettes count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)inCollectionView cellForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
	FBPaletteCell* cell = [inCollectionView dequeueReusableCellWithReuseIdentifier:kPaletteCellIdentifier forIndexPath:inIndexPath];

	NSString* file_path = [self.palettes objectAtIndex:inIndexPath.item];
	
	cell.nameField.text = [[file_path lastPathComponent] stringByDeletingPathExtension];
    
    NSMutableArray<FBColor*>* colors = [NSMutableArray new];
    NSArray* colorHexArray = [NSArray arrayWithContentsOfFile:file_path];
    for (NSString* hex in colorHexArray) {
        [colors addObject:[[FBColor alloc] initWithUIColor:[UIColor fb_colorFromString:hex]]];
    }
    
	[cell.colorsView loadColors:colors];
	
	return cell;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout insetForSectionAtIndex:(NSInteger)inSection
{
	return UIEdgeInsetsMake (5.0, 2.0, 5.0, 2.0);
}

- (CGSize) collectionView:(UICollectionView *)inCollectionView layout:(UICollectionViewLayout *)inCollectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)inIndexPath
{
	return CGSizeMake (90.0, 100.0);
}

- (void) collectionView:(UICollectionView *)inCollectionView didSelectItemAtIndexPath:(NSIndexPath *)inIndexPath
{
	if ([self isEditing]) {
		FBPaletteCell* cell = (FBPaletteCell *)[inCollectionView cellForItemAtIndexPath:inIndexPath];
		cell.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
		[self updateEditingButtonsEnabled:YES];
	}
	else {
		[self openPaletteAtIndex:inIndexPath.item animated:YES];
	}
}

- (void) collectionView:(UICollectionView *)inCollectionView didDeselectItemAtIndexPath:(NSIndexPath *)inIndexPath
{
	if ([self isEditing]) {
		FBPaletteCell* cell = (FBPaletteCell *)[inCollectionView cellForItemAtIndexPath:inIndexPath];
		cell.backgroundColor = [UIColor clearColor];
		[self updateEditingButtonsEnabled:NO];
	}
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

@end
