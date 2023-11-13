//
//  FBBrushesController.m
//  FlipPad
//
//  Created by Manton Reece on 1/18/16.
//  Copyright © 2016 DigiCel, Inc. All rights reserved.
//

#import "FBBrushesController.h"
#import "Header-Swift.h"
#import "FBBrushCell.h"
#import "FBConstants.h"

static NSString* const kBrushCellIdentifier = @"BrushCell";

@implementation FBBrushesController

- (instancetype) init
{
	self = [super init];
	if (self) {
	}
	
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setupBrushes];
	[self setupCollectionView];
	
	[self performSelector:@selector(restoreSelectedBrush) withObject:nil afterDelay:0.2];
}

- (void) setupBrushes
{
	self.brushes = [[FBBrush allBrushes] mutableCopy];
}

- (void) setupCollectionView
{
	[self.collectionView registerNib:[UINib nibWithNibName:@"BrushCell" bundle:nil] forCellWithReuseIdentifier:kBrushCellIdentifier];
}

- (void) restoreSelectedBrush
{
	FBBrush* default_brush = [FBBrush currentBrush];
	for (NSInteger i = 0; i < self.brushes.count; i++) {
		FBBrush* b = [self.brushes objectAtIndex:i];
		if ([b.name isEqualToString:default_brush.name]) {
			NSIndexPath* index_path = [NSIndexPath indexPathForItem:i inSection:0];
			[self.collectionView selectItemAtIndexPath:index_path animated:YES scrollPosition:UICollectionViewScrollPositionNone];
			break;
		}
	}
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.brushes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	FBBrush* b = [self.brushes objectAtIndex:indexPath.item];
	
	FBBrushCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBrushCellIdentifier forIndexPath:indexPath];
	[cell setupWithBrush:b];

	return cell;
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (0, 0, 0, 0);
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (75, 75);
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	FBBrush* b = [self.brushes objectAtIndex:indexPath.item];
	[b setDefault];
	[[NSNotificationCenter defaultCenter] postNotificationName:kBrushSelectedNotification object:self userInfo:@{ kBrushSelectedBrushKey: b }];
}

@end
