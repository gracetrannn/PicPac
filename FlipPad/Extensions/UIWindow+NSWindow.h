//
//  UIWindow+NSWindow.h
//  FlipPad
//
//  Created by Alex Vihlayew on 12/2/20.
//  Copyright © 2020 Alex. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (PSPDFAdditions)

#if TARGET_OS_UIKITFORMAC

/**
    Finds the NSWindow hosting the UIWindow.
    @note This is a hack. Iterates over all windows to find match. Might fail.
 */
@property (nonatomic, readonly, nullable) id nsWindow;

#endif

@end

NS_ASSUME_NONNULL_END
