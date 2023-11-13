//
//  NSString_Extras.m
//  WiiTransfer
//
//  Created by Manton Reece on 12/23/06.
//  Copyright 2006 Riverfold. All rights reserved.
//

#import "NSString_Extras.h"

#if !TARGET_OS_IPHONE
	#import "RegexKitLite.h"

	CGRect CGRectFromString (NSString* inString)
	{
		// FIXME: implement
		return CGRectZero;
	}
#endif

@implementation NSString (Extras)

//@implementation NSDate (FormattedStrings)
//- (NSString *)dateStringWithStyle:(NSDateFormatterStyle)style
//{
//    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
//    [dateFormatter setDateStyle:style];
//    return [dateFormatter stringFromDate:self];
//}
//@end

+ (NSString *) stringForFileSize:(long long)inBytes
{
	const float kBytesPerMegabyte = 1024.0 * 1024.0;
	const float kBytesPerGigabyte = kBytesPerMegabyte * 1024.0;
	float bytes_mb = inBytes / kBytesPerMegabyte;
	float bytes_gb = inBytes / kBytesPerGigabyte;
	NSString* s;
	if (bytes_mb < 1000.0) {
		s = [NSString stringWithFormat:@"%.0f MB", bytes_mb];
	}
	else {
		s = [NSString stringWithFormat:@"%.2f GB", bytes_gb];
	}
	
	return s;	
}

+ (NSString *) stringWithRandomCharactersOfLength:(int)inLength
{
	static BOOL sInitRandom = NO;
	if (!sInitRandom) {
		srandom ([[NSDate date] timeIntervalSinceReferenceDate]);
		sInitRandom = YES;
	}

	NSMutableString* s = [[NSMutableString alloc] initWithCapacity:inLength];
	char kRandomChars[] = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 
									'T', 'U', 'V', 'W', 'X', 'Y', 'Z' };
	for (int i = 0; i < inLength; i++) {
		int picked = random() % sizeof (kRandomChars);
		[s appendFormat:@"%c", kRandomChars[picked]];
	}
	
	return s;
}

+ (NSString *) stringWithUniqueDateIdentifierNamed:(NSString *)inPrefix
{
	NSString* random_extras = [NSString stringWithRandomCharactersOfLength:4];
	NSString* desc = [[NSDate date] description];
	desc = [desc replaceSubstring:@"/" withString:@""];
	desc = [desc replaceSubstring:@":" withString:@""];
	desc = [desc replaceSubstring:@"-" withString:@""];
	desc = [desc replaceSubstring:@" " withString:@""];
	return [NSString stringWithFormat:@"%@-%@-%@", inPrefix, desc, random_extras];
}

+ (NSString *) rf_stringRegexForLinks
{
//	NSString* regex = @"https?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?"; // simple
	NSString* regex = @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"; // via Daring Fireball
	return regex;
}

- (NSArray *) rf_extractLinks
{
	NSMutableArray* result = nil;
	NSRange current_range = NSMakeRange (0, [self length]);
	NSRange found_range;
	do {
		found_range = [self rf_rangeOfRegexString:[NSString rf_stringRegexForLinks] range:current_range];
		if (found_range.length > 0) {
			if (!result) {
				result = [[NSMutableArray alloc] init];
			}
			NSString* found_url = [self substringWithRange:found_range];
			[result addObject:found_url];
			current_range.location = found_range.location + found_range.length;
			current_range.length = [self length] - current_range.location;
		}
	}
	while (found_range.length > 0);
	
	return result;
}

- (NSString *) rf_urlEncoded
{
    NSCharacterSet * queryKVSet = [NSCharacterSet
                                   characterSetWithCharactersInString: @"!*'();:@&=+$,/?%#[]"].invertedSet;
    NSString* newValue = self;
    newValue = [newValue stringByAddingPercentEncodingWithAllowedCharacters: queryKVSet];
    
	if (newValue) {
		return newValue;
	} else {
		return self;
	}
}

- (NSString *) rf_urlDecoded
{
	CFStringRef cf = CFURLCreateStringByReplacingPercentEscapes (NULL, (CFStringRef)self, CFSTR(""));
	if (cf) {
		NSString* s = (__bridge_transfer NSString *)cf;
		return s;
	}
	else {
		return self;
	}
}

- (NSString *) rf_entitiesDecoded
{
	NSString* s = self;
	s = [s replaceSubstring:@"&lt;" withString:@"<"];
	s = [s replaceSubstring:@"&gt;" withString:@">"];
	s = [s replaceSubstring:@"&quot;" withString:@"\""];
	s = [s replaceSubstring:@"&amp;" withString:@"&"];
	return s;
}

#pragma mark -

- (BOOL) pathExists
{
	NSFileManager* fm = [NSFileManager defaultManager];
	return [fm fileExistsAtPath:self];
}

- (BOOL) pathIsFile
{
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL is_dir;
	return ([fm fileExistsAtPath:self isDirectory:&is_dir] && (!is_dir));
}

- (BOOL) pathIsDirectory
{
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL is_dir;
	return ([fm fileExistsAtPath:self isDirectory:&is_dir] && (is_dir));
}

- (BOOL) pathIsZeroLengthFile
{
	if ([self pathIsFile]) {
		NSFileManager* fm = [NSFileManager defaultManager];
		NSDictionary* attrs = [fm attributesOfItemAtPath:self error:nil];
		int sz = [[attrs objectForKey:NSFileSize] intValue];
		if (sz == 0) {
			return YES;
		}
	}
	
	return NO;
}

