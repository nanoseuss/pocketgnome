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
#import "PlayersController.h"
#import "MacroController.h"

#import "Unit.h"
#import "Mob.h"
#import "Player.h"
#import "CombatProfile.h"
#import "Offsets.h"

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
- (Unit*)getUnitFromAttackQueue;
- (BOOL)addUnitToAttackQueue: (Unit*)mob;
- (BOOL)removeUnitFromAttackQueue: (Unit*)mob;
- (BOOL)addUnitToCombatList: (Unit*)unit;
- (BOOL)removeUnitFromCombatList: (Unit*)unit;

- (float)initialDistanceForUnit: (Unit*)unit;

- (void)refreshBlacklist;
- (int)blacklistCountForUnit: (Unit*)unit;
- (void)blacklistUnit: (Unit*)mob;
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
		_lastWasBackEstablish = NO;
        _combatUnits = [[NSMutableArray array] retain];
        _attackQueue = [[NSMutableArray array] retain];
        _blacklist = [[NSMutableArray array] retain];
		_unitsAttackingMe = [[NSMutableArray array] retain];
        _initialDistances = [[NSMutableDictionary dictionary] retain];
		_combatDictionaryWithWeights = [[NSMutableDictionary dictionary] retain];;
        
        //[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
        //[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(invalidTarget:) name: ErrorInvalidTarget object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(outOfRange:) name: ErrorOutOfRange object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(errorTargetNotInFront:) name: ErrorTargetNotInFront object: nil];
		
    }
    return self;
}

@synthesize inCombat = _inCombat;
@synthesize attackUnit = _attackUnit;
@synthesize combatEnabled = _combatEnabled;

#pragma mark from PlayerData Controller
- (void)playerEnteringCombat {
    if(botController.isBotting) PGLog(@"------ Player Entering Combat ------");
    self.inCombat = YES;
    _technicallyOOC = NO;
    
    // make the mob controller rescal
    if([self combatEnabled] && ([[self combatUnits] count] == 0)) {
        // PGLog(@"[Combat] Rescan mobs because we are in combat, but have no known targets.");
        // [mobController enumerateAllMobs];
        [mobController doCombatScan];
    }

    if(![_attackQueue count]) {
        [botController playerEnteringCombat];
    } else {
        [self attackBestTarget: NO];
    }
}

- (void)concludeCombat {
    // lets stop everything and tell the botController
    self.inCombat = NO;
    self.attackUnit = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    if(botController.isBotting) PGLog(@"------ Player Leaving Combat ------ (conclude combat)");
    [botController playerLeavingCombat];
}

- (void)playerLeavingCombat {
    if(botController.isBotting) PGLog(@"------ Technically OOC ------");
    _technicallyOOC = YES;
    
    // get rid of any unit still classified as in combat
    [self verifyCombatUnits: YES];
    [self verifyCombatState];
    
    // dump everything
    //[_combatUnits removeAllObjects];
    //[_attackQueue removeAllObjects];

    [self concludeCombat];
}

#pragma mark State

