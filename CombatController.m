//
//  CombatController.m
//  Pocket Gnome
//
//  Created by Josh on 12/19/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
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
#import "MacroController.h"

#import "Unit.h"
#import "Rule.h"
#import "CombatProfile.h"
#import "Behavior.h"

#import "ImageAndTextCell.h"

@interface CombatController ()
@property (readwrite, retain) Unit *attackUnit;
@property (readwrite, retain) Unit *castingUnit;
@property (readwrite, retain) Unit *addUnit;
@end

@interface CombatController (Internal)
- (NSArray*)friendlyUnits;
- (NSRange)levelRange;
- (int)weight: (Unit*)unit PlayerPosition:(Position*)playerPosition;
- (void)stayWithUnit;
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
		
		_enteredCombat = nil;
		
		_inCombat = NO;
		
		_unitsAttackingMe = [[NSMutableArray array] retain];
		_unitsAllCombat = [[NSMutableArray array] retain];
		_unitLeftCombatCount = [[NSMutableDictionary dictionary] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerHasDied:) name: PlayerHasDiedNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(outOfRange:) name: ErrorOutOfRange object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(outOfRange:) name: ErrorTargetNotInLOS object: nil];
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
	[_unitsAllCombat release];
	[_unitLeftCombatCount release];
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
	
	NSDictionary *dict = (NSDictionary*)context;

	NSNumber *w1 = [dict objectForKey:[NSNumber numberWithLongLong:[unit1 GUID]]];
	NSNumber *w2 = [dict objectForKey:[NSNumber numberWithLongLong:[unit2 GUID]]];
	
	int weight1=0, weight2=0;
	
	if ( w1 )
		weight1 = [w1 intValue];
	if ( w2 )
		weight2 = [w2 intValue];
	
	//log(LOG_COMBAT, @"(%@)%d vs. (%@)%d", unit1, weight1, unit2, weight2);
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
    log(LOG_COMBAT, @"------ Player Entering Combat ------");
	
	_inCombat = YES;
}

- (void)playerLeavingCombat: (NSNotification*)notification {
    log(LOG_DEV, @"------ Technically (real) OOC ------");
	
	_inCombat = NO;
	
	[self cancelAllCombat];
}

- (void)playerHasDied: (NSNotification*)notification {
    log(LOG_COMBAT, @"Player has died!");
	
	[self cancelAllCombat];
}

// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	
	// is there a unit we should be attacking
	if ( _castingUnit && [playerData targetID] == [_castingUnit GUID] ){
		log(LOG_BLACKLIST, @"Target not valid, blacklisting %@", _castingUnit);
		[blacklistController blacklistObject: _castingUnit];
	}
}

// target is out of range
- (void)outOfRange: (NSNotification*)notification {
	if ( !_castingUnit || [playerData targetID] != [_castingUnit GUID] ) return;
		
	// try to correct the OOR
	if ([movementController checkUnitOutOfRange:_castingUnit]) {
		// Unit should now be back in range
		log(LOG_COMBAT, @"Looks like we've corrected the out of range issue.");
	} else {
		// Should be no need to blacklist here, if it's OOR it wont't be picked up as a valid target again
		log(LOG_COMBAT, @"Unit is put of range, disengaging.");
		self.attackUnit = nil;
//		[self resetAllCombat];
//		[botController cancelCurrentProcedure];
	}
}

- (void)targetNotInFront: (NSNotification*)notification {
	log(LOG_ERROR, @"AKSJDHAKSDHAKSDHASDHASKDHASLKDHASKDAHSDAHSDLASDJHASKLDHASDLAHSDKLAJSHDAKLJSDH [Combat] Target not in front!");
	log(LOG_ERROR, @"AKSJDHAKSDHAKSDHASDHASKDHASLKDHASKDAHSDAHSDLASDJHASKLDHASDLAHSDKLAJSHDAKLJSDH [Combat] Target not in front!");
	log(LOG_ERROR, @"AKSJDHAKSDHAKSDHASDHASKDHASLKDHASKDAHSDAHSDLASDJHASKLDHASDLAHSDKLAJSHDAKLJSDH [Combat] Target not in front!");
	[movementController establishPlayerPosition];
}

