//
//  CombatController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/18/07.
//  Copyright 2007 Savory Software, LLC. All rights reserved.
//

#import "CombatController.h"
#import "PlayerDataController.h"
#import "MovementController.h"
#import "Controller.h"
#import "BotController.h"
#import "MobController.h"
#import "ChatController.h"
#import "Unit.h"
#import "Mob.h"
#import "Player.h"
#import "CombatProfile.h"
#import "PlayersController.h"

@interface CombatController ()
@property BOOL inCombat;
@property (readwrite, retain) Unit *attackUnit;
@end

@interface CombatController (Internal)
- (void)verifyCombatUnits: (BOOL)purgeCombat;
- (void)verifyCombatState;
- (void)attackBestTarget: (BOOL)establishPosition;
- (void)finishUnit: (Unit*)mob;

// data structure access
- (BOOL)addUnitToAttackQueue: (Unit*)mob;
- (BOOL)removeUnitFromAttackQueue: (Unit*)mob;
//- (BOOL)addUnitToCombatList: (Unit*)unit;
//- (BOOL)removeUnitFromCombatList: (Unit*)unit;

- (Unit*)findBestUnitToAttack;
- (BOOL)addUnitToCombatQueue: (Unit*)unit;
- (BOOL)removeUnitFromCombatQueue: (Unit*)unit;

- (void)refreshBlacklist;
- (int)blacklistCountForUnit: (Unit*)unit;
- (void)removeUnitFromBlacklist: (Unit*)mob;
@end

@implementation CombatController

- (id) init
{
    self = [super init];
    if (self != nil) {
        _inCombat = NO;
        _combatEnabled = NO;
        _technicallyOOC = YES;
        _attemptingCombat = NO;
        //_combatUnits = [[NSMutableArray array] retain];
        _attackQueue = [[NSMutableArray array] retain];
        _blacklist = [[NSMutableArray array] retain];
		_unitsAttackingMe = [[NSMutableArray array] retain];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(outOfRange:) name: ErrorOutOfRange object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetNotInFront:) name: ErrorTargetNotInFront object: nil];
    }
    return self;
}

@synthesize inCombat = _inCombat;
@synthesize attackUnit = _attackUnit;
@synthesize combatEnabled = _combatEnabled;

#pragma mark from PlayerData Controller
- (void)concludeCombat {
	PGLog(@"------ Player Leaving Combat ------ (conclude combat)");
	
    // lets stop everything and tell the botController
    self.inCombat = NO;
    self.attackUnit = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [botController playerLeavingCombat];
}

#pragma mark State

/*- (NSArray*)combatUnits {
 return [[_combatUnits retain] autorelease];
 }*/
- (NSArray*)attackQueue {
    return [[_attackQueue retain] autorelease];
}

- (NSArray*)unitsAttackingMe {
    return [[_unitsAttackingMe retain] autorelease];
}


#pragma mark (Internal) State Maintenence

- (void)verifyCombatState {
    // this function is (basically) disabled for now
    
    if( [_attackQueue count]) {
        [self attackBestTarget: YES];
        return;
    }
}

// The sole purpose of verifyCombatUnits is to validate the units currently being tracked for combat purposes
// this includes the complete list of combat units, as well as the attack queue
- (void)verifyCombatUnits: (BOOL)purgeCombat {
    NSMutableArray *unitsToRemove = [NSMutableArray array];
    
    // We want to remove:
    // * Blacklisted
    // * Dead
    // * Not in combat
    // * Invalid
    // * Evading
    // * Tapped by others
    
    for(Unit* unit in _attackQueue) {
        // remove the unit if it's invalid, blacklisted, dead, evading or no longer in combat
        if( ![unit isValid] || [self isUnitBlacklisted: unit] || [unit isDead] || [unit isEvading] || [unit isTappedByOther] || ![unit isInCombat] ) {
            PGLog(@"[Combat] [A] Removing %@  NotValid?(%d) Blacklisted?(%d) Dead?(%d) Evading?(%d) TappedByOther?(%d) NotInCombat?(%d)", unit, ![unit isValid], [self isUnitBlacklisted: unit], [unit isDead], [unit isEvading], [unit isTappedByOther], ![unit isInCombat]);
			[unitsToRemove addObject: unit];
        }
    }
    
    for(Unit* unit in unitsToRemove) {
        // this removes the unit from the attack queue as well
        [self finishUnit: unit];
    }
    
    if([unitsToRemove count]) { 
		PGLog(@"[Combat] %d attacking me; %d in attack queue.", [_unitsAttackingMe count], [_attackQueue count]);
		
		if( ![self inCombat] && ([_unitsAttackingMe count] == 0) && ([_attackQueue count] == 0)) {
			PGLog(@"[Combat] We are neither in combat nor have any remaining targets.");
			[self concludeCombat];
		}
		else{
			PGLog(@"[Combat] Still in combat!");
		}
    }
}

