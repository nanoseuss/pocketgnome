//
//  MacroController.h
//  Pocket Gnome
//
//  Created by Josh on 9/21/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class BotController;
@class PlayerDataController;
@class AuraController;
@class ChatController;

@interface MacroController : NSObject {
	IBOutlet Controller				*controller;
	IBOutlet BotController			*botController;
	IBOutlet PlayerDataController	*playerData;
	IBOutlet AuraController			*auraController;
	IBOutlet ChatController			*chatController;
	
	IBOutlet NSPopUpButton *macroAcceptBattleFieldPort;
	IBOutlet NSPopUpButton *macroJoinBattlefield;
	IBOutlet NSPopUpButton *macroLeaveBattlefield;
	IBOutlet NSPopUpButton *macroRepopMe;
	IBOutlet NSPopUpButton *macroRetrieveCorpse;
	IBOutlet NSPopUpButton *macroDismount;
	IBOutlet NSPopUpButton *macroCancelSwiftFlightForm;
	IBOutlet NSPopUpButton *macroCancelFlightForm;
	IBOutlet NSPopUpButton *macroClickPopup;
	
	NSString *_accountName;
	NSString *_playerName;
	NSString *_serverName;
}

- (IBAction) macroSelected: (id)sender;

- (void)acceptBattlefield;
- (void)joinBattlefield;
- (void)leaveBattlefield;
- (void)rePopMe;
- (void)retrieveCorpse;
- (void)clickPopup;
- (void)dismount;

@end
