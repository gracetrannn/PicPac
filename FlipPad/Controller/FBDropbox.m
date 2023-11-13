//
//  FBDropbox.m
//  FlipPad
//
//  Created by Manton Reece on 4/23/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "FBDropbox.h"

#define kDropboxRevisionsFilename @"DropboxRevisions.plist"

@implementation FBDropbox

+ (NSString *) revisionsPath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docs_folder = [paths objectAtIndex:0];
	return [docs_folder stringByAppendingPathComponent:kDropboxRevisionsFilename];
}

+ (NSString *) lastRevForDropboxPath:(NSString *)inPath
{
	NSString* result = nil;
	NSString* file = [self revisionsPath];
	NSDictionary* revisions = [NSDictionary dictionaryWithContentsOfFile:file];
	if (revisions) {
		result = [revisions objectForKey:inPath];
	}
	
	return result;
}

+ (void) setRev:(NSString *)inRevision forDropboxPath:(NSString *)inPath
{
	NSString* file = [self revisionsPath];
	NSMutableDictionary* revisions = [[NSDictionary dictionaryWithContentsOfFile:file] mutableCopy];
	if (!revisions) {
		revisions = [NSMutableDictionary dictionary];
	}
	[revisions setObject:inRevision forKey:inPath];
	[revisions writeToFile:file atomically:YES];
}

@end
