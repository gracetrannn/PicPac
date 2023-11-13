//
//  FBDGCSceneDatabase.h
//  FlipPad
//
//  Created by Alex Vihlayew on 11/2/20.
//  Copyright © 2020 Alex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBSceneDatabase.h"

@import ObjcDGC;

NS_ASSUME_NONNULL_BEGIN

@interface FBDGCSceneDatabase : NSObject <FBSceneDatabase>

- (DGC*)getDGC;

@end

NS_ASSUME_NONNULL_END
