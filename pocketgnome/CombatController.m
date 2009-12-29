//
//  CombatController.m
//  Pocket Gnome
//
//  Created by Josh on 12/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CombatController.h"
#import "PlayersController.h"
#import "AuraController.h"
#import "MobController.h"
#import "BotController.h"
#import "PlayerDataController.h"
#import "BlacklistController.h"
#import "MovementController.h"
#import "Controller.h"
#import "AuraController.h"

#import "Unit.h"
#import "Rule.h"
#import "CombatProfile.h"

#import "ImageAndTextCell.h"


@interface CombatController (Internal)
-(NSArray*)allValidUnitsForCombat:(BOOL)includeFriendly;
- (NSArray*)availableUnits:(BOOL)includeFriendly;
- (NSArray*)friendlyUnits;
- (NSArray*)findNearbyEnemies;
- (NSRange)levelRange;
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition;
- (void)stayWithUnit;
- (void)finishUnit:(Unit*)unit;
- (NSArray*)combatListValidated;
- (void)updateCombatTable;
- (void)monitorUnit: (Unit*)unit;
@end


@implementation CombatController

- (id) init{
    self = [super init];
    if (self != nil) {
        
		_attackUnit		= nil;
		_friendUnit		= nil;
		_addUnit		= nil;
		_castingUnit	= nil;
		
		_inCombat = NO;
		
		_unitsAttackingMe = [[NSMutableArray array] retain];
		_unitsAllCombat = [[NSMutableArray array] retain];
		
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(outOfRange:) name: ErrorOutOfRange object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInFront:) name: ErrorTargetNotInFront object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(unitDied:) 
                                                     name: UnitDiedNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc
{
	[_unitsAttackingMe release];
    [super dealloc];
}

@synthesize attackUnit = _attackUnit;
@synthesize castingUnit = _castingUnit;
@synthesize addUnit = _addUnit;
@synthesize inCombat = _inCombat;

#pragma mark -

int DistFromPositionCompare(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
    
    //PlayerDataController *playerData = (PlayerDataController*)context; [playerData position];
    Position *position = (Position*)context; 
	
    float d1 = [position distanceToPosition: [unit1 position]];
    float d2 = [position distanceToPosition: [unit2 position]];
    if (d1 < d2)
        return NSOrderedAscending;
    else if (d1 > d2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

int WeightCompare(id unit1, id unit2, void *context) {
	
	CombatController *combat = (CombatController*)context;
	
	int weight1 = [combat weight:unit1];
	int weight2 = [combat weight:unit2];
	
	//PGLog(@"(%@)%d vs. (%@)%d", unit1, weight1, unit2, weight2);
    if (weight1 > weight2)
        return NSOrderedAscending;
    else if (weight1 < weight2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
	
	return NSOrderedSame;
}

#pragma mark Notifications

- (void)playerEnteringCombat: (NSNotification*)notification {
    PGLog(@"------ Player Entering Combat ------");
	
	_inCombat = YES;
}

- (void)playerLeavingCombat: (NSNotification*)notification {
    PGLog(@"------ Technically (real) OOC ------");
	
	_inCombat = NO;
	
	[self cancelAllCombat];
}

// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	
	// is there a unit we should be attacking
	if ( _castingUnit && [playerData targetID] == [_castingUnit GUID] ){
		PGLog(@"[Combat] Target not valid, blacklisting %@", _castingUnit);
		[blacklistController blacklistObject: _castingUnit];
	}
}

// target is out of range
- (void)outOfRange: (NSNotification*)notification {
	
	// blacklist?
	if ( _castingUnit && [playerData targetID] == [_castingUnit GUID] ){
		PGLog(@"[Combat] Out of range, blacklisting %@", _castingUnit);
		[blacklistController blacklistObject: _castingUnit];
	}
}

- (void)targetNotInFront: (NSNotification*)notification {
	PGLog(@"[Combat] Target not in front!");
	[movementController backEstablishPosition];
}

- (void)unitDied: (NSNotification*)notification{
	Unit *unit = [notification object];
	
	if ( unit == _addUnit ){
		PGLog(@"[Combat] Removing add %@", unit);
		[_addUnit release]; _addUnit = nil;
	}
}
	
#pragma mark Public

// list of units we're in combat with, NO friendlies
- (NSArray*)combatList{
	
	NSMutableArray *units = [NSMutableArray array];
	
	if ( [_unitsAttackingMe count] ){
		[units addObjectsFromArray:_unitsAttackingMe];
	}
	
	// add the other units if we need to
	if ( _attackUnit!= nil && ![units containsObject:_attackUnit] ){
		[units addObject:_attackUnit];
	}
	
	if ( _addUnit != nil && ![units containsObject:_addUnit] ){
		[units addObject:_addUnit];
	}
	
	[units sortUsingFunction: WeightCompare context: self];
	
	return [[units retain] autorelease];
}

// out of the units that are attacking us, which are valid for us to attack back?
- (NSArray*)combatListValidated{
	NSArray *units = [self combatList];
	NSMutableArray *validUnits = [NSMutableArray array];
	
	Position *playerPosition = [playerData position];
	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
	
	for ( Unit *unit in units ){
		
		if ( [blacklistController isBlacklisted:unit] )
			continue;
		
		// ignore dead/evading/not valid units
		if ( [unit isDead] || [unit isEvading] || ![unit isValid] ){
			continue;
		}
		
		// ignore if vertical distance is too great
		if ( [[unit position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
			continue;
		}
		
		// range changes if the unit is friendly or not
		float distanceToTarget = [playerPosition distanceToPosition:[unit position]];
		float range = ([playerData isFriendlyWithFaction: [unit factionTemplate]] ? botController.theCombatProfile.healingRange : botController.theCombatProfile.attackRange);
		if ( distanceToTarget > range ){
			continue;
		}
		
		[validUnits addObject:unit];		
	}	
	
	// sort by weight!
	[validUnits sortUsingFunction: WeightCompare context: self];
	
	return [[validUnits retain] autorelease];
}


- (BOOL)combatEnabled{
	return botController.theCombatProfile.combatEnabled;
}

// from: BOTCONTOLLER
/*
- (void)startOnUnit:(Unit*)unit{
	
	// if we get to this function, we can make the assumption that the appropriate checks have been made on this unit!
	//  i.e. if friendly, we actually have friendly rules, etc...  or it's still alive
	
	
	// in theory this is purely notification, we store this internally so we know who we are targeting, then we tell botController to start the CombatProcedure
	
	//BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
	
	
	// what should we do here?
	
	[_castingUnit release]; _castingUnit = nil;
	_castingUnit = [unit retain];
	
	// lets monitor the unit here
	BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
	if ( !isFriendly ){
		
	}
	
	[botController actOnUnit:unit];
	
}*/

// from performProcedureWithState (CombatProcedure)
// this will keep the unit targeted!
- (void)stayWithUnit:(Unit*)unit withType:(int)type{
	
	Unit *oldTarget = [_castingUnit retain];
	
	[_castingUnit release]; _castingUnit = nil;
	_castingUnit = [unit retain];
	
	// enemy
	if ( type == TargetEnemy ){
		_attackUnit = [unit retain];
	}
	// add
	else if ( type == TargetAdd ){
		_addUnit = [unit retain];
	}
	// friendly
	else if ( type == TargetFriend || type == TargetPet ){
		_friendUnit = [unit retain];
	}
	// otherwise lets clear our target (we're either targeting no one or ourself)
	else{
		[_castingUnit release];
		_castingUnit = nil;
	}
	
	// stop monitoring our "old" unit - we ONLY want to do this in PvP as we'd like to know when the unit dies!
	if ( oldTarget && [botController isPvPing] ){
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: oldTarget];
		[oldTarget release];
	}
	
	// we want to monitor enemies to fire off notifications if they die!
	if ( type == TargetEnemy ){
		// cancel a previous request if it's going on
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(monitorUnit:) object: unit];
		
		// monitor again!
		[self monitorUnit:unit];
	}
	
	PGLog(@"[Combat] Now staying with %@", unit);
	
	[self stayWithUnit];
}

- (void)stayWithUnit{
	
	//PGLog(@"[Combat] Staying with %@", _castingUnit);
	
	// cancel other requests
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
	
	if ( _castingUnit == nil ){
		PGLog(@"[Combat] No longer staying w/the unit");
		return;
	}
	
	// dead
	if ( [_castingUnit isDead] ){
		PGLog(@"[Combat] Unit is dead! %@", _castingUnit);
		return;
	}
	
	// sanity checks
	if ( ![_castingUnit isValid] || [_castingUnit isEvading] || [blacklistController isBlacklisted:_castingUnit] ) {
		PGLog(@"[Combat] STOP ATTACK: Invalid? (%d)  Evading? (%d)  Blacklisted? (%d)", ![_castingUnit isValid], [_castingUnit isEvading], [blacklistController isBlacklisted:_castingUnit]);
		return;
	}
	
	if ( [playerData isDead] ){
		PGLog(@"[Combat] You died, stopping attack.");
		return;
	}
	
	BOOL isCasting = [playerData isCasting];
	
	// check player facing vs. unit position
	float playerDirection = [playerData directionFacing];
	float theAngle = [[playerData position] angleTo: [_castingUnit position]];
	
	// compensate for the 2pi --> 0 crossover
	if(fabsf(theAngle - playerDirection) > M_PI) {
		if(theAngle < playerDirection)  theAngle        += (M_PI*2);
		else                            playerDirection += (M_PI*2);
	}
	
	// find the difference between the angles
	float angleTo = fabsf(theAngle - playerDirection);
	
	// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
	if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
		PGLog(@"[Combat] Unit is behind us (%.2f). Repositioning.", angleTo);
		
		// set player facing and establish position
		BOOL useSmooth = [movementController useSmoothTurning];
		
		if(!isCasting) [movementController pauseMovement];
		[movementController turnTowardObject: _castingUnit];
		if(!isCasting && !useSmooth) {
			[movementController backEstablishPosition];
		}
	}
	
	if( !isCasting ) {
		
		// ensure unit is our target
		UInt64 unitUID = [_castingUnit GUID];
		//PGLog(@"[Combat] Not casting 0x%qX 0x%qX", [playerData targetID], unitUID);
		if ( ( [playerData targetID] != unitUID) || [_castingUnit isFeignDeath] ) {
			Position *playerPosition = [playerData position];
			PGLog(@"[Combat] Targeting %@  Weight: %d", _castingUnit, [self weight:_castingUnit PlayerPosition:playerPosition] );
			
			[playerData setPrimaryTarget: _castingUnit];
			usleep([controller refreshDelay]);
		}
	}
	
	// tell/remind bot controller to attack
	//[botController attackUnit: _castingUnit];
	[self performSelector: @selector(stayWithUnit) withObject: nil afterDelay: 0.25];
}

- (void)cancelAllCombat{
	
	PGLog(@"[Combat] All combat cancelled");
	
	// cancel selecting the unit!
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
	
	// cancel all requests!
	//[NSObject cancelPreviousPerformRequestsWithTarget: self];		// we're not calling this as it kills our monitor function + the death might not be fired!

	// reset our variables
	[_castingUnit release]; _castingUnit = nil;
	[_attackUnit release];	_attackUnit = nil;
	[_addUnit release];		_addUnit = nil;
	[_friendUnit release];	_friendUnit =  nil;
	
	// remove blacklisted units (TO DO: we should only remove those of type Unit)
	[blacklistController removeAllUnits];
}

- (void)resetAllCombat{
	[self cancelAllCombat];
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
}

- (NSArray*)availableUnits:(BOOL)includeFriendly{
	
	NSMutableArray *allPotentialUnits = [NSMutableArray array];
	
	// add friendly units w/in range
	if ( ( botController.theCombatProfile.healingEnabled || includeFriendly ) ){
		[allPotentialUnits addObjectsFromArray:[self friendlyUnits]];
	}
	
	// add new units w/in range
	if ( botController.theCombatProfile.combatEnabled && ![botController.theCombatProfile onlyRespond] ){
		[allPotentialUnits addObjectsFromArray:[self findNearbyEnemies]];
	}
	
	// add units attacking me
	//_unitsAttackingMe
	if ( [_unitsAttackingMe count] ){
		
		for ( Unit *target in _unitsAttackingMe ){
			if ( ![allPotentialUnits containsObject:target] ){
				[allPotentialUnits addObject:target];
			}
		}
	}
	
	return [[allPotentialUnits retain] autorelease];
}

// used by performProcedureWithState
-(NSArray*)allValidAndInCombat:(BOOL)includeFriendly{
	
	NSMutableArray *units = [NSMutableArray arrayWithArray:[self allValidUnitsForCombat:includeFriendly]];
	
	// add combat units
	NSArray *combatUnits = [self combatListValidated];
	for ( Unit *unit in combatUnits ){
		if ( ![units containsObject:unit] ){
			[units addObject:unit];
		}
	}
	
	// TO DO: THE ADD CHECK SHOULD ONLY LOOK @ UNITS WE ARE IN COMBAT WITH!
	
	
	// should we remove the add unit from the list? (should only happen if one hostile is left!)
	if ( _addUnit != nil ){
		
		// we have more than 1!
		if ( [combatUnits count] > 1 ){
			
			// get the number of hostiles, if more than 1, we will remove the add unit
			int hostiles = 0;
			for ( Unit *unit in combatUnits ){
				BOOL isHostile = [playerData isHostileWithFaction: [unit factionTemplate]];

				if ( isHostile ){
					hostiles++;
				}
			}
			
			// this means we have at least 2 hostiles, so we can ignore the add for now!
			if ( hostiles > 1 ){
				[units removeObject:_addUnit];
				PGLog(@"[Combat] Removing the add %@ from our valid unit list!", _addUnit);
			}
		}
		
		// we have an add unit, but no combat units (makes sense if they are cc:ed + not selecting us)
		if ( [combatUnits count] == 0 ){
			PGLog(@"[Combat] Adding add to our list! The count before add is %d", [units count]);
			[units addObject:_addUnit];
		}
	}
	
	[units sortUsingFunction: WeightCompare context: self];
	
	return [[units retain] autorelease];	
}

// units here will meet all conditions! Combat Profile WILL be checked
-(NSArray*)allValidUnitsForCombat:(BOOL)includeFriendly{
	
	NSArray *allPotentialUnits = [NSMutableArray arrayWithArray:[self availableUnits:includeFriendly]];
	NSMutableArray *validUnits = [NSMutableArray array];
	
	Position *playerPosition = [playerData position];
	
	if ( [allPotentialUnits count] ){
		float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
		float distanceToTarget = 0.0f, range = 0.0f;
		BOOL isFriendly = NO;
		
		for ( Unit *unit in allPotentialUnits ){
			
			// ignore blacklisted units
			if ( [blacklistController isBlacklisted:unit] ){
				PGLog(@"[Combat] Unit %@ is blacklisted, ignoring in best unit selection", unit);
				continue;
			}
			
			// ignore dead/evading/not valid units
			if ( [unit isDead] || [unit isEvading] || ![unit isValid] ){
				continue;
			}
			
			// ignore if vertical distance is too great
			if ( [[unit position] verticalDistanceToPosition: playerPosition] > vertOffset ) {
				continue;
			}
			
			isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
			
			// ignore friendly
			if ( isFriendly && !includeFriendly ){
				continue;
			}
			
			// range changes if the unit is friendly or not
			distanceToTarget = [playerPosition distanceToPosition:[unit position]];
			range = (self.inCombat ? (isFriendly ? botController.theCombatProfile.healingRange : botController.theCombatProfile.attackRange) : botController.theCombatProfile.engageRange);
			
			if ( distanceToTarget > range ){
				continue;
			}
			
			// make sure they're not a ghost
			NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
			if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
				continue;
			}
			
			[validUnits addObject: unit];
		}
		
		//PGLog(@"[Combat] Actually considered units: %d", [validUnits count]);
	}
	
	return [[validUnits retain] autorelease];
}

// find a unit to attack, CC, or heal
-(Unit*)findUnitWithFriendly:(BOOL)includeFriendly{
	
	// flying check?
	if ( [botController.theCombatProfile ignoreFlying] ){
		// are we flying?
		if ( ![[playerData player] isOnGround] ){
			return nil;
		}
	}

	NSArray *validUnits = [NSArray arrayWithArray:[self allValidUnitsForCombat:includeFriendly]];
	Position *playerPosition = [playerData position];
	
	if ( [validUnits count] ){
		int highestWeight = 0;
		Unit *bestUnit = nil;
		for ( Unit *unit in validUnits ){
									 
			// begin weight calculation
			int weight = [self weight:unit PlayerPosition:playerPosition];

			PGLog(@"[Combat] Valid target %@ found with weight %d", unit, weight);
			
			// best weight
			if ( weight > highestWeight ){
				highestWeight = weight;
				bestUnit = unit;
			}
		}

		return bestUnit;
	}
	
	return nil;
}

- (NSArray*)allAdds{
	
	NSMutableArray *allAdds = [NSMutableArray array];
	
	// loop through units that are attacking us!
	for ( Unit *unit in _unitsAttackingMe ){
		
		if ( unit != _attackUnit ){
			[allAdds addObject:unit];
		}
	}
	
	return [[allAdds retain] autorelease];
}

#pragma mark Enemy

// so, in a perfect world
// -) players before pets
// -) low health targets before high health targets
// -) closer before farther
// everything needs to be in combatProfile range

// assign 'weights' to each target based on current conditions/settings
// highest weight unit is our best target

// current target? +25
// player? +100 pet? +25
// hostile? +100, neutral? +100
// health: +(100-percentHealth)
// distance: 100*(attackRange - distance)/attackRange
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition{
	float attackRange = botController.theCombatProfile.attackRange;
	float distanceToTarget = [playerPosition distanceToPosition:[unit position]];
	BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
	
	// begin weight calculation
	int weight = 0;
	
	// player or pet?
	if ([unit isPlayer])
		weight += 100;
	else if ([unit isPet])
		weight -= 25;
	
	// current target
	if ( [playerData targetID] == [unit GUID] )
		weight += 25;
	
	// health left
	weight += (100-[unit percentHealth]);
	
	// distance to target
	if ( !isFriendly && attackRange > 0 )
		weight += ( 100 * ((attackRange-distanceToTarget)/attackRange));
	
	// friendly?
	if ( isFriendly ){
		weight *= 1.5;
	}
	
	return weight;	
}

- (int)weight: (Unit*)unit{
	return [self weight:unit PlayerPosition:[playerData position]];
}

// scan for targets that are in range (generally not in combat)
- (NSArray*)findNearbyEnemies {
    // scan for valid, in-range targets to attack
    
    // determine level range
    //int min, range, level = [playerData level];
    //if(_minLevel == 100)    min = 1;
    //else                    min = level - _minLevel;
    //if(min < 1) min = 1;
    //range = (level + _maxLevel) - min;  // set max level
	
    /*if ( !botController.theCombatProfile.combatEnabled )
        return nil;*/
    
    NSMutableArray *targetsWithinRange = [NSMutableArray array];
	
	NSRange range = [self levelRange];

	 // check for mobs?
	 if ( botController.theCombatProfile.attackNeutralNPCs || botController.theCombatProfile.attackHostileNPCs ) {
		 [targetsWithinRange addObjectsFromArray: [mobController mobsWithinDistance: [botController.theCombatProfile attackRange]
																		 levelRange: range
																	   includeElite: !(botController.theCombatProfile.ignoreElite)
																	includeFriendly: NO
																	 includeNeutral: botController.theCombatProfile.attackNeutralNPCs
																	 includeHostile: botController.theCombatProfile.attackHostileNPCs]];
	 }
	
	 // check for players?
	 if ( botController.theCombatProfile.attackPlayers ) {
		 [targetsWithinRange addObjectsFromArray: [playersController playersWithinDistance: [botController.theCombatProfile attackRange] 
																				levelRange: range
																		   includeFriendly: NO
																			includeNeutral: NO
																			includeHostile: YES]];
	 }
	
	//PGLog(@"[Combat] Found %d targets within range", [targetsWithinRange count]);
	
	return targetsWithinRange;
}

#pragma mark Friendly

- (BOOL)validFriendlyUnit: (Unit*)unit{
	
	NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
	// regular dead - night elf ghost
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
		//PGLog(@"[Combat] Friendly is a ghost! And dead! We should consider them invalid");
		return NO;
	}
	
	// We need to check:
	//	Not dead
	//	Friendly
	//	Could check position + health threshold + if they are moving away!
	if ( ![unit isDead] && [playerData isFriendlyWithFaction: [unit factionTemplate]] ){
		return YES;
	}
	
	return NO;
}