- (void)unitDied: (NSNotification*)notification{
	Unit *unit = [notification object];
	
	if ( unit == _addUnit ) {
		log(LOG_COMBAT, @"[Combat] Removing add %@", unit);
		[_addUnit release]; _addUnit = nil;
	}
}
	
#pragma mark Public

// list of units we're in combat with, NO friendlies
- (NSArray*)combatList{
	
	NSMutableArray *units = [NSMutableArray array];
	
	if ( [_unitsAttackingMe count] ) {
		[units addObjectsFromArray:_unitsAttackingMe];
	}
	
	// add the other units if we need to
	if ( _attackUnit!= nil && ![units containsObject:_attackUnit] && ![blacklistController isBlacklisted:_attackUnit] ){
		[units addObject:_attackUnit];
		log(LOG_DEV, @"Adding attack unit: %@", _attackUnit);
	}
	
	// add our add
	if ( _addUnit != nil && ![units containsObject:_addUnit] && ![blacklistController isBlacklisted:_addUnit] ){
		[units addObject:_addUnit];
		log(LOG_COMBAT, @"[Bot] Adding add unit: %@", _addUnit);
	}
	
	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];
	Position *playerPosition = [playerData position];
	for ( Unit *unit in units ){
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit GUID]]];
	}
	[units sortUsingFunction: WeightCompare context: dictOfWeights];
	
	return [[units retain] autorelease];
}

// out of the units that are attacking us, which are valid for us to attack back?
- (NSArray*)combatListValidated{
	NSArray *units = [self combatList];
	NSMutableArray *validUnits = [NSMutableArray array];
	
	Position *playerPosition = [playerData position];
	float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
	
	for ( Unit *unit in units ){
		
		if ( [blacklistController isBlacklisted:unit] ) {
			log(LOG_COMBAT, @"Not adding blacklisted unit to validated combat list: %@", unit);
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
		
		// range changes if the unit is friendly or not
		float distanceToTarget = [playerPosition distanceToPosition:[unit position]];
		float attackRange = ( botController.theCombatProfile.attackRange > botController.theCombatProfile.engageRange ) ? botController.theCombatProfile.attackRange : botController.theCombatProfile.engageRange;
		float range = ([playerData isFriendlyWithFaction: [unit factionTemplate]] ? botController.theCombatProfile.healingRange : attackRange);
		if ( distanceToTarget > range ){
			continue;
		}
		
		[validUnits addObject:unit];		
	}	
	
	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];
	for ( Unit *unit in validUnits ){
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit GUID]]];
	}
	[validUnits sortUsingFunction: WeightCompare context: dictOfWeights];
	
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
	
	// remember when we started w/this unit
	[_enteredCombat release]; _enteredCombat = [[NSDate date] retain];
	
	
	
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
	
	log(LOG_DEV, @"Now staying with %@", unit);
	
	// we don't need to monitor friendlies!
	if ( ![playerData isFriendlyWithFaction: [unit factionTemplate]] )
		[self stayWithUnit];
}