- (NSArray*)combatUnits {
    return [[_combatUnits retain] autorelease];
}
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
    
    return;
    
    if(self.inCombat && _technicallyOOC && ![_combatUnits count] && ![_attackQueue count] && ![playerData isInCombat]) {
        if(self.inCombat) {
            [NSObject cancelPreviousPerformRequestsWithTarget: self];
            self.inCombat = NO;
            if(botController.isBotting) PGLog(@"------ Player Leaving Combat ------ (verifyCombatState)");
            [botController playerLeavingCombat];
            return;
        }
    } else {
        if( [_attackQueue count]) {
            [self attackBestTarget: YES];
            return;
        }
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
    
    // first, verify our list of combat units
    for(Unit* unit in _combatUnits) {
        if( purgeCombat || ![unit isValid] || [self isUnitBlacklisted: unit] || [unit isDead] || (![unit isFeignDeath] && ![unit isInCombat]) || [unit isEvading] || [unit isTappedByOther]) {
            //PGLog(@"[Combat] <--- [C] %@ has been killed or left combat.", unit);
            [unitsToRemove addObject: unit];
        }
    }

    for(Unit* unit in _attackQueue) {
        // remove the unit if it's invalid, blacklisted, dead, evading or no longer in combat
        if( ![unit isValid] || [self isUnitBlacklisted: unit] || [unit isDead] || [unit isEvading] || [unit isTappedByOther] ) {
            //PGLog(@"[Combat] <--- [A] %@ has been killed or left combat.", unit);
            if(![unitsToRemove containsObject: unit])
                [unitsToRemove addObject: unit];
        }
    }
    
    for(Unit* unit in unitsToRemove) {
        // this removes the unit from the attack queue as well
        [self finishUnit: unit];
    }
    
    if([unitsToRemove count]) { 
        if(botController.isBotting) {
            PGLog(@"[Combat] %d in combat; %d in attack queue.", [_combatUnits count], [_attackQueue count]);
            
            if( ![self inCombat] && ([_combatUnits count] == 0) && ([_attackQueue count] == 0)) {
                PGLog(@"[Combat] We are neither in combat nor have any remaining targets.");
                [self concludeCombat];
            }
        }
    }
    
}

#pragma mark from Mob Controller

- (void)setInCombatUnits: (NSArray*)units {
    
    // add units to our list
    Player *player = [playerData player];
    
    for(Unit* unit in units) {
        GUID targetID = [unit targetID];
        if(   self.inCombat                                                 // if we're in combat
           && ![_combatUnits containsObject: unit]                          // if we aren't already tracking the unit
           && ![unit isTappedByOther]                                       // it's not tapped by somebody else
           && ((targetID > 0) || [unit isFleeing] )                         // if it has SOMETHING targeted or is fleeing
           && (   (targetID == [player GUID])                               // if it has us targeted
               || ([player hasPet] && (targetID == [player petGUID])))      // ... or our pet
           ) {
            if([self addUnitToCombatList: unit]) {
                [botController addingUnit: unit];
				
				PGLog(@"[Combat] Adding %@ to combat list!", unit);
            }
            // disabled for now.
            //if([self combatEnabled])
            //    [self addUnitToAttackQueue: unit];
        }
    }
    
    [self verifyCombatUnits: NO];
    [self verifyCombatState];
}

#pragma mark Internal

- (void)combatCheck: (Unit*)unit {
    if(!unit) return;
    
    // cancel any other pending checks for this unit
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
    
    // if the unit is either not in combat, or is evading
    if( ![unit isInCombat] || [unit isEvading] || ![unit isAttackable] ) { 
        if(botController.isBotting) PGLog(@"[Combat] -XX- Unit %@ not in combat.", unit);
        [self blacklistUnit: unit];
        return;
    }
	/*
	if ( [botController targetNotInLOSAttempts] > 5 ){
        if(botController.isBotting) PGLog(@"[Combat] -XX- Unit %@ not in line of site.", unit);
        [self blacklistUnit: unit];
        return;
	}*/
    
    float currentDistance = [[playerData position] distanceToPosition2D: [unit position]];
    if( ([self initialDistanceForUnit: unit] < currentDistance) && ( botController.theCombatProfile.attackRange < currentDistance) ) {
        if(botController.isBotting)
            PGLog(@"[Combat] -XX- Unit %@ distance (%.2f) is greater than both initial distance (%.2f) and attack distance (%.2f).", 
                  unit, 
                  currentDistance, 
                  [self initialDistanceForUnit: unit], 
                  botController.theCombatProfile.attackRange);
        [self blacklistUnit: unit];
        return;
    }
    
    // keep pulsing the combat check every 5 seconds
    [self performSelector: @selector(combatCheck:)
               withObject: unit
               afterDelay: 5.0f];
}

