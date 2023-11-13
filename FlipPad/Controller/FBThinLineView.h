//
//  FBThinLineView.h
//  FlipPad
//
//  Created by Manton Reece on 7/5/15.
//  Copyright (c) 2015 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBThinLineView : UIView

@property (strong, nonatomic) UIColor* lineColor;
@property (assign, nonatomic) CGFloat offset;

- (void) setupLineColor;

@end

@interface FBTopLineView : FBThinLineView
{
}

@end

@interface FBBottomLineView : FBThinLineView
{
}

@end

@interface FBVerticalLineView : FBThinLineView
{
}

@end