- (void)stayWithUnit{
	
	log(LOG_DEV, @"Staying with %@ in procedure %@", _castingUnit, [botController procedureInProgress]);
	// cancel other requests
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
	
	if ( _castingUnit == nil ) {
		log(LOG_COMBAT, @"No longer staying w/the unit");
		return;
	}
	
	// dead
	if ( [_castingUnit isDead] ){
		log(LOG_COMBAT, @"Unit is dead! %@", _castingUnit);
		return;
	}
	
	// sanity checks
	if ( ![_castingUnit isValid] || [_castingUnit isEvading] || [blacklistController isBlacklisted:_castingUnit] ) {
		log(LOG_COMBAT, @"STOP ATTACK: Invalid? (%d)  Evading? (%d)  Blacklisted? (%d)", ![_castingUnit isValid], [_castingUnit isEvading], [blacklistController isBlacklisted:_castingUnit]);
		return;
	}
	
	if ( [playerData isDead] ){
		log(LOG_COMBAT, @"You died, stopping attack.");
		return;
	}
	
	// no longer in combat procedure
	if ( ![[botController procedureInProgress] isEqualToString:CombatProcedure] ){
		log(LOG_COMBAT, @"No longer in combat procedure, no longer staying with unit");
		return;
	}
	
	BOOL isCasting = [playerData isCasting];
	
	// check player facing vs. unit position
	Position *playerPosition = [playerData position];
	float playerDirection = [playerData directionFacing];
	float theAngle = [playerPosition angleTo: [_castingUnit position]];
	
	// compensate for the 2pi --> 0 crossover
	if(fabsf(theAngle - playerDirection) > M_PI) {
		if(theAngle < playerDirection)  theAngle        += (M_PI*2);
		else                            playerDirection += (M_PI*2);
	}
	
	// find the difference between the angles
	float angleTo = fabsf(theAngle - playerDirection);
	
	// if the difference is more than 90 degrees (pi/2) M_PI_2, reposition
	if( (angleTo > 0.785f) ) {  // changed to be ~45 degrees
		log(LOG_COMBAT, @"[Combat] Unit is behind us (%.2f). Repositioning.", angleTo);
		
		// set player facing and establish position
		//BOOL useSmooth = [movementController useSmoothTurning];
		
		//if(!isCasting) [movementController pauseMovement];
		[movementController turnTowardObject: _castingUnit];
		//if(!isCasting && !useSmooth) {
		//	[movementController backEstablishPosition];
		//}
	}
	
	if( !isCasting ) {
		
		// ensure unit is our target
		UInt64 unitUID = [_castingUnit GUID];
		//log(LOG_COMBAT, @"[Combat] Not casting 0x%qX 0x%qX", [playerData targetID], unitUID);
		if ( ( [playerData targetID] != unitUID) || [_castingUnit isFeignDeath] ) {
			Position *playerPosition = [playerData position];
			log(LOG_COMBAT, @"[Combat] Targeting %@  Weight: %d", _castingUnit, [self weight:_castingUnit PlayerPosition:playerPosition] );
			
			[playerData setPrimaryTarget: _castingUnit];
			usleep([controller refreshDelay]);
		}
		
		// move toward unit?
		if ( [botController.theBehavior meleeCombat] ){
			
			if ( [playerPosition distanceToPosition: [_castingUnit position]] > 5.0f ){
				log(LOG_COMBAT, @"[Combat] Moving to %@", _castingUnit);
				
				[movementController moveToObject:_castingUnit];	//andNotify: NO
			}
		}
	}
	
	// tell/remind bot controller to attack
	//[botController attackUnit: _castingUnit];
	[self performSelector: @selector(stayWithUnit) withObject: nil afterDelay: 0.25];
}

- (void)cancelAllCombat{
	
	log(LOG_COMBAT, @"[Combat] All combat cancelled");
	
	// cancel selecting the unit!
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(stayWithUnit) object: nil];
	
	// cancel all requests!
	//[NSObject cancelPreviousPerformRequestsWithTarget: self];		// we're not calling this as it kills our monitor function + the death might not be fired!

	// reset our variables
	self.castingUnit = nil;
	self.attackUnit = nil;
	self.addUnit = nil;
	[_friendUnit release];	_friendUnit =  nil;
	
	// remove blacklisted units (TO DO: we should only remove those of type Unit)
	[blacklistController removeAllUnits];
}

- (void)resetAllCombat{
	[self cancelAllCombat];
	[_unitLeftCombatCount removeAllObjects];
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
}

