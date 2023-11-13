//
//  SelectedItem.h
//  FlipPad
//
//  Created by Alex on 2/17/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, selectedMode) {
    None = 0,
    Row = 1,
    Item = 2
};

@interface SelectedItem: NSObject

@property (nonatomic, assign) enum selectedMode mode;
@property (assign) NSInteger item;
@property (assign) NSInteger row;

@end