- (NSArray*)friendlyUnits{
	
	// get list of all targets
    NSMutableArray *friendliesWithinRange = [NSMutableArray array];
	NSMutableArray *friendlyTargets = [NSMutableArray array];
	[friendliesWithinRange addObjectsFromArray: [playersController allPlayers]];
	
	// sort by range
    Position *playerPosition = [playerData position];
    [friendliesWithinRange sortUsingFunction: DistFromPositionCompare context: playerPosition];
	
	// if we have some targets
    if ( [friendliesWithinRange count] ) {
        for ( Unit *unit in friendliesWithinRange ) {
			//PGLog(@"[Combat] Friendly - Checking %@", unit);
			if ( [self validFriendlyUnit:unit] ){
				//PGLog(@"[Combat] Valid friendly");
				[friendlyTargets addObject: unit];
			}
        }
    }
	
	//PGLog(@"[Combat] Total friendlies: %d", [friendlyTargets count]);
	
	return friendlyTargets;
}

#pragma mark Internal

// monitor unit until it dies
- (void)monitorUnit: (Unit*)unit{
	
	PGLog(@"[**********] Monitoring %@", unit);
	
	// invalid unit
	if ( !unit || ![unit isValid] ){
		PGLog(@"[**********] Unit isn't valid! %@", unit);
		return;
	}
	
	// unit died, fire off notification
	if ( [unit isDead] ){
		PGLog(@"[**********] Firing death notification for unit %@", unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}
	
	// unit has ghost aura (so is dead, fire off notification
	NSArray *auras = [[AuraController sharedController] aurasForUnit: unit idsOnly: YES];
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
		PGLog(@"[**********] Firing death notification for player %@", unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}
	
	[self performSelector:@selector(monitorUnit:) withObject:unit afterDelay:0.1f];
}

// find all units we are in combat with
- (void)doCombatSearch{
	
	// add all mobs + players
	NSArray *mobs = [mobController allMobs];
	NSArray *players = [playersController allPlayers];
	
	UInt64 playerGUID = [[playerData player] GUID];
	UInt64 unitTarget = 0;
	BOOL playerHasPet = [[playerData player] hasPet];
	
	for ( Mob *mob in mobs ){
		unitTarget = [mob targetID];
		if (
			![mob isDead]	&&		// 1 - living units only
			[mob isInCombat] &&		// 2 - in Combat
			[mob isSelectable] &&	// 3 - can select this target
			[mob isAttackable] &&	// 4 - attackable
			//[mob isTapped] &&		// 5 - tapped - in theory someone could tap a target while you're casting, and you get agg - so still kill (removed as a unit @ 100% could attack us and not be tapped)
			[mob isValid] &&		// 6 - valid mob
			(	(unitTarget == playerGUID ||										// 7 - targetting us
				 (playerHasPet && unitTarget == [[playerData player] petGUID]) ) ||	// or targetting our pet
			 [mob isFleeing])													// or fleeing
			){
			
			// add mob!
			if ( ![_unitsAttackingMe containsObject:(Unit*)mob] ){
				PGLog(@"[Combat] Adding mob %@", mob);
				[_unitsAttackingMe addObject:(Unit*)mob];
				[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[mob retain] autorelease]];
			}
		}
		// remove unit
		else if ( [_unitsAttackingMe containsObject:(Unit*)mob] ) {
			PGLog(@"[Combat] Removing mob %@", mob);
			[_unitsAttackingMe removeObject:(Unit*)mob];
		}
	}
	
	for ( Player *player in players ){
		unitTarget = [player targetID];
		if (
			![player isDead] &&										// 1 - living units only
			[player currentHealth] != 1 &&							// 2 - this should be a ghost check, being lazy for now
			[player isInCombat] &&									// 3 - in combat
			[player isSelectable] &&								// 4 - can select this target
			([player isAttackable] || [player isFeignDeath] ) &&	// 5 - attackable or feigned
			[player isValid] &&										// 6 - valid
			(	(unitTarget == playerGUID ||										// 7 - targetting us
				 (playerHasPet && unitTarget == [[playerData player] petGUID]) ) ||	// or targetting our pet
			 [player isFleeing])													// or fleeing
			){
			
			// add player
			if ( ![_unitsAttackingMe containsObject:(Unit*)player] ){
				PGLog(@"[Combat] Adding player %@", player);
				[_unitsAttackingMe addObject:(Unit*)player];
				[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[player retain] autorelease]];
			}
		}
		// remove unit
		else if ( [_unitsAttackingMe containsObject:(Unit*)player] ) {
			PGLog(@"[Combat] Removing player %@", player);
			[_unitsAttackingMe removeObject:(Unit*)player];
		}
	}
	
	PGLog(@"[Combat] In combat with %d units", [_unitsAttackingMe count]);
}