// units here will meet all conditions! Combat Profile WILL be checked
- (NSArray*)validUnitsWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat {
	
	// *************************************************
	//	Find all available units!
	//		Add friendly units
	//		Add Assist unit if we're assisting!
	//		Add hostile/neutral units if we should
	//		Add units attacking us
	// *************************************************
	
	NSMutableArray *allPotentialUnits = [NSMutableArray array];
	
	// add friendly units w/in range
	// only do this if we dont have the onlyHostilesInCombat flag
	if ( ( botController.theCombatProfile.healingEnabled || includeFriendly ) && !onlyHostilesInCombat) {
		log(LOG_COMBAT, @"Adding friendlies to the list of valid units");
		[allPotentialUnits addObjectsFromArray:[self friendlyUnits]];
	}
	
	// only want to add the assist unit
	if ( botController.theCombatProfile.partyEnabled && botController.theCombatProfile.assistUnit && botController.theCombatProfile.assistUnitGUID > 0x0 ) {
		Player *assistPlayer = [playersController playerWithGUID:botController.theCombatProfile.assistUnitGUID];

		if ( assistPlayer && [assistPlayer isValid] && [assistPlayer isInCombat]) {
			UInt64 targetGUID = [assistPlayer targetID];
			// only assist if the assist player is in combat
			if ( targetGUID > 0x0) {
				Mob *mob = [mobController mobWithGUID:targetGUID];
				if ( mob ) {
					[allPotentialUnits addObject:mob];
					log(LOG_COMBAT, @"Adding my assist's target to list of valid units");
				}
			}
		} else {
			log(LOG_COMBAT, @"Player not found for assisting with GUID: 0x%qX", botController.theCombatProfile.assistUnitGUID);
		}
	} else 
	// add new units w/in range if we're not on assist
	if ( botController.theCombatProfile.combatEnabled && ![botController.theCombatProfile onlyRespond] && !onlyHostilesInCombat ) {
		log(LOG_DEV, @"Adding ALL available combat units");
		// determine attack range
		float attackRange = [botController.theCombatProfile engageRange];
		if ( botController.isPvPing && [botController.theCombatProfile attackRange] > [botController.theCombatProfile engageRange] )
			attackRange = [botController.theCombatProfile attackRange];
		[allPotentialUnits addObjectsFromArray:[self enemiesWithinRange:attackRange]];
	}
	
	// remove units attacking us from the list
	if ( [_unitsAttackingMe count] ) [allPotentialUnits removeObjectsInArray:_unitsAttackingMe];
	
	// add combat units that have been validated! (includes attack unit + add)
	NSArray *inCombatUnits = [self combatListValidated];
	if ( [inCombatUnits count] ) {
		log(LOG_DEV, @"Adding %d validated in combat units to list", [inCombatUnits count]);
		for ( Unit *unit in inCombatUnits ) if ( ![allPotentialUnits containsObject:unit] ) [allPotentialUnits addObject:unit];
	}
	
	log(LOG_DEV, @"Found %d potential units to validate", [allPotentialUnits count]);
	
	// *************************************************
	//	Validate all potential units - check for:
	//		Blacklisted
	//		Dead, evading, invalid
	//		Vertical distance
	//		Distance to target
	//		Ghost
	// *************************************************

	NSMutableArray *validUnits = [NSMutableArray array];
	Position *playerPosition = [playerData position];
	
	if ( [allPotentialUnits count] ){
		float vertOffset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistVerticalOffset"] floatValue];
		float distanceToTarget = 0.0f, range = 0.0f;
		BOOL isFriendly = NO;
		
		for ( Unit *unit in allPotentialUnits ){

			if ( [blacklistController isBlacklisted:unit] ) {
				log(LOG_COMBAT, @":Ignoring blacklisted unit: %@", unit);
				continue;
			}

			if ( [unit isDead] || [unit isEvading] || ![unit isValid] ) continue;
			if ( [[unit position] verticalDistanceToPosition: playerPosition] > vertOffset ) continue;
			if ( !includeFriendly && [playerData isFriendlyWithFaction: [unit factionTemplate]] ) continue;
			
			// range changes if the unit is friendly or not
			distanceToTarget = [playerPosition distanceToPosition:[unit position]];
			range = (self.inCombat ? (isFriendly ? botController.theCombatProfile.healingRange : botController.theCombatProfile.attackRange) : botController.theCombatProfile.engageRange);
			if ( distanceToTarget > range ) continue;
			
			// player: make sure they're not a ghost
			if ( [unit isPlayer] ) {
				NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
				if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ) {
					continue;
				}
			}
			
			[validUnits addObject: unit];
		}
		
	}
	
	if ([validUnits count]) log(LOG_DEV, @"Found %d valid units", [validUnits count]);
	// sort
	NSMutableDictionary *dictOfWeights = [NSMutableDictionary dictionary];
	for ( Unit *unit in validUnits ) {
		[dictOfWeights setObject: [NSNumber numberWithInt:[self weight:unit PlayerPosition:playerPosition]] forKey:[NSNumber numberWithUnsignedLongLong:[unit GUID]]];
	}
	[validUnits sortUsingFunction: WeightCompare context: dictOfWeights];	
	return [[validUnits retain] autorelease];
}

