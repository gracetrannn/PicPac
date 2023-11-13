//
//  FBColorPaletteView.m
//  FlipBookPad
//
//  Created by Manton Reece on 5/23/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBColorPaletteView.h"

#import "UIColor_Extras.h"
#import "FBConstants.h"
#import "Header-Swift.h"

@interface FBColorPaletteView ()

@property (strong, nonatomic) UICollectionView* collectionView;

@end

@implementation FBColorPaletteView

- (id) initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (self) {
		_colors = [NSArray array];
        
        UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
        [layout setMinimumInteritemSpacing:0.0];
        [layout setMinimumLineSpacing:0.0];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_collectionView registerClass:[UICollectionViewCell self] forCellWithReuseIdentifier:@"cell"];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        [_collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_collectionView setShowsVerticalScrollIndicator:NO];
        [_collectionView setBackgroundColor:[UIColor whiteColor]];
        
        [self addSubview:_collectionView];
        [[self.leftAnchor constraintEqualToAnchor:_collectionView.leftAnchor] setActive:YES];
        [[self.rightAnchor constraintEqualToAnchor:_collectionView.rightAnchor] setActive:YES];
        [[self.topAnchor constraintEqualToAnchor:_collectionView.topAnchor] setActive:YES];
        [[self.bottomAnchor constraintEqualToAnchor:_collectionView.bottomAnchor] setActive:YES];
	}
	
	return self;
}

- (void)loadColors:(NSArray<FBColor *> *)colors {
    _colors = colors;
    [_collectionView reloadData];
}

- (NSInteger)colorsPerLine
{
    return 8;
}


- (void)tapAtIndexPath:(NSIndexPath*)indexPath
{
    FBColor* color = [_colors objectAtIndex:indexPath.item];

	if (color) {
        [_delegate colorPaletteViewDidSelectColor:color atIndex:indexPath.item];
	}
}

- (void)tapAndHold:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    sender.enabled = NO;
    sender.enabled = YES;
    NSInteger index = [sender.view tag];
    FBColor *color = [_colors objectAtIndex:index];
    if (color) {
        if (_delegate) {
            [_delegate colorPaletteViewDidLongSelectColor:color
                                                  atIndex:index];
        }
    }
}

#pragma mark - CollectionView DataSource & Delegate & DelegateFlowLayout

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_colors count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell setTag:indexPath.item];
    
    UIColor* color = [_colors objectAtIndex:indexPath.item].uiColor;
    [cell setBackgroundColor:color];
    [cell.layer setBorderWidth:0.5];
    [cell.layer setBorderColor:[UIColor.lightGrayColor CGColor]];
    
    UILongPressGestureRecognizer* holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapAndHold:)];
    holdGesture.minimumPressDuration = 1.0;
    [cell addGestureRecognizer:holdGesture];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [cell.layer setBorderWidth:1];
    [cell.layer setBorderColor:[UIColor.blackColor CGColor]];
    
    [self tapAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [cell.layer setBorderWidth:0.5];
    [cell.layer setBorderColor:[UIColor.lightGrayColor CGColor]];
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat lenght = collectionView.bounds.size.width / (CGFloat)[self colorsPerLine];
    return CGSizeMake(lenght, lenght);
}

@end