#pragma mark Internal

- (void)combatCheck: (Unit*)unit {
    if ( !unit ) {
		PGLog(@"[Combat] No unit %@ to attack!", unit);
		return;
	}
    
    // cancel any other pending checks for this unit
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
    
	if ( [unit isDead] ){
		PGLog(@"[Combat] Unit %@ dead, cancelling combatCheck", unit);
		return;
	}
	
    // if the unit is either not in combat, or is evading
    if( ![unit isInCombat] || [unit isEvading] || ![unit isAttackable] ) { 
        PGLog(@"[Combat] -XX- Unit %@ not in combat (%d), evading (%d), or not attackable(%d), blacklisting.", unit, ![unit isInCombat], [unit isEvading], ![unit isAttackable] );
        [self blacklistUnit: unit];
        return;
    }
	
	// we should be checking other things here
	//	has the unit's health not dropped?
	//	check vertical distance?
    
    /*float currentDistance = [[playerData position] distanceToPosition2D: [unit position]];
    if( botController.theCombatProfile.attackRange < currentDistance ) {
		PGLog(@"[Combat] -XX- Unit %@ distance (%.2f) is greater than the attack distance (%.2f).", unit, currentDistance, botController.theCombatProfile.attackRange);
        [self blacklistUnit: unit];
        return;
    }*/
    
    // keep pulsing the combat check every second
    [self performSelector: @selector(combatCheck:)
               withObject: unit
               afterDelay: 1.0f];
}

- (void)attackTheUnit: (Unit*)unit {
    if(![unit isValid] || [unit isDead] || [unit isEvading] || [self isUnitBlacklisted:unit]) {
		PGLog(@"STOP ATTACK: Invalid? (%d)  Dead? (%d)  Evading? (%d)  Blacklisted? (%d)", ![unit isValid], [unit isDead], [unit isEvading], [self isUnitBlacklisted:unit]);
		[self finishUnit:unit];
		return;
	}
	
	// o noes you died!
	if ( [playerData isDead] ){
		PGLog(@"[Combat] You died, stopping attack.");
		return;
	}
    
    if(self.attackUnit != unit){
		PGLog(@"[Combat] No longer attacking %@, cancelling attack", unit);
		return;
	}
    
    BOOL isCasting = [playerData isCasting];
    
    // check player facing vs. unit position
    float playerDirection = [playerData directionFacing];
    float theAngle = [[playerData position] angleTo: [unit position]];
    
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
        [movementController turnTowardObject: unit];
        if(!isCasting && !useSmooth) {
            [movementController backEstablishPosition];
        }
    }
	
    if( !isCasting ) {
        // ensure unit is our target
        UInt64 unitUID = [unit GUID];
        if ( ( [playerData targetID] != unitUID) || [unit isFeignDeath] ) {
			Position *playerPosition = [playerData position];
			PGLog(@"SELECTING (com) %@  Weight: %d", unit, [self unitWeight:unit PlayerPosition:playerPosition] );
            
            [playerData setPrimaryTarget: unit];
            usleep([controller refreshDelay]);
        }
    }
    
    // tell/remind bot controller to attack
    [botController attackUnit: unit];
    [self performSelector: @selector(attackTheUnit:) withObject: unit afterDelay: 0.25];
}

#pragma mark Notifications

- (void)playerEnteringCombat: (NSNotification*)notification {
    PGLog(@"------ Player Entering Combat ------");
    self.inCombat = YES;
    _technicallyOOC = NO;
    
    // find who we are in combat with
    if([self combatEnabled] && ([[self unitsAttackingMe] count] == 0)) {
        PGLog(@"[Combat] Rescan targets because we are in combat, but have no known targets.");
		[self doCombatSearch];
    }
	
    if(![_attackQueue count]) {
        [botController playerEnteringCombat];
    } else {
        [self attackBestTarget: NO];
    }
}

