//
// LogController.m
// Pocket Gnome
//
// Created by benemorius on 12/17/09.
// Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "LogController.h"


@implementation LogController

+ (BOOL) canLog:(char*)type_s, ...
{
	// Check to see whether or not extended logging is even on
	if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue]) {
		// Extended logging is on so lets see if we're supposed to log the requested type

		// Check to see if we have a setting for it in the interface.
		NSString* type = [NSString stringWithFormat:@"ExtendedLogging%s", type_s];
		if ([[NSUserDefaults standardUserDefaults] objectForKey: type])
			return([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: type] boolValue]);
//			return( [[[NSUserDefaults standardUserDefaults] objectForKey: type] boolValue] );

	} else {
		// These are the types we supress when Extended Logging isn't enabled
		// We'll most likely need to add more to this list as we further the roll out of this logging
		if (type_s == LOG_CONDITION) return NO;
		if (type_s == LOG_RULE) return NO;
		if (type_s == LOG_MOVEMENT) return NO;
		if (type_s == LOG_DEV) return NO;
		if (type_s == LOG_WAYPOINT) return NO;
		if (type_s == LOG_BINDINGS) return NO;
		if (type_s == LOG_STATISTICS) return NO;
		if (type_s == LOG_MACRO) return NO;
		if (type_s == LOG_EVALUATE) return NO;
		if (type_s == LOG_BLACKLIST) return NO;
		if (type_s == LOG_FUNCTION) return NO;
		if (type_s == LOG_MEMORY) return NO;
		if (type_s == LOG_PROCEDURE) return NO;

	}

	// If it's not been supressed let's allow it
	return YES;
	
}

+ (NSString*) log:(char*)type_s, ...
{
	NSString* type = [NSString stringWithFormat:@"%s", type_s];
	va_list args;
	va_start(args, type_s);
	NSString* format = va_arg(args, NSString*);
	NSMutableString* output = [[NSMutableString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	output = [NSString stringWithFormat:@"[%@] %@", type, output];
	return output;
}

@end