- (void)attackTheUnit: (Unit*)unit {
    if(![unit isValid] || [unit isDead]) return;
	
	// shouldn't be mounted when attacking!
	if ( [[playerData player] isMounted] ){
		[movementController dismount];
	}
    
    if(self.attackUnit != unit)
        self.attackUnit = unit;
    
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
        if(botController.isBotting) PGLog(@"[Combat] Unit is behind us (%.2f). Repositioning.", angleTo);
        
        // set player facing and establish position
        BOOL useSmooth = [movementController useSmoothTurning];
        
        if(!isCasting) [movementController pauseMovement];
        [movementController turnTowardObject: unit];
        if(!isCasting && !useSmooth) {
            [movementController backEstablishPosition];
        }
    } else {
        //[playerData faceToward: [unit position]];
    }
    
    // attack
    if([unit isDead] || [unit isEvading]) return;
	
	if ( [self isUnitBlacklisted:unit] ){
		PGLog(@"[Combat] Unit %@ blacklisting, stopping attack", unit);
		return;
	}
	
	PGLog(@"Attacking %@", unit);
	
	//PGLog(@"Attacking unit %@ with health %d", unit, [unit currentHealth]);
    if( !isCasting ) {
        
        // ensure unit is our target
        BOOL isFeignDeath = [unit isFeignDeath];
        UInt64 unitUID = [unit GUID];
        if(([playerData targetID] != unitUID) || isFeignDeath) {
            // removed because 'tab' was causing wrong target issues
            //if(!isFeignDeath) {
            //    [chatController tab];
            //    usleep([controller refreshDelay]);
            //}
            
            PGLog(@"[Combat] Targetting %@", unit);
            
            [playerData setPrimaryTarget: unit];
            usleep([controller refreshDelay]);
        }
    }
    
    // tell/remind bot controller to attack
    [botController attackUnit: unit];
    [self performSelector: @selector(attackTheUnit:) withObject: unit afterDelay: 0.25];
}

#pragma mark Blacklist

- (void)invalidTarget: (NSNotification*)notification {
	
	// We should blacklist this guy?
	if ( self.attackUnit ){
		// Check the GUID of what we just attacked!
		
		UInt64 target = [playerData targetID];
		
		//PGLog(@"%qx:%qx", target, [self.attackUnit GUID]);
		
		if ( target == [self.attackUnit GUID] ){
			PGLog(@"[Combat] Target not valid, should I blacklist %@", self.attackUnit);
			
			//[self blacklistUnit: self.attackUnit];
			//[self finishUnit:self.attackUnit];
		}
	}
}

- (void)outOfRange: (NSNotification*)notification {
	
	// We should blacklist this guy?
	if ( self.attackUnit ){
		// Check the GUID of what we just attacked!
		UInt64 target = [playerData targetID];
		
		//PGLog(@"%qx:%qx", target, [self.attackUnit GUID]);
		
		if ( target == [self.attackUnit GUID] ){
			//PGLog(@"[Combat] Out of range, blacklisting %@", self.attackUnit);
			
			//[self blacklistUnit: self.attackUnit];
			//[self finishUnit:self.attackUnit];
		}
	}
}

