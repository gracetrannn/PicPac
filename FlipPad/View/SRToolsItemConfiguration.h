//
//  SRToolsItemConfiguration.h
//  FlipPad
//
//  Created by Alex on 04.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRToolsItemConfiguration : NSObject

@property (strong, nonatomic) id target;

@property (strong, nonatomic) UIImage* pencilImage;
@property (strong, nonatomic) UIImage* eraserImage;
@property (strong, nonatomic) UIImage* fillImage;
@property (strong, nonatomic) UIImage* lassoImage;

@property (strong, nonatomic) NSValue* pencilAction;
@property (strong, nonatomic) NSValue* pencilLongPressAction;

@property (strong, nonatomic) NSValue* eraserAction;
@property (strong, nonatomic) NSValue* eraserLongPressAction;

@property (strong, nonatomic) NSValue* fillAction;
@property (strong, nonatomic) NSValue* fillLongPressAction;

@property (strong, nonatomic) NSValue* lassoAction;

@end

NS_ASSUME_NONNULL_END
