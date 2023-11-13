//
//  NSString_Extras.h
//  WiiTransfer
//
//  Created by Manton Reece on 12/23/06.
//  Copyright 2006 Riverfold. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_OS_IPHONE
//	#import <UIKit/UIKit.h>
#else
//	#import "UIKitMac.h"
	CGRect CGRectFromString (NSString* inString);
#endif

@interface NSString (Extras)

+ (NSString *) stringForFileSize:(long long)inBytes;
+ (NSString *) stringWithRandomCharactersOfLength:(int)inLength;
+ (NSString *) stringWithUniqueDateIdentifierNamed:(NSString *)inPrefix;
+ (NSString *) rf_stringRegexForLinks;

- (NSArray *) rf_extractLinks;
- (NSString *) rf_urlEncoded;
- (NSString *) rf_urlDecoded;
- (NSString *) rf_entitiesDecoded;

- (BOOL) pathExists;
- (BOOL) pathIsFile;
- (BOOL) pathIsDirectory;
- (BOOL) pathIsZeroLengthFile;
- (void) makeDirectory;
- (void) safelyMakeDirectory;
- (NSString *) stringByReplacingPathExtension:(NSString *)inNewExtension;

- (BOOL) containsSubstring:(NSString *)inSubstring;
- (BOOL) startsWithSubstring:(NSString *)inSubstring;
- (BOOL) endsWithSubstring:(NSString *)inSubstring;
- (NSString *) replaceSubstring:(NSString *)inSubstring withString:(NSString *)inReplacementString;
- (NSString *) replaceSubstring:(NSString *)inSubstring withString:(NSString *)inReplacementString caseInsensitive:(BOOL)inCaseInsensitive;
- (NSString *) stripNonAlphaNumeric;
- (NSRange) rf_rangeOfRegexString:(NSString *)inRegex;
- (NSRange) rf_rangeOfRegexString:(NSString *)inRegex range:(NSRange)inRange;

- (NSString *) stringByTruncatingLength:(int)inMaxChars;
- (NSString *) rf_trimWhitespace;
- (BOOL) rf_isEqualToStringNoCase:(NSString *)inAnotherString;
- (unsigned long long) rf_unsignedLongLongValue;

- (void) rf_showInAlertWithError:(NSError *)inError;
- (void) rf_showInAlertWithMessage:(NSString *)inMessage;

@end

@interface NSAttributedString (Extras)

+ (id) hyperlinkFromString:(NSString *)inString linkRange:(NSRange)inRange;

@end

@interface NSMutableString (Extras)

- (void) rf_clearCharacters;

@end
