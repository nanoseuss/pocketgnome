//
//  CombatController.h
//  Pocket Gnome
//
//  Created by Josh on 12/19/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

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