// target isn't in front of us (we probably did a memory write to face the target + didn't do an establish position)
- (void)errorTargetNotInFront: (NSNotification*)notification {
	
	PGLog(@"errorTargetNotInFront");
	
	// We should blacklist this guy?
	if ( self.attackUnit ){
		PGLog(@"[Combat] Attacking unit with CTM");
		//[movementController setClickToMove:[self.attackUnit position] andType:ctmAttackGuid andGUID:[self.attackUnit GUID]];
		
		// we don't want to KEEP moving backward - lets switch it up a bit!
		if ( _lastWasBackEstablish ){
			[movementController establishPosition];
			_lastWasBackEstablish = NO;
		}
		else{
			[movementController backEstablishPosition];
			_lastWasBackEstablish = YES;
		}
		
		// Check the GUID of what we just attacked!
		UInt64 target = [playerData targetID];
		
		if ( target == [self.attackUnit GUID] ){
			PGLog(@"[Combat] Target %@ isn't in front of us, re-establishing position", self.attackUnit);
		}
	}
}

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
        [self playerLeavingCombat];
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
        [self attackBestTarget: YES];    // attack any eligible target incase we are in trouble
        return;
    } else {
        if(isBlacklisted) {
            PGLog(@"[Combat] Blacklisted unit %@ will not be fought.", unit);
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
    
        if([unit isTappedByOther]) {
            PGLog(@"[Combat] %@ is already tapped.", unit);
            [self blacklistUnit: unit];
            return;
        }
    }
    

    if( ![self.attackUnit isEqualToObject: unit]) {
        if([self addUnitToAttackQueue: unit]) {
            // PGLog(@"[Combat] disposeOfUnit: %@", unit);
            [self attackBestTarget: NO];
        } else {
            [self attackBestTarget: YES];
        }
    }
}

- (void)cancelAllCombat {
    // PGLog(@"[Combat] Clearing all combat state.");
    self.attackUnit = nil;
    [_initialDistances removeAllObjects];
    [_blacklist removeAllObjects];
    [_combatUnits removeAllObjects];
    [_attackQueue removeAllObjects];
	[_unitsAttackingMe removeAllObjects];
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    // [self setInCombat: NO andNotify: NO];
}

#pragma mark Attack

- (void)attackBestTarget: (BOOL)establishPosition {
    if(!self.combatEnabled) return;

    // get the next unit from the attack queue
    Unit *unit = [self getUnitFromAttackQueue];
    if(![unit isValid]) return;
    
    if( ![self.attackUnit isEqualToObject: unit] ) {
    
        if(![playerData isCasting]) {
            [movementController pauseMovement];
            [movementController turnTowardObject: unit];
            usleep( [controller refreshDelay] );
            
            // either move forward or backward
            if(establishPosition) [movementController backEstablishPosition];
            else                  [movementController establishPosition];
        }
        
        // why was I cancelling perform requests after starting the attack?
        
        // cancel previous perform requests
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: self.attackUnit];
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
        
        PGLog(@"[Combat] Commence attack on %@. (0x%x:0x%x)", unit, [unit unitBytes1], [unit unitBytes2]);
        [self attackTheUnit: unit];
        
        // if we aren't in combat after X seconds, something is wrong
        float delay = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"CombatBlacklistDelay"] floatValue];
        [self performSelector: @selector(combatCheck:)
                   withObject: unit
                   afterDelay: delay];
		
        // } else {
        //    PGLog(@"[Combat] Unit %@ moved out of range before attack could begin.", unit);
        //    [self blacklistUnit: unit];
        // }
    } else {
        // we're already attacking this unit
    }
}


- (void)finishUnit: (Unit*)unit {
    if(unit == nil) return;
    
    if([self.attackUnit isEqualToObject: unit]) {
        self.attackUnit = nil;
    }
    
    // make sure the unit sticks around until we're done with it
    [[unit retain] autorelease];
    
    // unregister callbacks to this controller
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(attackTheUnit:) object: unit];
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
    [_initialDistances removeObjectForKey: [NSNumber numberWithUnsignedLongLong: [unit GUID]]];
    
    // remove from the attack queue & combat list
    BOOL wasInAttackQueue = [_attackQueue containsObject: unit];
    [self removeUnitFromAttackQueue: unit];
    [self removeUnitFromCombatList: unit];
    
    // tell the bot controller
    [botController finishUnit: unit wasInAttackQueue: wasInAttackQueue];
}

#pragma mark Data Structure Access