- (void) makeDirectory
{
	NSFileManager* fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:self withIntermediateDirectories:NO attributes:nil error:nil];
}

- (void) safelyMakeDirectory
{
	if (![self pathExists]) {
		NSFileManager* fm = [NSFileManager defaultManager];
		[fm createDirectoryAtPath:self withIntermediateDirectories:NO attributes:nil error:nil];
	}
}

- (NSString *) stringByReplacingPathExtension:(NSString *)inNewExtension
{
	return [[self stringByDeletingPathExtension] stringByAppendingPathExtension:inNewExtension];
}

#pragma mark -

- (BOOL) containsSubstring:(NSString *)inSubstring
{
	return ([self rangeOfString:inSubstring].length > 0);
}

- (BOOL) startsWithSubstring:(NSString *)inSubstring
{
	NSRange r = [self rangeOfString:inSubstring];
	return (r.length > 0) && (r.location == 0);
}

- (BOOL) endsWithSubstring:(NSString *)inSubstring
{
	NSRange r = [self rangeOfString:inSubstring];
	return (r.length > 0) && (r.location == ([self length] - [inSubstring length]));
}

- (NSString *) replaceSubstring:(NSString *)inSubstring withString:(NSString *)inReplacementString
{
	return [self replaceSubstring:inSubstring withString:inReplacementString caseInsensitive:YES];
}

- (NSString *) replaceSubstring:(NSString *)inSubstring withString:(NSString *)inReplacementString caseInsensitive:(BOOL)inCaseInsensitive
{
	int options;
	if (inCaseInsensitive) {
		options = NSCaseInsensitiveSearch;
	}
	else {
		options = NSLiteralSearch;
	}
	NSMutableString* mut = [self mutableCopy];
	[mut replaceOccurrencesOfString:inSubstring withString:inReplacementString options:options range:NSMakeRange (0, [self length])];
	return mut;
}

- (NSString *) stripNonAlphaNumeric
{
	NSString* result = self;
	result = [result replaceSubstring:@"?" withString:@""];
	result = [result replaceSubstring:@"#" withString:@""];
	result = [result replaceSubstring:@"-" withString:@""];
	return result;
}

- (NSRange) rf_rangeOfRegexString:(NSString *)inRegex
{
#if TARGET_OS_IPHONE
	return [self rangeOfString:inRegex options:NSRegularExpressionSearch];	
#else
	return [self rangeOfRegex:inRegex];
#endif
}

- (NSRange) rf_rangeOfRegexString:(NSString *)inRegex range:(NSRange)inRange
{
#if TARGET_OS_IPHONE
	return [self rangeOfString:inRegex options:NSRegularExpressionSearch range:inRange];
#else
	return [self rangeOfRegex:inRegex inRange:inRange];
#endif
}

#pragma mark -

- (NSString *) stringByTruncatingLength:(int)inMaxChars
{
	NSString* s;
	NSUInteger len = [self length];
	if (len > inMaxChars) {
		s = [self substringToIndex:(inMaxChars - 3)];
		s = [s stringByAppendingString:@"..."];
	}
	else {
		s = self;
	}
	
	return s;
}

- (NSString *) rf_trimWhitespace
{
	if ([self length] > 0) {
		CFMutableStringRef s = CFStringCreateMutableCopy (kCFAllocatorDefault, 0, (CFStringRef)self);
		CFStringTrimWhitespace (s);

		NSMutableString* result = (__bridge_transfer NSMutableString *)s;
		return result;
	}
	else {
		return self;
	}
}

- (BOOL) rf_isEqualToStringNoCase:(NSString *)inAnotherString
{
	NSString* s1 = [self lowercaseString];
	NSString* s2 = [inAnotherString lowercaseString];
	return [s1 isEqualToString:s2];
}

- (unsigned long long) rf_unsignedLongLongValue
{
	unsigned long long val = strtoull ([self UTF8String], NULL, 0);
	return val;
}

- (void) rf_showInAlertWithError:(NSError *)inError
{
	NSString* msg = @"";
	if (inError) {
		msg = [inError localizedDescription];
	}
	[self rf_showInAlertWithMessage:msg];
}

- (void) rf_showInAlertWithMessage:(NSString *)inMessage
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self message: inMessage preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            //button click event
                        }];
    [alert addAction:ok];
    id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
    }
    if([rootViewController isKindOfClass:[UITabBarController class]])
    {
        rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
    }
    //...
    [rootViewController presentViewController: alert animated:YES completion:nil];
}

@end

#pragma mark -

@implementation NSAttributedString (Extras)

+(id) hyperlinkFromString:(NSString*)inString linkRange:(NSRange)inRange
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:inString];

//    [attrString beginEditing];
////    [attrString addAttribute:NSLinkAttributeName value:[inURL absoluteString] range:inRange];
//
//    // make the text appear in blue
//    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:inRange];
//
//    // next make the text appear with an underline
//    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:inRange];
//
//    [attrString endEditing];

    return attrString;
}

@end

#pragma mark -

@implementation NSMutableString (Extras)

- (void) rf_clearCharacters
{
	NSRange r = NSMakeRange (0, [self length]);
	[self deleteCharactersInRange:r];
}

@end
