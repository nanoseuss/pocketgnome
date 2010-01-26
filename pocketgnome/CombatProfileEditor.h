//
//  CombatProfileEditor.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 7/19/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CombatProfile.h"
#import "SaveData.h"

@class PlayersController;
@class BotController;
@class Controller;
@class MobController;

@class Player;

@interface CombatProfileEditor : SaveData {
    IBOutlet NSPanel			*editorPanel;
    IBOutlet NSPanel			*renamePanel;
    IBOutlet NSTableView		*ignoreTable;
	
	IBOutlet NSPopUpButton		*assistPopUpButton;
	IBOutlet NSPopUpButton		*tankPopUpButton;
	IBOutlet NSPopUpButton		*followPopUpButton;
	
	IBOutlet PlayersController	*playersController;
	IBOutlet BotController		*botController;
	IBOutlet Controller			*controller;
	IBOutlet MobController		*mobController;
	
    NSMutableArray				*_combatProfiles;
    CombatProfile				*_currentCombatProfile;
	
	NSString *_nameBeforeRename;
}

@property (readonly) NSArray *combatProfiles;

+ (CombatProfileEditor *)sharedEditor;
- (void)showEditorOnWindow: (NSWindow*)window forProfileNamed: (NSString*)profile;

- (NSArray*)combatProfiles;
- (IBAction)createCombatProfile: (id)sender;
- (IBAction)loadCombatProfile: (id)sender;

- (IBAction)renameCombatProfile: (id)sender;
- (IBAction)closeRename: (id)sender;
- (IBAction)duplicateCombatProfile: (id)sender;
- (IBAction)deleteCombatProfile: (id)sender;

- (id)importCombatProfileAtPath: (NSString*)path;
- (IBAction)importCombatProfile: (id)sender;
- (IBAction)exportCombatProfile: (id)sender;

- (IBAction)addIgnoreEntry: (id)sender;
- (IBAction)addIgnoreFromTarget: (id)sender;
- (IBAction)deleteIgnoreEntry: (id)sender;

- (IBAction)closeEditor: (id)sender;

@end
