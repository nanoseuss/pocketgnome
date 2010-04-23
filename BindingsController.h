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
@class ChatController;
@class OffsetController;

#define BindingPrimaryHotkey		@"MULTIACTIONBAR1BUTTON1"
#define BindingPrimaryHotkeyBackup	@"ACTIONBUTTON1"
#define BindingPetAttack			@"PETATTACK"
#define BindingInteractMouseover	@"INTERACTMOUSEOVER"
#define BindingTargetLast			@"TARGETLASTTARGET"
#define BindingTurnLeft				@"TURNLEFT"
#define BindingTurnRight			@"TURNRIGHT"
#define BindingMoveForward			@"MOVEFORWARD"

@interface BindingsController : NSObject {
	
	IBOutlet Controller			*controller;
	IBOutlet BotController		*botController;
	IBOutlet ChatController		*chatController;
	IBOutlet OffsetController	*offsetController;
	
	NSArray *_requiredBindings;
	NSArray *_optionalBindings;

	NSMutableDictionary *_bindings;
	NSMutableDictionary *_keyCodesWithCommands;
	
	NSDictionary *_commandToAscii;
	
	NSMutableDictionary *_bindingsToCodes;		// used w/the defines above
	
	GUID _guid;
}

// this will send the command to the client (use the above 3 keys - defines)
- (BOOL)executeBindingForKey:(NSString*)key;

// just tells us if a binding exists!
- (BOOL)bindingForKeyExists:(NSString*)key;

// only called on bot start
- (void)reloadBindings;

// returns the bar offset (where the spell should be written to)
- (int)castingBarOffset;

// validates that all required key bindings exist! returns an error message
- (NSString*)keyBindingsValid;

@end
