//
//  FBDropbox.h
//  FlipPad
//
//  Created by Manton Reece on 4/23/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBDropbox : NSObject

+ (NSString *) lastRevForDropboxPath:(NSString *)inPath;
+ (void) setRev:(NSString *)inRevision forDropboxPath:(NSString *)inPath;

@end
