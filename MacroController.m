//
//  MacroController.m
//  Pocket Gnome
//
//  Created by Josh on 9/21/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "MacroController.h"
#import "Controller.h"
#import "BotController.h"
#import "ActionMenusController.h"
#import "PlayerDataController.h"
#import "AuraController.h"
#import "ChatController.h"
#import "OffsetController.h"

#import "Player.h"
#import "MemoryAccess.h"
#import "Macro.h"

@implementation MacroController


- (id) init{
    self = [super init];
    if (self != nil) {
        
		_playerName = nil;
		_accountName = nil;
		_serverName = nil;
		_playerMacros = nil;
		
		 // Notifications
		 [[NSNotificationCenter defaultCenter] addObserver: self
		 selector: @selector(playerIsValid:) 
		 name: PlayerIsValidNotification 
		 object: nil];
    }
    return self;
}

- (void) dealloc{
	[_playerName release];
	[_accountName release];
	[_serverName release];
    [super dealloc];
}

@synthesize playerMacros = _playerMacros;

#pragma mark Notifications

- (void)setMenu: (NSPopUpButton*)popUpButton Key:(NSString*)key{
	NSString *newKey = [NSString stringWithFormat:@"%@_%@_%@_%@", _serverName, _accountName, _playerName, key];
	UInt32 actionID = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: newKey] intValue];
	//PGLog(@"Looking up for key: %@  Value: %d", newKey, actionID);
	NSMenu *macroMenu = [[[ActionMenusController sharedMenus] menuType: MenuType_Macro actionID: actionID] retain];
	[popUpButton setMenu: macroMenu];
	if ( actionID ) [popUpButton selectItemWithTag:actionID];
}

// save helper
- (void)saveMacro: (NSPopUpButton*)popUpButton Key:(NSString*)key{
	NSString *newKey = [NSString stringWithFormat:@"%@_%@_%@_%@", _serverName, _accountName, _playerName, key];
	//PGLog(@"Saving key: %@", newKey);
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[popUpButton selectedTag]] forKey: newKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// save all info!
- (IBAction)macroSelected: (id)sender{
	[self saveMacro:macroAcceptBattleFieldPort			Key:@"MacroAcceptBattlefieldPort"];
	[self saveMacro:macroJoinBattlefield				Key:@"MacroJoinBattlefield"];
	[self saveMacro:macroLeaveBattlefield				Key:@"MacroLeaveBattlefield"];
	[self saveMacro:macroRepopMe						Key:@"MacroRepopMe"];
	[self saveMacro:macroRetrieveCorpse					Key:@"MacroRetrieveCorpse"];
	[self saveMacro:macroDismount						Key:@"MacroDismount"];
	[self saveMacro:macroCancelSwiftFlightForm			Key:@"MacroCancelSwiftFlightForm"];
	[self saveMacro:macroCancelFlightForm				Key:@"MacroCancelFlightForm"];
	[self saveMacro:macroClickPopup						Key:@"MacroClickPopup"];
}

//	update our list of macros when the player is valid
- (void)playerIsValid: (NSNotification*)not {
	
	[_playerName release]; _playerName = nil;
	[_accountName release]; _accountName = nil;
	[_serverName release]; _serverName = nil;
	_playerName = [[playerData playerName] retain];
	_accountName = [[playerData accountName] retain];
	_serverName = [[playerData serverName] retain];
	
	[self setMenu:macroAcceptBattleFieldPort		Key:@"MacroAcceptBattlefieldPort"];
	[self setMenu:macroJoinBattlefield				Key:@"MacroJoinBattlefield"];
	[self setMenu:macroLeaveBattlefield				Key:@"MacroLeaveBattlefield"];
	[self setMenu:macroRepopMe						Key:@"MacroRepopMe"];
	[self setMenu:macroRetrieveCorpse				Key:@"MacroRetrieveCorpse"];
	[self setMenu:macroDismount						Key:@"MacroDismount"];
	[self setMenu:macroCancelSwiftFlightForm		Key:@"MacroCancelSwiftFlightForm"];
	[self setMenu:macroCancelFlightForm				Key:@"MacroCancelFlightForm"];
	[self setMenu:macroClickPopup					Key:@"MacroClickPopup"];
}

