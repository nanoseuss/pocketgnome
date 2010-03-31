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

@class Controller;
@class BotController;
@class PlayerDataController;
@class AuraController;
@class ChatController;
@class OffsetController;

@interface MacroController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet PlayerDataController	*playerData;
	IBOutlet AuraController			*auraController;
	IBOutlet ChatController			*chatController;
	IBOutlet OffsetController		*offsetController;
	
	NSArray *_playerMacros;
	NSDictionary *_macroDictionary;
	NSDictionary *_macroMap;
}

@property (readonly) NSArray *playerMacros;

// this will make us do something!
- (void)useMacroOrSendCmd: (NSString*)key;

// check to see if the macro exists + will return the key
- (int)macroIDForCommand: (NSString*)command;

// execute a macro by it's ID
- (void)useMacroByID: (int)macroID;

// only use the macro (it won't send the command)
- (BOOL)useMacro: (NSString*)key;

// use a macro with a parameter
- (BOOL)useMacroWithKey: (NSString*)key andInt:(int)param;

// use a macro
- (BOOL)useMacroWithCommand: (NSString*)macroCommand;

- (NSArray*)macros;

- (NSString*)nameForID:(UInt32)macroID;
/*
 "Swift Flight Form" >>> "Forme de vol rapide"
 "Flight Form" >>> "Forme de vol"
 */
@end
