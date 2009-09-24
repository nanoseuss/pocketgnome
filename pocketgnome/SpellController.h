//
//  SpellController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/20/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MemoryAccess.h"
#import "Spell.h"

@class Controller;
@class BotController;
@class PlayerDataController;
@class OffsetController;

@interface SpellController : NSObject {
    IBOutlet Controller				*controller;
    IBOutlet BotController			*botController;
    IBOutlet PlayerDataController	*playerController;
	IBOutlet OffsetController		*offsetController;

    IBOutlet id spellDropDown;
    IBOutlet id spellLoadingProgress;
    
    IBOutlet NSView *view;
	IBOutlet NSPanel *cooldownPanel;
    IBOutlet NSTableView *cooldownPanelTable;
	
    Spell *selectedSpell;
    NSMutableArray *_playerSpells;
	NSMutableArray *_spellTableAddresses;
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

@end
