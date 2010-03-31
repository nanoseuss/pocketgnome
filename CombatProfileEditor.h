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