- (void)playerLeavingCombat: (NSNotification*)notification {
    PGLog(@"------ Technically (real) OOC ------");
    _technicallyOOC = YES;
    
    // get rid of any unit still classified as in combat
    [self verifyCombatUnits: YES];
    [self verifyCombatState];
    
    // dump everything
    [_unitsAttackingMe removeAllObjects];
    [_attackQueue removeAllObjects];
	
    [self concludeCombat];
}

// invalid target
- (void)invalidTarget: (NSNotification*)notification {
	
	// is there a unit we should be attacking
	if ( self.attackUnit && [playerData targetID] == [self.attackUnit GUID] ){
		PGLog(@"[Combat] Target not valid, blacklisting %@", self.attackUnit);
		[self blacklistUnit: self.attackUnit];
		[self finishUnit:self.attackUnit];
	}
}

// target is out of range
- (void)outOfRange: (NSNotification*)notification {
	
	// We should blacklist this guy?
	if ( self.attackUnit ){

		// is this who we are currently attacking?
		if ( [playerData targetID] == [self.attackUnit GUID] ){
			PGLog(@"[Combat] Out of range, blacklisting %@", self.attackUnit);
			[self blacklistUnit: self.attackUnit];
			[self finishUnit:self.attackUnit];
		}
	}
}

- (void)targetNotInFront: (NSNotification*)notification {
	PGLog(@"[Combat] Target not in front!");
}


#pragma mark Blacklist

- (void)blacklistUnit: (Unit*)unit {
    [self refreshBlacklist];
    int blackCount = [self blacklistCountForUnit: unit];
    if( blackCount == 0 ) {
        PGLog(@"[Combat] Blacklisting %@ for 15 seconds. Strike 1.", unit);
        [_blacklist addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                unit,                                       @"Unit", 
                                [NSDate date],                              @"Date", 
                                [NSNumber numberWithInt: 1],                @"Count", nil]];
    } else {
        // the blacklist already contains this unit!
        [self removeUnitFromBlacklist: unit];
        PGLog(@"[Combat] Blacklisting %@ again. Strike %d.", unit, blackCount + 1);
        [_blacklist addObject: [NSDictionary dictionaryWithObjectsAndKeys: 
                                unit,                                       @"Unit", 
                                [NSDate date],                              @"Date", 
                                [NSNumber numberWithInt: blackCount + 1],   @"Count", nil]];
    }
    
    // if we're not in combat after we blacklist something...
    // then we need to trigger a leaving combat notification
    if( ![self inCombat] ) {
        PGLog(@"[Combat] Not in combat after blacklisting; concluding combat.");
        [self playerLeavingCombat:nil];
    }
}

- (int)blacklistCountForUnit: (Unit*)unit {
    for(NSDictionary *black in _blacklist) {
        if( [[black objectForKey: @"Unit"] isEqualToObject: unit]) {
            return [[black objectForKey: @"Count"] intValue];
        }
    }
    return 0;
}

- (BOOL)isUnitBlacklisted: (Unit*)unit {
    int count = [self blacklistCountForUnit: unit];
    if(count == 0)  return NO;
    if(count >= 3)  return YES;
    
    // check the time on the blacklist
    for(NSDictionary *black in _blacklist) {
        if([[black objectForKey: @"Unit"] isEqualToObject: unit]) {
            int count = [[black objectForKey: @"Count"] intValue];
            if(count < 1) count = 1;
            if( [[black objectForKey: @"Date"] timeIntervalSinceNow]*-1.0 > (15.0*count)) 
                return NO;
        }
    }
    
    return YES;
}

- (void)removeUnitFromBlacklist: (Unit*)unit {
    
    NSMutableArray *blRemove = [NSMutableArray array];
    for(NSDictionary *black in _blacklist) {
        if([[black objectForKey: @"Unit"] isEqualToObject: unit])
            [blRemove addObject: black];
    }
    [_blacklist removeObjectsInArray: blRemove];
}

- (void)refreshBlacklist {
    // remove invalid or dead entries
    NSMutableArray *blRemove = [NSMutableArray array];
    for(NSDictionary *black in _blacklist) {
        Unit *unit = [black objectForKey: @"Unit"];
        if( ![unit isValid] || [unit isDead] ) {
            [blRemove addObject: black];
        }
    }
    [_blacklist removeObjectsInArray: blRemove];
}


#pragma mark from BotController