// this will return the level range of mobs we are attacking!
- (NSRange)levelRange{
	
	// set the level of mobs/players we are attacking!
	NSRange range = NSMakeRange(0, 0);
	
	// any level
	if ( botController.theCombatProfile.attackAnyLevel ){
		range.length = 200;	// in theory this would be 83, but just making it a high value to be safe
		
		// ignore level one?
		if ( botController.theCombatProfile.ignoreLevelOne ){
			range.location = 2;
		}
		else{
			range.location = 1;
		}
	}
	// we have level requirements!
	else{
		range.location = botController.theCombatProfile.attackLevelMin;
		range.length = botController.theCombatProfile.attackLevelMax - botController.theCombatProfile.attackLevelMin;
	}
	
	return range;
}

#pragma mark UI

- (void)showCombatPanel{
	[combatPanel makeKeyAndOrderFront: self];
}

- (void)updateCombatTable{
	
	if ( [combatPanel isVisible] ){

		[_unitsAllCombat removeAllObjects];
		
		NSArray *allUnits = [self allValidAndInCombat:YES];
		NSMutableArray *allAndSelf = [NSMutableArray array];
		
		if ( [allUnits count] ){
			[allAndSelf addObjectsFromArray:allUnits];
		}
		[allAndSelf addObject:[playerData player]];
		
		Position *playerPosition = [playerData position];
		
		for(Unit *unit in allAndSelf) {
			if( ![unit isValid] )
				continue;
			
			float distance = [playerPosition distanceToPosition: [unit position]];
			unsigned level = [unit level];
			if(level > 100) level = 0;
			int weight = [self weight: unit PlayerPosition:playerPosition];
			
			NSString *name = [unit name];
			if ( (name == nil || [name length] == 0) && ![unit isNPC] ){
				[name release]; name = nil;
				name = [playersController playerNameWithGUID:[unit GUID]];
			}
			
			if ( [unit GUID] == [[playerData player] GUID] ){
				weight = 0;
			}
			
			[_unitsAllCombat addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
										 unit,                                                                @"Player",
										 name,																  @"Name",
										 [NSString stringWithFormat: @"0x%X", [unit lowGUID]],                @"ID",
										 [NSString stringWithFormat: @"%@%@", [unit isPet] ? @"[Pet] " : @"", [Unit stringForClass: [unit unitClass]]],                             @"Class",
										 [Unit stringForRace: [unit race]],                                   @"Race",
										 [NSString stringWithFormat: @"%d%%", [unit percentHealth]],          @"Health",
										 [NSNumber numberWithUnsignedInt: level],                             @"Level",
										 [NSNumber numberWithFloat: distance],                                @"Distance", 
										 [NSNumber numberWithInt:weight],									  @"Weight",
										 nil]];
		}
		
		// Update our combat table!
		[_unitsAllCombat sortUsingDescriptors: [combatTable sortDescriptors]];
		[combatTable reloadData];
	}
	
}

