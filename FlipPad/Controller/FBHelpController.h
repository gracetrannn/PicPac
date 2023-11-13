//
//  FBHelpController.h
//  FlipPad
//
//  Created by Manton Reece on 5/3/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kHelpPaneXsheet = 0,
    kHelpPaneDrawing,
    kHelpPaneEraser,
    kHelpPaneUndo,
    kHelpPaneLightbox,
    kHelpPanePause,
    kHelpPaneFlip,
    kHelpPanePencil,
    kHelpPaneHD,
    kHelpPaneColor,
    kHelpPaneLevels,
    kHelpPaneLayer
} FBHelpPane;

@interface FBHelpController : UIViewController

- (id) initWithHelpPane:(FBHelpPane)inHelpPane;
+ (void) showHelpPane:(FBHelpPane)helpPane;

@property (retain, nonatomic) IBOutlet UIView* xsheetHelpView;
@property (retain, nonatomic) IBOutlet UIView* documentsHelpView;
@property (weak, nonatomic) IBOutlet UILabel *documentsHelpViewLabel;
@property (retain, nonatomic) IBOutlet UIView* drawingHelpView;

@property (assign, nonatomic) FBHelpPane helpPane;

@end
