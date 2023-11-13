//
//  NSURL_Extras.m
//  FlipPad
//
//  Created by Alex on 23.01.2020.
//  Copyright © 2020 DigiCel. All rights reserved.
//

#import "NSURL_Extras.h"
#import "Header-Swift.h"
#import "Name.h"

@implementation NSURL (Extras)

+ (instancetype)iCloudDriveDocumentsFolder
{
    return [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
}

+ (instancetype)iCloudDocStorage
{
    NSURL* iCloudUrl = [self iCloudDriveDocumentsFolder];
    if (!iCloudUrl) {
        return nil;
    }
    return iCloudUrl;
}

+ (instancetype)localDocStorage
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docs_path = [paths objectAtIndex:0];
    NSURL* docs_url = [NSURL fileURLWithPath:docs_path];
#if TARGET_OS_MACCATALYST
    return [docs_url URLByAppendingPathComponent:kAppName];
#else
    return docs_url;
#endif
}

+ (instancetype)documentsFolder
{
    NSURL* url = [self localDocStorage];
    if ([SettingsBundleHelper storageType] == 1) {
        url = [self iCloudDocStorage];
    }
    if (!url) {
        url = [self localDocStorage];
    }
    return url;
}

@end