#pragma mark -
#pragma mark TableView Delegate & Datasource

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	[aTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if ( aTableView == combatTable ){
		return [_unitsAllCombat count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ( aTableView == combatTable ){
		if(rowIndex == -1 || rowIndex >= [_unitsAllCombat count]) return nil;
		
		if([[aTableColumn identifier] isEqualToString: @"Distance"])
			return [NSString stringWithFormat: @"%.2f", [[[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: @"Distance"] floatValue]];
		
		if([[aTableColumn identifier] isEqualToString: @"Status"]) {
			NSString *status = [[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: @"Status"];
			if([status isEqualToString: @"1"])  status = @"Combat";
			if([status isEqualToString: @"2"])  status = @"Hostile";
			if([status isEqualToString: @"3"])  status = @"Dead";
			if([status isEqualToString: @"4"])  status = @"Neutral";
			if([status isEqualToString: @"5"])  status = @"Friendly";
			return [NSImage imageNamed: status];
		}
		
		return [[_unitsAllCombat objectAtIndex: rowIndex] objectForKey: [aTableColumn identifier]];
	}
	
	return nil;
}

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell forTableColumn: (NSTableColumn *)aTableColumn row: (int)aRowIndex{
	
	if ( aTableView == combatTable ){
		if( aRowIndex == -1 || aRowIndex >= [_unitsAllCombat count]) return;
		
		if ([[aTableColumn identifier] isEqualToString: @"Race"]) {
			[(ImageAndTextCell*)aCell setImage: [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"RaceIcon"]];
		}
		if ([[aTableColumn identifier] isEqualToString: @"Class"]) {
			[(ImageAndTextCell*)aCell setImage: [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"ClassIcon"]];
		}
		
		// do text color
		if( ![aCell respondsToSelector: @selector(setTextColor:)] ){
			return;
		}
		
		Unit *unit = [[_unitsAllCombat objectAtIndex: aRowIndex] objectForKey: @"Player"];
		
		// casting unit
		if ( unit == _castingUnit ){
			[aCell setTextColor: [NSColor blueColor]];
		}
		else if ( unit == _addUnit ){
			[aCell setTextColor: [NSColor purpleColor]];
		}
		// all others
		else{
			if ( [playerData isFriendlyWithFaction:[unit factionTemplate]] || [unit GUID] == [[playerData player] GUID] ){
				[aCell setTextColor: [NSColor greenColor]];
			}
			else{
				[aCell setTextColor: [NSColor redColor]];
			}
		}
	}
	
	return;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
    if( [[aTableColumn identifier] isEqualToString: @"RaceIcon"])
        return NO;
    if( [[aTableColumn identifier] isEqualToString: @"ClassIcon"])
        return NO;
    return YES;
}

@end
