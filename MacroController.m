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

#import "Player.h"

@implementation MacroController


- (id) init{
    self = [super init];
    if (self != nil) {
        
		_playerName = nil;
		_accountName = nil;
		_serverName = nil;
		
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

@end
