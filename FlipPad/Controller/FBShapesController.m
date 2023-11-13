//
//  FBShapesController.m
//  FlipPad
//
//  Created by Akshay Phulare on 06/03/23.
//  Copyright © 2023 Alex. All rights reserved.
//

#import "FBShapesController.h"
#import "Header-Swift.h"
#import "FBBrushCell.h"
#import "FBShapeCell.h"
#import "FBConstants.h"

static NSString* const kShapeCellIdentifier = @"ShapeCell";

@implementation FBShapesController

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
    
    [self setupShapes];
    [self setupCollectionView];
    
    [self performSelector:@selector(restoreSelectedBrush) withObject:nil afterDelay:0.2];
}

- (void) setupShapes
{
    self.shapes = [[FBShape allShapes] mutableCopy];
}

- (void) setupCollectionView
{

    [self.collectionView registerNib:[UINib nibWithNibName:@"ShapeCell" bundle:nil] forCellWithReuseIdentifier:kShapeCellIdentifier];

}

- (void) restoreSelectedBrush
{
    FBShape* default_brush = [FBShape currentShape];
    for (NSInteger i = 0; i < self.shapes.count; i++) {
        FBShape* b = [self.shapes objectAtIndex:i];
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
    return self.shapes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FBShape* b = [self.shapes objectAtIndex:indexPath.item];
    
    FBShapeCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kShapeCellIdentifier forIndexPath:indexPath];
    [cell setupWithShape:b];

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
    FBShape* b = [self.shapes objectAtIndex:indexPath.item];
    [b setDefault];
    [collectionView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:kShapeSelectedNotification object:self userInfo:@{ kShapeSelectedShapeKey: b }];
}

@end
