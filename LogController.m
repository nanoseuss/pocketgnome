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

//	NSString* type = [NSString stringWithFormat:@"log_%s", type_s];
// Not logging conditions, remove when we no longer need manual supression.
//	return([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: type] boolValue]);

	
/*
 As a temporary solution I think we should add a button like 'Extended Logging'.
 When it's clicked have it log everything, when it's not.. have it log all but these
 */
	
	if (type_s == LOG_CONDITION && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingCondition"] boolValue]))
		return NO;
	if (type_s == LOG_RULE && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingRule"] boolValue]))
		return NO;	
	if (type_s == LOG_MOVEMENT && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingMovement"] boolValue]))
		return NO;
	if (type_s == LOG_DEV && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingDev"] boolValue]))
		return NO;
	if (type_s == LOG_WAYPOINT && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingWaypoint"] boolValue]))
		return NO;
	if (type_s == LOG_BINDINGS && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingBindings"] boolValue]))
		return NO;
	if (type_s == LOG_STATISTICS && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingStatistics"] boolValue]))
		return NO;
	if (type_s == LOG_MACRO && (![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingEnable"] boolValue] || ![[[NSUserDefaults standardUserDefaults] objectForKey: @"ExtendedLoggingMacro"] boolValue]))
		return NO;
	
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
