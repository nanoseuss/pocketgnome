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
#import "MemoryAccess.h"
#import "Spell.h"

@class Controller;
@class BotController;
@class MacroController;
@class PlayerDataController;
@class OffsetController;
@class InventoryController;

@interface SpellController : NSObject {
    IBOutlet Controller				*controller;
    IBOutlet BotController			*botController;
    IBOutlet PlayerDataController	*playerController;
	IBOutlet OffsetController		*offsetController;
	IBOutlet MacroController		*macroController;
	IBOutlet InventoryController	*itemController;

    IBOutlet id spellDropDown;
    IBOutlet id spellLoadingProgress;
    
    IBOutlet NSView *view;
	IBOutlet NSPanel *cooldownPanel;
    IBOutlet NSTableView *cooldownPanelTable;
	
    Spell *selectedSpell;
    NSMutableArray *_playerSpells;
	NSMutableArray *_playerCooldowns;
    NSMutableDictionary *_spellBook, *_cooldowns;
    NSSize minSectionSize, maxSectionSize;
    
    NSTimer *_lastSpellReloadTimer;
}

+ (SpellController *)sharedSpells;

@property (readonly) NSView *view;
@property (readonly) NSString *sectionTitle;
@property NSSize minSectionSize;
@property NSSize maxSectionSize;
@property (readwrite, retain) Spell *selectedSpell;

- (UInt32)lastAttemptedActionID;         // uses LAST_SPELL_*_STATIC constant

- (void)reloadPlayerSpells;

- (Spell*)spellForName: (NSString*)name;
- (Spell*)spellForID: (NSNumber*)spellID;
- (Spell*)highestRankOfSpell: (Spell*)spell;
- (Spell*)playerSpellForName: (NSString*)spellName;
- (Spell*)mountSpell: (int)type andFast:(BOOL)isFast;
- (int)mountsLoaded;
- (BOOL)addSpellAsRecognized: (Spell*)spell;

// For spell cooldowns (no longer needed as of 3.1.3 due to CD code)
//- (void)didCastSpell: (Spell*)spell;
//- (void)didCastSpellWithID: (NSNumber*)spellID;
//- (BOOL)canCastSpellWithID: (NSNumber*)spellID;

- (BOOL)isPlayerSpell: (Spell*)spell;
- (NSArray*)playerSpells;
- (NSMenu*)playerSpellsMenu;

- (IBAction)reloadMenu: (id)sender;
- (IBAction)spellLoadAllData:(id)sender;

- (void)showCooldownPanel;
- (void)reloadCooldownInfo;

// Cooldown info
-(BOOL)isGCDActive;
-(BOOL)isSpellOnCooldown:(UInt32)spell;
-(UInt32)cooldownLeftForSpellID:(UInt32)spell;

- (BOOL)isUsableAction: (UInt32)actionID;
- (BOOL)isUsableActionWithSlot: (int)slot;

// returns nil if ready! Otherwise an error string
- (NSString*)spellsReadyForBotting;

@end