// find a unit to attack, CC, or heal
- (Unit*)findUnitWithFriendly:(BOOL)includeFriendly onlyHostilesInCombat:(BOOL)onlyHostilesInCombat {
	
	// flying check?
	if ( [botController.theCombatProfile ignoreFlying] ) if ( ![[playerData player] isOnGround] ) return nil;
	
	// no combat or healing?
	if ( !botController.theCombatProfile.healingEnabled && !botController.theCombatProfile.combatEnabled ) return nil;

	log(LOG_DEV, @"Looking for a valid target");

	NSArray *validUnits = [NSArray arrayWithArray:[self validUnitsWithFriendly:includeFriendly onlyHostilesInCombat:onlyHostilesInCombat]];
	Position *playerPosition = [playerData position];
	
	if ( ![validUnits count] ) return nil;

	int highestWeight = 0;
	Unit *bestUnit = nil;
	for ( Unit *unit in validUnits ) {
		// begin weight calculation
		int weight = [self weight:unit PlayerPosition:playerPosition];
		log(LOG_DEV, @"Valid target %@ found with weight %d", unit, weight);

		// best weight
		if ( weight > highestWeight ) {
			highestWeight = weight;
			bestUnit = unit;
		}
	}
	return bestUnit;	
}

- (NSArray*)allAdds {	
	NSMutableArray *allAdds = [NSMutableArray array];
	
	// loop through units that are attacking us!
	for ( Unit *unit in _unitsAttackingMe ) if ( unit != _attackUnit && ![unit isDead] ) [allAdds addObject:unit];
	
	return [[allAdds retain] autorelease];
}

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
	float attackRange = (botController.theCombatProfile.engageRange > botController.theCombatProfile.attackRange) ? botController.theCombatProfile.engageRange : botController.theCombatProfile.attackRange;
	float distanceToTarget = [playerPosition distanceToPosition:[unit position]];
	BOOL isFriendly = [playerData isFriendlyWithFaction: [unit factionTemplate]];
	
	// begin weight calculation
	int weight = 0;
	
	// player or pet?
	if ([unit isPlayer]) weight += 100;
	
	if ( [unit isPet] ) {
		weight -= 25;
		// we hate pets!
		if ( !botController.theCombatProfile.attackPets ) weight -= 300;
	}

	// health left
	int healthLeft = (100-[unit percentHealth]);
	weight += healthLeft;
	
	// our add?
	if ( unit == _addUnit ) weight -= 100;
		
	// non-friendly checks only
	if ( !isFriendly ) {
		if ( attackRange > 0 ) weight += ( 100 * ((attackRange-distanceToTarget)/attackRange));

		// current target
		if ( [playerData targetID] == [unit GUID] ) weight += 25;

		// Assist mode - assists target
		if ( botController.theCombatProfile.partyEnabled && botController.theCombatProfile.assistUnit && botController.theCombatProfile.assistUnitGUID > 0x0 ) {
			Player *assistPlayer = [playersController playerWithGUID:botController.theCombatProfile.assistUnitGUID];
			if ( assistPlayer && [assistPlayer isValid] && [assistPlayer isInCombat]) {
				UInt64 targetGUID = [assistPlayer targetID];
				if ( targetGUID > 0x0) {
					Mob *assistMob = [mobController mobWithGUID:targetGUID];
					if ( unit == assistMob ) weight += 100;
				}
			}
		}
		
	} else {	
	// friendly?
		// tank gets a pretty big weight @ all times
		if ( botController.theCombatProfile.partyEnabled && botController.theCombatProfile.tankUnit && botController.theCombatProfile.tankUnitGUID == [unit GUID] )
			weight += healthLeft;
		weight *= 1.5;
	}
	return weight;
}
- (NSString*)unitHealthBar: (Unit*)unit {
	// lets build a log prefix that reflects units health
	NSString *logPrefix = nil;
	UInt32 unitPercentHealth = [unit percentHealth];
	
	if ([playerData isFriendlyWithFaction: [unit factionTemplate]]) {		
		if (unitPercentHealth == 100)			logPrefix = @"[+++++++++++]";
			else if (unitPercentHealth >= 90)	logPrefix = @"[++++++++++ ]";
			else if (unitPercentHealth >= 80)	logPrefix = @"[+++++++++  ]";
			else if (unitPercentHealth >= 70)	logPrefix = @"[++++++++   ]";
			else if (unitPercentHealth >= 60)	logPrefix = @"[+++++++    ]";
			else if (unitPercentHealth >= 50)	logPrefix = @"[++++++     ]";
			else if (unitPercentHealth >= 40)	logPrefix = @"[+++++      ]";
			else if (unitPercentHealth >= 30)	logPrefix = @"[++++       ]";
			else if (unitPercentHealth >= 20)	logPrefix = @"[+++        ]";
			else if (unitPercentHealth >= 10)	logPrefix = @"[++         ]";
			else if (unitPercentHealth > 0)		logPrefix = @"[+          ]";
			else								logPrefix = @"[           ]";		
	} else {
		if (unitPercentHealth == 100)			logPrefix = @"[***********]";
			else if (unitPercentHealth >= 90)	logPrefix = @"[********** ]";
			else if (unitPercentHealth >= 80)	logPrefix = @"[*********  ]";
			else if (unitPercentHealth >= 70)	logPrefix = @"[********   ]";
			else if (unitPercentHealth >= 60)	logPrefix = @"[*******    ]";
			else if (unitPercentHealth >= 50)	logPrefix = @"[******     ]";
			else if (unitPercentHealth >= 40)	logPrefix = @"[*****      ]";
			else if (unitPercentHealth >= 30)	logPrefix = @"[****       ]";
			else if (unitPercentHealth >= 20)	logPrefix = @"[***        ]";
			else if (unitPercentHealth >= 10)	logPrefix = @"[**         ]";
			else if (unitPercentHealth > 0)		logPrefix = @"[*          ]";
			else								logPrefix = @"[           ]";
	}
	 return logPrefix;
 }
		 
