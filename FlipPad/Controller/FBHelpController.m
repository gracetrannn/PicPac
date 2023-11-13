//
//  FBHelpController.m
//  FlipPad
//
//  Created by Manton Reece on 5/3/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "FBHelpController.h"

#import "FBConstants.h"

@implementation FBHelpController

- (id) initWithHelpPane:(FBHelpPane)inHelpPane
{
    self = [super initWithNibName:@"Help" bundle:nil];
    if (self) {
        self.helpPane = inHelpPane;
    }
    
    return self;
}

+ (void) showHelpPane:(FBHelpPane)helpPane
{
//    if (FBIsPhone()) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:kShowHelpNotification object:self userInfo:@{ kShowHelpPaneKey: @(helpPane) }];
//    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];

#if FLIPBOOK
    if (_documentsHelpViewLabel) {
        [_documentsHelpViewLabel setText:@"Welcome to FlipBook! Start by creating a new scene."];
    }
#endif
    
    UIView* use_view = nil;
    if (self.helpPane == kHelpPaneXsheet) {
        use_view = self.xsheetHelpView;
    }
//    else if (self.helpPane == kHelpPaneDocuments) {
//        use_view = self.documentsHelpView;
//    }
    else if (self.helpPane == kHelpPaneDrawing) {
        use_view = self.drawingHelpView;
    }

    [self.view addSubview:use_view];
    [self.view setBackgroundColor:use_view.backgroundColor];
    [self.view setBounds:use_view.bounds];

    self.preferredContentSize = self.view.bounds.size;
}

@end
