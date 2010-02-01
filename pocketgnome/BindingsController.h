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

#define BindingPrimaryHotkey		@"BindingPrimaryHotkey"
#define BindingPetAttack			@"BindingPetAttack"
#define BindingInteractMouseover	@"BindingInteractMouseover"

@interface BindingsController : NSObject {
	
	IBOutlet Controller *controller;
	IBOutlet ChatController *chatController;

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

- (void)doIt;

// example: MULTIACTIONBAR1BUTTON1 for lower left action bar 1
- (NSArray*)bindingForCommand:(NSString*)binding;

// just pass MULTIACTIONBAR1BUTTON1 and it will send the command to the client!
//- (BOOL)executeBinding:(NSString*)binding;

// this will send the command to the client (use the above 3 keys - defines)
- (BOOL)executeBindingForKey:(NSString*)key;

// returns the bar offset (where the spell should be written to)
- (int)barOffsetForKey:(NSString*)key;

@end