- (void)disposeOfUnit: (Unit*)unit {
    if(!self.combatEnabled) return;
	
    // refresh blacklist
    [self refreshBlacklist];
    BOOL isBlacklisted = [self isUnitBlacklisted: unit];
	
    if(![unit isValid]) { // if we were sent a bad unit
        PGLog(@"[Combat] Unit to attack is not valid!");
        return;
    } else {
        if(isBlacklisted) {
            PGLog(@"[Combat] Blacklisted unit %@ will not be fought.", unit);
			return;
        }
        
        if( [unit isDead]) {
            PGLog(@"[Combat] Cannot attack a dead unit %@.", unit);
            [self blacklistUnit: unit];
            return;
        }
		
        if( [unit isEvading]) {
            PGLog(@"[Combat] %@ appears to be evading...", unit);
            [self blacklistUnit: unit];
            return;
        }
    }
    
    if( ![self.attackUnit isEqualToObject: unit]) {
        if([self addUnitToAttackQueue: unit]) {
			PGLog(@"[Combat] disposeOfUnit: %@ 0", unit);
            [self attackBestTarget: NO];
        } else {
			PGLog(@"[Combat] disposeOfUnit: %@ 1", unit);
            [self attackBestTarget: YES];
        }
    }
	else{
		PGLog(@"[Combat] Already attacking %@, ignoring disposeOfUnit", unit);
	}
	
	return;
}

- (void)cancelAllCombat {
    PGLog(@"[Combat] Clearing all combat state.");
    self.attackUnit = nil;
    [_blacklist removeAllObjects];
    [_attackQueue removeAllObjects];
	[_unitsAttackingMe removeAllObjects];
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
}

#pragma mark Attack


- (void)attackBestTarget: (BOOL)establishPosition {
    if(!self.combatEnabled) return;
	
    // get the next unit from the attack queue
    Unit *unit = [self findBestUnitToAttack];
	if ( !unit ) {
		PGLog(@"[Combat] Not able to find a unit to attack!");
		return;
	}
    
	// if we're not attacking this unit already
    if( ![self.attackUnit isEqualToObject: unit] ) {
		
        if(![playerData isCasting]) {
            [movementController pauseMovement];
            [movementController turnTowardObject: unit];
            usleep( [controller refreshDelay] );
            
            // either move forward or backward
            if(establishPosition) [movementController backEstablishPosition];
            else                  [movementController establishPosition];
        }
        
        // cancel previous perform requests
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: self.attackUnit];
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
        
        PGLog(@"[Combat] Commence attack on %@. (0x%X:0x%X)", unit, [unit unitBytes1], [unit unitBytes2]);
		self.attackUnit = unit;
        [self attackTheUnit: unit];
        
        // if we aren't in combat after X seconds, something is wrong
        float delay = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistDelay"] floatValue];
        [self performSelector: @selector(combatCheck:)
                   withObject: unit
                   afterDelay: delay];
    } else {
        // we're already attacking this unit
		//PGLog(@"[Combat] Already attacking %@", unit);
    }
}


- (void)finishUnit: (Unit*)unit {
    if ( unit == nil ) {
		PGLog(@"[Combat] Unable to finish a nil unit!");
		return;
	}
    
    if([self.attackUnit isEqualToObject: unit]) {
        self.attackUnit = nil;
		PGLog(@"[Combat] Finishing our current target %@", unit);
    }
    
    // make sure the unit sticks around until we're done with it
    [[unit retain] autorelease];
    
    // unregister callbacks to this controller
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(attackTheUnit:) object: unit];
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
    
    // remove from the attack queue & combat list
    BOOL wasInAttackQueue = [_attackQueue containsObject: unit];
    [self removeUnitFromAttackQueue: unit];
    
    // tell the bot controller
    [botController finishUnit: unit wasInAttackQueue: wasInAttackQueue];
}

#pragma mark Data Structure Access

// units will ONLY be added to the attack queue from botController
- (BOOL)addUnitToAttackQueue: (Unit*)unit {
    if( ![_attackQueue containsObject: unit] ) {
        [_attackQueue addObject: unit];
        float dist = [[playerData position] distanceToPosition2D: [unit position]];
        PGLog(@"[Combat] ---> [A] Adding %@ at %.2f", unit, dist);
        return YES;
    } else {
		PGLog(@"[Combat] Unit %@ already exists in the attack queue", unit);
        return NO;
    }
}

- (BOOL)removeUnitFromAttackQueue: (Unit*)unit {
    if([_attackQueue containsObject:unit]) {
        PGLog(@"[Combat] <--- [A] Removing %@", unit);
        [_attackQueue removeObject: unit];
        return YES;
    }
    return NO;
}

