//
//  ColorfulImageItem.m
//  toolbarItemTests
//
//  Created by Alex on 04.03.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#import "SRImageToolbarItem.h"

#include "TargetConditionals.h"
#include "SRToolsItemConfiguration.h"

#if TARGET_OS_MACCATALYST

@import ObjectiveC.runtime;
@import UIKit;

@implementation SRImageToolbarItem

@dynamic view;
@dynamic minSize;
@dynamic maxSize;

+ (instancetype)itemWithIdentifier:(NSString*)itemIdentifier Image:(UIImage*)image Target: (NSObject*)target Action:(SEL)action
{
    SRImageToolbarItem *toolbarItem = [[self alloc] initWithItemIdentifier:itemIdentifier];
    
    // Button configuration
    id button = [NSClassFromString(@"NSButton") new];
    [button setValue:@11 forKey:@"bezelStyle"];
    [button setValue:[self scaledImageWithImage:image] forKey:@"image"];
    
    id gesture = [NSClassFromString(@"NSPressGestureRecognizer") new];
    [gesture setValue:@1 forKey:@"minimumPressDuration"];
    [gesture setValue:@YES forKey:@"enabled"];
    ///left mouse button to trigger action
    [gesture setValue:@0x1 forKey:@"buttonMask"];
    [gesture addTarget:target action:action];
    [button addGestureRecognizer:gesture];

    // Item configuration
    toolbarItem.view = button;
    
    return toolbarItem;
}

+ (NSToolbarItemGroup*)toolItemWithButtonConfiguration:(SRToolsItemConfiguration*)configuration
{
    SRImageToolbarItem *pencilItem = [self itemWithIdentifier:@"pencil" Image:[self scaledImageWithImage:configuration.pencilImage]];
    SRImageToolbarItem *eraserItem = [self itemWithIdentifier:@"eraser" Image:[self scaledImageWithImage:configuration.eraserImage]];
    SRImageToolbarItem *fillItem = [self itemWithIdentifier:@"fill" Image:[self scaledImageWithImage:configuration.fillImage]];
    SRImageToolbarItem *lassoItem = [self itemWithIdentifier:@"lasso" Image:[self scaledImageWithImage:configuration.lassoImage]];
    
    [pencilItem setLabel:@"Pencil"];
    [eraserItem setLabel:@"Eraser"];
    [fillItem setLabel:@"Fill"];
    [lassoItem setLabel:@"Lasso"];
    
    [pencilItem setAction:configuration.pencilAction.pointerValue];
    [pencilItem setTarget:configuration.target];
    [self addLongPressTarget:configuration.target action:configuration.pencilLongPressAction.pointerValue forView:pencilItem.view];
    
    [eraserItem setAction:configuration.eraserAction.pointerValue];
    [eraserItem setTarget:configuration.target];
    [self addLongPressTarget:configuration.target action:configuration.eraserLongPressAction.pointerValue forView:eraserItem.view];
    
    [fillItem setAction:configuration.fillAction.pointerValue];
    [fillItem setTarget:configuration.target];
    [self addLongPressTarget:configuration.target action:configuration.fillLongPressAction.pointerValue forView:fillItem.view];
    
    [lassoItem setAction:configuration.lassoAction.pointerValue];
    [lassoItem setTarget:configuration.target];
    
    NSToolbarItemGroup* group = [[NSToolbarItemGroup alloc] initWithItemIdentifier:@"tool_group"];
    [group setSelectionMode:NSToolbarItemGroupSelectionModeSelectAny];
    [group setSubitems:@[ pencilItem, eraserItem, fillItem, lassoItem ]];
    
    [group setBordered:YES];
    
    return group;
}

+ (void)addLongPressTarget:(NSObject*)target action:(void*)action forView:(id)view
{
    id gesture = [NSClassFromString(@"NSPressGestureRecognizer") new];
    [gesture setValue:@1 forKey:@"minimumPressDuration"];
    [gesture setValue:@YES forKey:@"enabled"];
    ///left mouse button to trigger action
    [gesture setValue:@0x1 forKey:@"buttonMask"];
    [gesture addTarget:target action:action];
    [view addGestureRecognizer:gesture];
}

+ (instancetype)itemWithIdentifier:(NSString*)itemIdentifier Image:(UIImage*)image
{
    SRImageToolbarItem *toolbarItem = [[self alloc] initWithItemIdentifier:itemIdentifier];
    
    // Button configuration
    id button = [NSClassFromString(@"NSButton") new];
    [button setValue:@11 forKey:@"bezelStyle"];
    [button setValue:[self scaledImageWithImage:image] forKey:@"image"];

    // Item configuration
    toolbarItem.view = button;
    return toolbarItem;
}


+ (UIImage *)scaledImageWithImage:(UIImage *)image
{
    CGFloat ratio = image.size.width / image.size.height;
    CGFloat height = 18.0;
    CGFloat width = ratio * height;
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

#endif