- (float)initialDistanceForUnit: (Unit*)unit {
    NSNumber *key = [NSNumber numberWithUnsignedLongLong: [unit GUID]];
    if( [_initialDistances objectForKey: key] ) {
        return [[_initialDistances objectForKey: key] floatValue];
    }
    return -1;
}

- (Unit*)getUnitFromAttackQueue {
    if([self combatEnabled] && [_attackQueue count]) {
        
        // so, in a perfect world
        // -) players before pets
        // -) low health targets before high health targets
        // -) closer before farther
        // everything needs to be in combatProfile range
        
        // assign 'weights' to each target based on current conditions/settings
        // highest weight unit is out best target
        
        // current target? +25
        // player? +100 pet? +25
        // hostile? +100, neutral? +100
        // health: +(100-percentHealth)
        // distance: 100*(attackRange - distance)/attackRange
        
        //botController.theCombatProfile.attackRange
        //Unit *theUnit = [_attackQueue objectAtIndex: 0];
        //Position *playerPosition = [playerData position];
        //if(botController.theBehavior.meleeCombat) {
            // if we're in melee combat, logically, we should attack something in melee range
            // of the targets in melee range, the lowest health would be the best
        //} else {
            // if we're not in melee combat, we should attack the lowest health target
            // though there should be an emphasis on closer targets
            
            /*for(Unit *unit in _attackQueue) {
                int health = [unit currentHealth];
                if((health > 0) && (health < [theUnit currentHealth])) {
                    theUnit = unit;
                }
            }
            // we come out of this with the unit that has the lowest health
            */
        //}
        
        /*Unit *firstUnit = [_attackQueue objectAtIndex: 0];
        if( [firstUnit isPet] ) {
            GUID owner = [firstUnit summonedBy];
            int ownderIndex = NSNotFound;
            for(Unit *unit in _attackQueue) {
            
            }
        }*/
		
		Unit *attackUnit = [_attackQueue objectAtIndex: 0];
		
		/*for ( Unit *unit in _attackQueue ){
			
			if ( ![unit isPet] && [attackUnit isPet] ){
				PGLog(@"[Combat] Switching from pet %@ to player %@", attackUnit, unit);
				attackUnit = unit;
				break;
			}
		}*/
		
		return attackUnit;
    }
    return nil;
}

- (BOOL)addUnitToAttackQueue: (Unit*)unit {
    if( [unit isValid] && ![unit isDead] && ![_attackQueue containsObject: unit] ) {
        [_attackQueue addObject: unit];
        
        float dist = [[playerData position] distanceToPosition2D: [unit position]];
        [_initialDistances setObject: [NSNumber numberWithFloat: dist] 
                              forKey: [NSNumber numberWithUnsignedLongLong: [unit GUID]]];
        PGLog(@"[Combat] ---> [A] %@ at %.2f", unit, dist);
        
        // if we're supposed to be attacking it, take it off the blacklist
        // [self removeUnitFromBlacklist: unit];     // ...if it's even on it
        return YES;
    } else {
        //PGLog(@"Unit %@ already exists in attack queue.", unit);
        return NO;
    }
}

- (BOOL)removeUnitFromAttackQueue: (Unit*)unit {
    if(unit) {
        PGLog(@"[Combat] <--- [A] %@", unit);
        [_attackQueue removeObject: unit];
        return YES;
    }
    return NO;
}

- (BOOL)addUnitToCombatList: (Unit*)unit {
    if( [unit isValid] && ![unit isDead] && ![_combatUnits containsObject: unit] ) {
        [_combatUnits addObject: unit];
        [self removeUnitFromBlacklist: unit];
        PGLog(@"[Combat] ---> [C] %@ (%d total)", unit, [_combatUnits count]);
        return YES;
    }
    return NO;
}