#pragma mark Enemy

- (int)weight: (Unit*)unit {
	return [self weight:unit PlayerPosition:[playerData position]];
}

// find available hostile targets
- (NSArray*)enemiesWithinRange:(float)range {
	
    NSMutableArray *targetsWithinRange = [NSMutableArray array];
	NSRange levelRange = [self levelRange];

	 // check for mobs?
	 if ( botController.theCombatProfile.attackNeutralNPCs || botController.theCombatProfile.attackHostileNPCs ) {
		 [targetsWithinRange addObjectsFromArray: [mobController mobsWithinDistance: range
																		 levelRange: levelRange
																	   includeElite: !(botController.theCombatProfile.ignoreElite)
																	includeFriendly: NO
																	 includeNeutral: botController.theCombatProfile.attackNeutralNPCs
																	 includeHostile: botController.theCombatProfile.attackHostileNPCs]];
	 }
	
	 // check for players?
	 if ( botController.theCombatProfile.attackPlayers ) {
		 [targetsWithinRange addObjectsFromArray: [playersController playersWithinDistance: range
																				levelRange: levelRange
																		   includeFriendly: NO
																			includeNeutral: NO
																			includeHostile: YES]];
	 }
	
	//log(LOG_COMBAT, @"[Combat] Found %d targets within range", [targetsWithinRange count]);
	
	return targetsWithinRange;
}