int DistanceFromPositionCmp(id <UnitPosition> unit1, id <UnitPosition> unit2, void *context) {
    
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
- (UInt32)unitWeight: (Unit*)unit PlayerPosition:(Position*)playerPosition{
	float attackRange = botController.theCombatProfile.attackRange;
	float distanceToTarget = [playerPosition distanceToPosition:[unit position]];
	
	// begin weight calculation
	int weight = 0;
	
	// player or pet?
	if ([unit isPlayer])
		weight += 100;
	else if ([unit isPet])
		weight += 25;
	
	// current target
	if ( [playerData targetID] == [unit GUID] )
		weight += 25;
	
	// health left
	weight += (100-[unit percentHealth]);
	
	// distance to target
	if ( attackRange > 0 )
		weight += ( 100 * ((attackRange-distanceToTarget)/attackRange));
	
	return weight;	
}

// assumptions: combat is enabled
- (Unit*)findBestUnitToAttack{
	if ( ![botController isBotting] )	return nil;
	if ( ![self combatEnabled] )		return nil;
	
	// grab all units we're in combat with
	NSMutableArray *units = [NSMutableArray array];
	[units addObjectsFromArray:_unitsAttackingMe];
	// add new mobs which are in the attack queue
	for ( Unit *unit in _attackQueue ){
		if ( ![units containsObject:unit] ){
			[units addObject:unit];
		}
	}
	
	// sort units by position
	Position *playerPosition = [playerData position];
	[units sortUsingFunction: DistanceFromPositionCmp context: playerPosition];
	//PGLog(@"[Combat] Units in queue or attacking me: %d (Queue:%d) (Me:%d)", [units count], [_attackQueue count], [_unitsAttackingMe count]);
	
	// lets find the best target
	if ( [units count] ){
		float distanceToTarget = 0.0f;
		float attackRange = botController.theCombatProfile.attackRange;
		int highestWeight = 0;
		Unit *bestUnit = nil;
		
		for ( Unit *unit in units ){
			distanceToTarget = [playerPosition distanceToPosition:[unit position]];
			
			// only check targets that are close enough
			if ( distanceToTarget > attackRange ){
				continue;
			}
			
			// ignore blacklisted units
			if ( [self isUnitBlacklisted:unit] ){
				continue;
			}
			
			// ignore dead/evading/not valid units
			if ( [unit isDead] || [unit isEvading] || ![unit isValid] ){
				continue;
			}
			
			// begin weight calculation
			int weight = [self unitWeight:unit PlayerPosition:playerPosition];
			//PGLog(@"[Combat] Valid target %@ found %0.2f yards away with weight %d", unit, distanceToTarget, weight);
			
			// best weight
			if ( weight > highestWeight ){
				highestWeight = weight;
				bestUnit = unit;
			}
		}
		
		// make sure the unit sticks around until we're done with it
		[[bestUnit retain] autorelease];
		return bestUnit;
	}
	
	// no targets found
	return nil;	
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
			
			//PGLog(@"[Combat] In combat with mob %@", mob);
			
			// add mob!
			[self addUnitToCombatQueue: (Unit*)mob];
		}
		// remove unit
		else{
			[self removeUnitFromCombatQueue:(Unit*)mob];
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
			
			//PGLog(@"[Combat] In combat with player %@", player);
			
			// add player
			[self addUnitToCombatQueue:player];
		}
		// remove unit
		else{
			[self removeUnitFromCombatQueue:player];
		}
	}
	
	// verify units we're in combat with!
	[self verifyCombatUnits: NO];
	[self verifyCombatState];
	
	//PGLog(@"[Combat] In combat with %d units", [_unitsAttackingMe count]);
}

- (BOOL)addUnitToCombatQueue: (Unit*)unit{
	if ( ![_unitsAttackingMe containsObject: unit] ){
		[_unitsAttackingMe addObject:unit];
		[self removeUnitFromBlacklist: unit];	// TO DO: should this really be here?  stuck in infinite add/remove?
		PGLog(@"[Combat] Adding ---> [C] %@ (%d total)", unit, [_unitsAttackingMe count]);
		return YES;
	}
	return NO;
}

- (BOOL)removeUnitFromCombatQueue: (Unit*)unit{
	if ([_unitsAttackingMe containsObject: unit]){
		[_unitsAttackingMe removeObject: unit];
		PGLog(@"[Combat] Removing <--- [C] %@", unit);
		return YES;		
	}
	return NO;			 
}

@end
