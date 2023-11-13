//
//  UIWindow+NSWindow.m
//  FlipPad
//
//  Created by Alex Vihlayew on 12/2/20.
//  Copyright © 2020 Alex. All rights reserved.
//

#import "UIWindow+NSWindow.h"

@implementation UIWindow (PSPDFAdditions)

#if TARGET_OS_UIKITFORMAC

- (nullable NSObject *)nsWindow {
    id delegate = [[NSClassFromString(@"NSApplication") sharedApplication] delegate];
    const SEL hostWinSEL = NSSelectorFromString([NSString stringWithFormat:@"_%@Window%@Window:", @"host", @"ForUI"]);
    @try {
        // There's also hostWindowForUIWindow 🤷‍♂️
        id nsWindow = [delegate performSelector:hostWinSEL withObject:self];
            
        // macOS 11.0 changed this to return an UINSWindowProxy
        SEL attachedWin = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"attached", @"Window"]);
        if ([nsWindow respondsToSelector:attachedWin]) {
            nsWindow = [nsWindow valueForKey:NSStringFromSelector(attachedWin)];
        }
        
        return nsWindow;
    } @catch (...) {
        NSLog(@"Failed to get NSWindow for %@.", self);
    }
    return nil;
}

#endif

@end