#pragma mark Friendly

- (BOOL)validFriendlyUnit: (Unit*)unit{
	
	NSArray *auras = [auraController aurasForUnit: unit idsOnly: YES];
	// regular dead - night elf ghost
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
		//log(LOG_COMBAT, @"[Combat] Friendly is a ghost! And dead! We should consider them invalid");
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
			//log(LOG_COMBAT, @"[Combat] Friendly - Checking %@", unit);
			if ( [self validFriendlyUnit:unit] ){
				//log(LOG_COMBAT, @"[Combat] Valid friendly");
				[friendlyTargets addObject: unit];
			}
        }
    }
	
	//log(LOG_COMBAT, @"[Combat] Total friendlies: %d", [friendlyTargets count]);
	
	return friendlyTargets;
}

#pragma mark Internal

// monitor unit until it dies
- (void)monitorUnit: (Unit*)unit{
	
	// invalid unit
	if ( !unit || ![unit isValid] ) {
		log(LOG_COMBAT, @"Unit isn't valid! %@", unit);
		return;
	}
	
	int leftCombatCount = [[_unitLeftCombatCount objectForKey:[NSNumber numberWithLongLong:[unit GUID]]] intValue];
	// unit left combat?
	if ( ![unit isInCombat] ) {
		log(LOG_DEV, @"%@ Unit not in combat now for %d", [self unitHealthBar: unit], leftCombatCount);
		leftCombatCount++;
		
		// If it's our target let's do some checks as we should be in combat
		if ( unit == _attackUnit ) {

			// not in combat after 5 seconds try moving forward to unbug casting
			if ( leftCombatCount < 100 && leftCombatCount > 50) {
				// Try Stepping forward in case we're just position bugged for casting
				if (![playerData isCasting] && ![movementController isMoving]) {
					log(LOG_COMBAT, @"%@ stepping forward to try to unbug a bad casting position.", [self unitHealthBar: unit]);
					[movementController stepForward];
				}
			} else 
			// not in combat after 10 seconds we blacklist
			if ( leftCombatCount > 100 ) {
				log(LOG_COMBAT, @"%@ Unit not in combat after 10 seconds, blacklisting", [self unitHealthBar: unit]);
				[blacklistController blacklistObject:unit withReason:Reason_NotInCombatAfter10];
				self.attackUnit = nil;
				return;
			}
		}
		// after a minute stop monitoring
		if ( leftCombatCount > 600 ){
			log(LOG_COMBAT, @"%@ No longer monitoring %@, unit didn't enter combat after a minute!", [self unitHealthBar: unit], unit);
			return;
		}
	} else {
		log(LOG_COMBAT, @"%@ Monitoring %@", [self unitHealthBar: unit], unit);
		leftCombatCount = 0;
	}
	[_unitLeftCombatCount setObject:[NSNumber numberWithInt:leftCombatCount] forKey:[NSNumber numberWithLongLong:[unit GUID]]];
	
	
	// unit died, fire off notification
	if ( [unit isDead] ){
		log(LOG_DEV, @"Firing death notification for unit %@", unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}
	
	// unit has ghost aura (so is dead, fire off notification
	NSArray *auras = [[AuraController sharedController] aurasForUnit: unit idsOnly: YES];
	if ( [auras containsObject: [NSNumber numberWithUnsignedInt: 8326]] || [auras containsObject: [NSNumber numberWithUnsignedInt: 20584]] ){
		log(LOG_COMBAT, @"%@ Firing death notification for player %@", [self unitHealthBar: unit], unit);
		[[NSNotificationCenter defaultCenter] postNotificationName: UnitDiedNotification object: [[unit retain] autorelease]];
		return;
	}
	
	[self performSelector:@selector(monitorUnit:) withObject:unit afterDelay:0.1f];
}

// find all units we are in combat with
- (void)doCombatSearch{
	
	if ( [[playerData player] isDead] ){
		
		log(LOG_COMBAT, @"Dead, removing all objects!");
		
		[_unitsAttackingMe removeAllObjects];
		self.attackUnit = nil;
		self.addUnit = nil;
		self.castingUnit = nil;
		
		return;
	}
	
	// add all mobs + players
	NSArray *mobs = [mobController allMobs];
	NSArray *players = [playersController allPlayers];
	
	UInt64 playerGUID = [[playerData player] GUID];
	UInt64 unitTarget = 0;
	BOOL playerHasPet = [[playerData player] hasPet];
	BOOL tapCheckPassed = YES;
	
	for ( Mob *mob in mobs ){
		tapCheckPassed = YES;
		unitTarget = [mob targetID];
		
		if ([mob isTappedByOther] && !botController.theCombatProfile.partyEnabled && !botController.isPvPing) tapCheckPassed = NO;
		
		if (
			![mob isDead]	&&		// 1 - living units only
			[mob isInCombat] &&		// 2 - in Combat
			[mob isSelectable] &&	// 3 - can select this target
			[mob isAttackable] &&	// 4 - attackable
			//[mob isTapped] &&		// 5 - tapped - in theory someone could tap a target while you're casting, and you get agg - so still kill (removed as a unit @ 100% could attack us and not be tapped)
			tapCheckPassed &&	// lets give this one a go
			[mob isValid] &&		// 6 - valid mob
			(	(unitTarget == playerGUID ||										// 7 - targetting us
				 (playerHasPet && unitTarget == [[playerData player] petGUID]) ) ||	// or targetting our pet
			 [mob isFleeing])													// or fleeing
			){
			
			// add mob!
			if ( ![_unitsAttackingMe containsObject:(Unit*)mob] ){
				log(LOG_COMBAT, @"Adding mob %@", mob);
				[_unitsAttackingMe addObject:(Unit*)mob];
				[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[mob retain] autorelease]];
			}
		}
		// remove unit
		else if ( [_unitsAttackingMe containsObject:(Unit*)mob] ) {
			log(LOG_COMBAT, @"[Combat] Removing mob %@", mob);
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
				log(LOG_COMBAT, @"[Combat] Adding player %@", player);
				[_unitsAttackingMe addObject:(Unit*)player];
				[[NSNotificationCenter defaultCenter] postNotificationName: UnitEnteredCombat object: [[player retain] autorelease]];
			}
		}
		// remove unit
		else if ( [_unitsAttackingMe containsObject:(Unit*)player] ) {
			log(LOG_COMBAT, @"[Combat] Removing player %@", player);
			[_unitsAttackingMe removeObject:(Unit*)player];
		}
	}
	
	// double check to see if we should remove any!
	NSMutableArray *unitsToRemove = [NSMutableArray array];
	for ( Unit *unit in _unitsAttackingMe ){
		if ( !unit || ![unit isValid] || [unit isDead] || ![unit isInCombat] || ![unit isSelectable] || ![unit isAttackable] ){
			log(LOG_COMBAT, @"[Combat] Removing unit: %@", unit);
			[unitsToRemove addObject:unit];
		}
	}
	if ( [unitsToRemove count] ){
		[_unitsAttackingMe removeObjectsInArray:unitsToRemove];
	}
	
	log(LOG_DEV, @"In combat with %d units", [_unitsAttackingMe count]);
	
	for ( Unit *unit in _unitsAttackingMe ){
		log(LOG_DEV, @"	%@", unit);
	}
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
		
		NSArray *allUnits = [self validUnitsWithFriendly:YES onlyHostilesInCombat:NO];
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
