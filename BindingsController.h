//
//  BindingsController.h
//  Pocket Gnome
//
//  Created by Josh on 1/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class ChatController;
@class OffsetController;

#define BindingPrimaryHotkey		@"BindingPrimaryHotkey"
#define BindingPetAttack			@"BindingPetAttack"
#define BindingInteractMouseover	@"BindingInteractMouseover"

@interface BindingsController : NSObject {
	
	IBOutlet Controller			*controller;
	IBOutlet ChatController		*chatController;
	IBOutlet OffsetController	*offsetController;

	NSMutableDictionary *_bindings;
	NSMutableDictionary *_keyCodesWithCommands;
	
	NSDictionary *_commandToAscii;
	
	// key bindings
	int _primaryActionOffset;
	int _primaryActionCode;
	int _primaryActionModifier;
	int _petAttackActionOffset;
	int _petAttackActionCode;
	int _petAttackActionModifier;
	int _interactMouseoverActionOffset;
	int _interactMouseoverActionCode;
	int _interactMouseoverActionModifier;
	
	NSMutableDictionary *_bindingsToCodes;		// used w/the defines above
	
	GUID _guid;
}

// this will send the command to the client (use the above 3 keys - defines)
- (BOOL)executeBindingForKey:(NSString*)key;

// returns the bar offset (where the spell should be written to)
- (int)barOffsetForKey:(NSString*)key;

// just tells us if a binding exists!
- (BOOL)bindingForKeyExists:(NSString*)key;

// only called on bot start
- (void)reloadBindings;

@end