- (BOOL)removeUnitFromCombatList: (Unit*)unit {
    if(unit) {
        PGLog(@"[Combat] <--- [C] %@", unit);
        [_combatUnits removeObject: unit];
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
// this will find the best unit we are CURRENTLY in combat with
- (Unit*)findBestUnitToAttack{
	
	// is player in combat?
	if ( ![playerData isInCombat] )
		return nil;
	
	// grab all units we're in combat with
	NSMutableArray *units = [NSMutableArray array];
	[units addObjectsFromArray:_unitsAttackingMe];
	
	// sort units by position
	Position *playerPosition = [playerData position];
	[units sortUsingFunction: DistanceFromPositionCmp context: playerPosition];
	
	PGLog(@"Total valid units: %d", [units count]);
	
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
	
	if ( [units count] ){
		float distanceToTarget = 0.0f;
		float attackRange = botController.theCombatProfile.attackRange;
		
		
		for ( Unit *unit in units ){
			distanceToTarget = [playerPosition distanceToPosition:[unit position]];
														 
			// only check targets that are close enough!
			if ( distanceToTarget > attackRange ){
				[_combatDictionaryWithWeights removeObjectForKey:[NSNumber numberWithLongLong:[unit GUID]]];
				continue;
			}
			
			PGLog(@"[Combat] Valid target found %0.2f yards away", distanceToTarget);
			
			// begin weight calculation
			int weight = [self unitWeight:unit PlayerPosition:playerPosition];
			
			PGLog(@"[Combat] Weight: %d for %@", weight, unit);
			
			[_combatDictionaryWithWeights setObject: [NSNumber numberWithInt:weight] forKey: [NSNumber numberWithLongLong:[unit GUID]]];
		}
		
		// grab the unit with the highest weight!
		int highestWeight = 0;
		NSNumber *bestGUID = nil;
		for (NSNumber* guid in _combatDictionaryWithWeights) {
			NSNumber *weight = [_combatDictionaryWithWeights objectForKey:guid];
			if ( [weight intValue] > highestWeight ){
				highestWeight = [weight intValue];
				bestGUID = guid;
			}
		}
	
		PGLog(@"[Combat] Best unit to attack is %@ with a weight of %d", bestGUID, highestWeight);
		
		// return the unit
		UInt64 guid = [bestGUID longLongValue];
		for ( Unit *unit in units ){
			if ( guid == [unit GUID] ){
				return unit;
			}
		}
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
			if ( ![_unitsAttackingMe containsObject: (Unit*)mob] ){
				[_unitsAttackingMe addObject: (Unit*)mob];
			}
		}
		// remove unit
		else if ([_unitsAttackingMe containsObject: (Unit*)mob]){
			[_unitsAttackingMe removeObject:(Unit*)mob];

		}
	}
	
	for ( Player *player in players ){
		unitTarget = [player targetID];
		if (
			![player isDead] &&										// 1 - living units only
			[player currentHealth] != 1 &&							// 2 - this should be a ghost check, being lazy for now
			[player isInCombat] &&									// 3 - in Combat
			[player isSelectable] &&								// 4 - can select this target
			([player isAttackable] || [player isFeignDeath] ) &&	// 5 - attackable or feigned
			[player isValid] &&										// 6 - valid
			(	(unitTarget == playerGUID ||										// 7 - targetting us
				 (playerHasPet && unitTarget == [[playerData player] petGUID]) ) ||	// or targetting our pet
			 [player isFleeing])													// or fleeing
			){
			
			//PGLog(@"[Combat] In combat with player %@", player);
			// add player
			if ( ![_unitsAttackingMe containsObject: (Unit*)player] ){
				[_unitsAttackingMe addObject: (Unit*)player];
			}
		}
		// remove unit
		else if ([_unitsAttackingMe containsObject: (Unit*)player]){
			[_unitsAttackingMe removeObject:(Unit*)player];
			
		}
	}
	
	//PGLog(@"[Combat] In combat with %d units", [_unitsAttackingMe count]);
}

@end
