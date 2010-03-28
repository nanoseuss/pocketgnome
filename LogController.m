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
/*
		// This is an example of how it could be done for a faster return and without using static values here.
		// NOTE: It also means the button variable names will have to match the log levels to work
			NSString* type = [NSString stringWithFormat:@"log_%s", type_s];
			return([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: type] boolValue]);
*/
		// This works for now
		if (type_s == LOG_CONDITION && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingCondition"] boolValue])
			return NO;
		if (type_s == LOG_RULE && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingRule"] boolValue])
			return NO;	
		if (type_s == LOG_MOVEMENT && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingMovement"] boolValue])
			return NO;
		if (type_s == LOG_DEV && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingDev"] boolValue])
			return NO;
		if (type_s == LOG_WAYPOINT && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingWaypoint"] boolValue])
			return NO;
		if (type_s == LOG_BINDINGS && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingBindings"] boolValue])
			return NO;
		if (type_s == LOG_STATISTICS && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingStatistics"] boolValue])
			return NO;
		if (type_s == LOG_MACRO && ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingMacro"] boolValue])
			return NO;
	} else {
		// These are the types we don't show when Extended Logging isn't enabled
		if (type_s == LOG_CONDITION) return NO;
		if (type_s == LOG_RULE) return NO;
		if (type_s == LOG_MOVEMENT) return NO;
		if (type_s == LOG_DEV) return NO;
		if (type_s == LOG_WAYPOINT) return NO;
		if (type_s == LOG_BINDINGS) return NO;
		if (type_s == LOG_STATISTICS) return NO;
		if (type_s == LOG_MACRO) return NO;
	}

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