// actually will take an action (macro or send command)
- (void)takeAction: (NSPopUpButton*)popUpButton Sequence:(NSString*)sequence{
	
	// use macro
	if ( [popUpButton selectedTag] ){
		int actionID = (USE_MACRO_MASK + [popUpButton selectedTag]);
		[botController performAction:actionID];	
	}
	else{
		// Does hitting escape work to close the chat?
		if ( [controller isWoWChatBoxOpen] ){
			PGLog(@"[Macro] Sending escape!");
			[chatController sendKeySequence: [NSString stringWithFormat: @"%c", kEscapeCharCode]];
			usleep(100000);
		}
		
		// Send dismount!
		[chatController enter];
		usleep(100000);
		[chatController sendKeySequence: [NSString stringWithFormat: @"%@%c", sequence, '\n']];
	}
}

- (void)acceptBattlefield{
	[self takeAction: macroAcceptBattleFieldPort Sequence:@"/script AcceptBattlefieldPort(1,1);"];
}

- (void)joinBattlefield{
	[self takeAction: macroJoinBattlefield Sequence:@"/script JoinBattlefield(0);"];
}

- (void)leaveBattlefield{
	[self takeAction: macroLeaveBattlefield Sequence:@"/script LeaveBattlefield();"];
}

- (void)rePopMe{
	[self takeAction: macroRepopMe Sequence:@"/script RepopMe();"];
}

- (void)retrieveCorpse{
	[self takeAction: macroRetrieveCorpse Sequence:@"/script RetrieveCorpse();"];
}

- (void)clickPopup{
	[self takeAction: macroClickPopup Sequence:@"/run if StaticPopup1:IsVisible() then StaticPopup_OnClick(StaticPopup1, 1) end"];
}

// dismount please!
- (void)dismount{
	
	// Swift Flight Form
	if ( [auraController unit: [playerData player] hasAuraNamed: @"Swift Flight Form"] ){
		
		[self takeAction: macroCancelSwiftFlightForm Sequence:@"/cancelaura Swift Flight Form"];
	}
	
	// Flight Form
	else if ( [auraController unit: [playerData player] hasAuraNamed: @"Flight Form"] ){
		
		[self takeAction: macroCancelFlightForm Sequence:@"/cancelaura Flight Form"];
	}
	
	// Otherwise dismount!
	else{
		
		[self takeAction: macroDismount Sequence:@"/dismount"];
	}
}

// this function will pull player macros from memory!
- (void)reloadMacros{
	
	// technically the first release does nothing
	[_playerMacros release]; _playerMacros = nil;
	
	// this is where we will store everything
	NSMutableArray *macros = [NSMutableArray array];
	
	// + 0x10 from this ptr is a ptr to the macro object list (but we don't need this)
	UInt32 offset = [offsetController offset:@"MACRO_LIST_PTR"];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	
	UInt32 objectPtr = 0, macroID = 0;
	[memory loadDataForObject:self atAddress:offset Buffer:(Byte *)&objectPtr BufLength:sizeof(objectPtr)];
	
	// while we have a valid ptr!
	while ( ( objectPtr & 0x1 ) == 0 ){
		
		//	0x0==0x18 macro ID
		//	0x10 next ptr
		//	0x20 macro name
		//	0x60 macro icon
		//	0x160 macro text
		// how to determine if it's a character macro: (macroID & 0x1000000) == 0x1000000
		
		// initialize variables
		char macroName[17], macroText[256];
		macroName[16] = 0;
		macroText[255] = 0;
		NSString *newMacroName = nil;
		NSString *newMacroText = nil;
		
		// get the macro name
		if ( [memory loadDataForObject: self atAddress: objectPtr+0x20 Buffer: (Byte *)&macroName BufLength: sizeof(macroName)-1] ) {
			newMacroName = [NSString stringWithUTF8String: macroName];
		}
		
		// get the macro text
		if ( [memory loadDataForObject: self atAddress: objectPtr+0x160 Buffer: (Byte *)&macroText BufLength: sizeof(macroText)-1] ) {
			newMacroText = [NSString stringWithUTF8String: macroText];
		}
		
		// get the macro ID
		[memory loadDataForObject:self atAddress:objectPtr Buffer:(Byte *)&macroID BufLength:sizeof(macroID)];
		
		// add it to our list	
		Macro *macro = [Macro macroWithName:newMacroName number:[NSNumber numberWithInt:macroID] body:newMacroText isCharacter:((macroID & 0x1000000) == 0x1000000)];
		[macros addObject:macro];

		// get the next object ptr
		[memory loadDataForObject:self atAddress:objectPtr+0x10 Buffer:(Byte *)&objectPtr BufLength:sizeof(objectPtr)];
	}

	_playerMacros = [macros retain];
}

@end
