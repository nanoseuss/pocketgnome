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

@class Controller;
@class ChatController;
@class MobController;
@class BotController;
@class MovementController;
@class PlayerDataController;
@class PlayersController;
@class BlacklistController;
@class AuraController;
@class MacroController;

@class Position;
@class Unit;

#define UnitDiedNotification		@"UnitDiedNotification"
#define UnitEnteredCombat			@"UnitEnteredCombat"

@interface CombatController : NSObject {
    IBOutlet Controller				*controller;
    IBOutlet PlayerDataController	*playerData;
	IBOutlet PlayersController		*playersController;
    IBOutlet BotController			*botController;
    IBOutlet MobController			*mobController;
    IBOutlet ChatController			*chatController;
    IBOutlet MovementController		*movementController;
	IBOutlet BlacklistController	*blacklistController;
	IBOutlet AuraController			*auraController;
	IBOutlet MacroController		*macroController;
	
	// three different types of units to be tracked at all times
	Unit *_attackUnit;
	Unit *_friendUnit;
	Unit *_addUnit;
	Unit *_castingUnit;		// the unit we're casting on!  This will be one of the above 3!
	
	IBOutlet NSPanel *combatPanel;
	IBOutlet NSTableView *combatTable;
	
	BOOL _inCombat;
	
	NSDate *_enteredCombat;
	
	NSMutableArray *_unitsAttackingMe;
	NSMutableArray *_unitsAllCombat;		// meant for the display table ONLY!
	
	NSMutableDictionary *_unitLeftCombatCount;
}

@property BOOL inCombat;
@property (readonly, retain) Unit *attackUnit;
@property (readonly, retain) Unit *castingUnit;
@property (readonly, retain) Unit *addUnit;


// weighted units we're in combat with
- (NSArray*)combatList;

// OUTPUT: PerformProcedureWithState - used to determine which unit to act on!
//	Also used for Proximity Count check
- (NSArray*)validUnitsWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// OUTPUT: return all adds
- (NSArray*)allAdds;

// OUTPUT: find a unit to attack, or heal
-(Unit*)findUnitWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat;

// INPUT: from CombatProcedure within PerformProcedureWithState
- (void)stayWithUnit:(Unit*)unit withType:(int)type;

// INPUT: called when combat should be over
- (void)cancelAllCombat;

// INPUT: called when we start/stop the bot
- (void)resetAllCombat;

// INPUT: from PlayerDataController when a user enters combat
- (void)doCombatSearch;

// OUPUT: could also be using [playerController isInCombat]
- (BOOL)combatEnabled;

// OUPUT: returns the weight of a unit
- (int)weight: (Unit*)unit;

// OUTPUT: valid targets in range based on combat profile
- (NSArray*)enemiesWithinRange:(float)range;

// UI
- (void)showCombatPanel;
- (void)updateCombatTable;

@end
