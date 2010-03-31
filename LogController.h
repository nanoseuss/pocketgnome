/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import <Cocoa/Cocoa.h>
#define log(...) if([LogController canLog:__VA_ARGS__]) PGLog(@"%@", [LogController log: __VA_ARGS__]);

#define LOG_FUNCTION				"function"
#define LOG_DEV						"dev"
#define LOG_DEV1					"dev1"
#define LOG_DEV2					"dev2"
#define LOG_TARGET					"target"
#define LOG_MOVEMENT_CORRECTION		"movement_correction"
#define LOG_MOVEMENT				"movement"
#define LOG_RULE					"rule"
#define LOG_CONDITION				"condition"
#define LOG_BEHAVIOR				"behavior"
#define LOG_LOOT					"loot"
#define LOG_HEAL					"heal"
#define LOG_COMBAT					"combat"
#define LOG_GENERAL					"general"
#define LOG_MACRO					"macro"
#define LOG_CHAT					"chat"
#define LOG_ERROR					"error"
#define LOG_PVP						"pvp"
#define LOG_NODE					"node"
#define LOG_FISHING					"fishing"
#define LOG_AFK						"afk"
#define LOG_MEMORY					"memory"
#define LOG_BLACKLIST				"blacklist"
#define LOG_WAYPOINT				"waypoint"
#define LOG_POSITION				"position"
#define LOG_ACTION					"action"
#define LOG_PARTY					"party"

@interface LogController : NSObject {
	
}

+ (BOOL) canLog:(char*)type_s, ...;
+ (NSString*) log:(char*)type_s, ...;

@end