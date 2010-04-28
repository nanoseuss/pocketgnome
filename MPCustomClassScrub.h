//
//  MPCustomClassScrub.h
//  Pocket Gnome
//
//  Created by codingMonkey on 4/26/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClass.h"

@class MPTimer;
@class Mob;
@class CombatController;
@class BotController;
@class MPSpell;
@class Unit;

@interface MPCustomClassScrub : MPCustomClass {

	NSArray *listBuffs, *listSpells, *listParty;
	MPTimer *timerGCD, *timerRefreshParty, *timerBuffCheck, *timerSpellScan;
	BOOL errorLOS;
	MPCCCombatState state;
}
@property (retain) NSArray *listBuffs, *listSpells, *listParty;
@property (retain) MPTimer *timerGCD, *timerRefreshParty, *timerBuffCheck, *timerSpellScan;


// called 1x before combat is started with given mob
// (isn't called if already in combat and switching to another target)
- (void) openingMoveWith: (Mob *)mob;

// called repeatedly while in combat.
- (MPCombatState) combatActionsWith: (Mob *) mob; 


- (void) targetUnit: (Unit *)unit;
- (BOOL) cast: (MPSpell *)spell on:(Unit *)unit;
- (BOOL) castDOT:(MPSpell *)spell on:(Unit *)unit;
- (BOOL) castHOT:(MPSpell *)spell on:(Unit *)unit;

@end
