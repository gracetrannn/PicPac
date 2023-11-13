//
//  SRImageToolbarItem.h
//  toolbarItemTests
//
//  Created by Alex on 04.03.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#include "TargetConditionals.h"

#if TARGET_OS_MACCATALYST

@import Cocoa;

@class SRToolsItemConfiguration;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(15.0))
@interface SRImageToolbarItem : NSToolbarItem

@property id view;

@property CGSize minSize;
@property CGSize maxSize;

/**
 Returns an instance of NSToolbarItem configured with a colorful image
 Image will be automatically resized to fit in button. Aspect ratio will be preserved
 
 @param itemIdentifier is a toolbar item identifier
 @param image is an image for the toolbar item
 */
+ (instancetype)itemWithIdentifier:(NSString*)itemIdentifier Image:(UIImage*)image;

/**
Returns an instance of NSToolbarItem configured with a colorful image and custom NSPressGestureRecognizer
Image will be automatically resized to fit in button. Aspect ratio will be preserved

@param itemIdentifier is a toolbar item identifier
@param image is an image for the toolbar item
@param target is a target for NSPressGestureRecognizer
@param action is a selector for NSPressGestureRecognizer
*/
+ (instancetype)itemWithIdentifier:(NSString*)itemIdentifier Image:(UIImage*)image Target: (NSObject*)target Action:(SEL)action;

+ (NSToolbarItemGroup*)toolItemWithButtonConfiguration:(SRToolsItemConfiguration*)configuration;

@end

NS_ASSUME_NONNULL_END

#endif
