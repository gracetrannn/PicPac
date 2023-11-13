//
//  UIViewController.m
//  FlipPad
//
//  Created by Manton Reece on 3/27/18.
//  Copyright © 2018 DigiCel, Inc. All rights reserved.
//

#import "UIViewController_Extras.h"
#import "Name.h"

@implementation UIViewController (Extras)

- (BOOL) prefersHomeIndicatorAutoHidden
{
	return YES;
}

#if TARGET_OS_MACCATALYST
- (void)setDrawingToolbarDocName:(NSString*)docName
{
    UIWindowScene* appScene = (UIWindowScene*)[UIApplication.sharedApplication.connectedScenes anyObject];
    [appScene.titlebar setTitleVisibility:UITitlebarTitleVisibilityVisible];
    [appScene.titlebar setToolbar:nil];
    [appScene setTitle:[[kAppName stringByAppendingString:@" - "] stringByAppendingString:docName]];
}

- (void)setToolbar:(NSToolbar*)toolbar isTitleVisible:(BOOL)isVisible;
{
    UIWindowScene* appScene = (UIWindowScene*)[UIApplication.sharedApplication.connectedScenes anyObject];
    [appScene.titlebar setTitleVisibility:(isVisible ? UITitlebarTitleVisibilityVisible : UITitlebarTitleVisibilityHidden)];
    if (@available(macCatalyst 14.0, *)) {
        [appScene.titlebar setToolbarStyle:UITitlebarToolbarStyleExpanded];
    }
    [appScene.titlebar setToolbar:toolbar];
}
#endif

- (void)showErrorWithMessage:(NSString *)message {
    [self showAlertWithTitle:@"Error"
                  andMessage:message];
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Ok"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil];
    [alertController addAction:alertAction];
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

@end
