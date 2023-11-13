//
//  NSURL_Extras.h
//  FlipPad
//
//  Created by Alex on 23.01.2020.
//  Copyright © 2020 DigiCel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSURL (Extras)

+ (instancetype)iCloudDriveDocumentsFolder;

+ (instancetype)documentsFolder;

+ (instancetype)iCloudDocStorage;

+ (instancetype)localDocStorage;

@end
