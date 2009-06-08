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

@interface SpellController : NSObject {
    IBOutlet id controller;
    IBOutlet id botController;
    IBOutlet id playerController;

    IBOutlet id spellDropDown;
    IBOutlet id spellLoadingProgress;
    
    IBOutlet NSView *view;
    
    Spell *selectedSpell;
    NSMutableArray *_playerSpells;
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
- (BOOL)addSpellAsRecognized: (Spell*)spell;

- (void)didCastSpell: (Spell*)spell;
- (void)didCastSpellWithID: (NSNumber*)spellID;
- (BOOL)canCastSpellWithID: (NSNumber*)spellID;

- (BOOL)isPlayerSpell: (Spell*)spell;
- (NSArray*)playerSpells;
- (NSMenu*)playerSpellsMenu;

- (IBAction)reloadMenu: (id)sender;
- (IBAction)spellLoadAllData:(id)sender;


@end
