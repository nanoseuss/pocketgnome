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
        _combatUnits = [[NSMutableArray array] retain];
        _attackQueue = [[NSMutableArray array] retain];
        _blacklist = [[NSMutableArray array] retain];
		_unitsAttackingMe = [[NSMutableArray array] retain];
        _initialDistances = [[NSMutableDictionary dictionary] retain];
        
        //[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerEnteringCombat:) name: PlayerEnteringCombatNotification object: nil];
        //[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playerLeavingCombat:) name: PlayerLeavingCombatNotification object: nil];
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

- (void)attackUnit: (Unit*)unit {
    if(![unit isValid] || [unit isDead]) return;
    
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
        BOOL useSmooth = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"MovementUseSmoothTurning"] boolValue];
        
        if(!isCasting) [movementController pauseMovement];
        [movementController turnToward: [unit position]];
        if(!isCasting && !useSmooth) {
            [movementController backEstablishPosition];
        }
    } else {
        //[playerData faceToward: [unit position]];
    }
    
    // attack
    if([unit isDead] || [unit isEvading]) return;
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
            
            if([unit isNPC])    [mobController selectMob: (Mob*)unit];
            else                [playerData setPrimaryTarget: unitUID];
            usleep([controller refreshDelay]);
        }
    }
    
    // tell/remind bot controller to attack
    [botController attackUnit: unit];
    [self performSelector: @selector(attackUnit:) withObject: unit afterDelay: 0.25];
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
            [movementController turnToward: [unit position]];
            usleep( [controller refreshDelay] );
            
            // either move forward or backward
            if(establishPosition) [movementController backEstablishPosition];
            else                  [movementController establishPosition];
        }
        
        // why was I cancelling perform requests after starting the attack?
        
        // cancel previous perform requests
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: self.attackUnit];
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(combatCheck:) object: unit];
        
        PGLog(@"[Combat] Commence attack on %@.", unit);
        [self attackUnit: unit];
        
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
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(attackUnit:) object: unit];
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
        
        
        return [_attackQueue objectAtIndex: 0];
        
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

// We're going to use this for our Player panel, for now
- (void)doCombatSearch{

	// get list of all targets
    NSMutableArray *targetsWithinRange = [NSMutableArray array];
    
	// add all mobs + players
	[targetsWithinRange addObjectsFromArray: [mobController allMobs]];
	[targetsWithinRange addObjectsFromArray: [playersController allPlayers]];
	[targetsWithinRange addObjectsFromArray: _combatUnits];
	
	// Now that we have all of our mobs/players sorted by range, lets see who is attacking us :-)
	Player *player = [playerData player];
	if ( [targetsWithinRange count] > 0 ){
		for(Unit* unit in targetsWithinRange) {
			GUID targetID = [unit targetID];
			if(   self.inCombat                                                 // if we're in combat
			   && ![playerData isFriendlyWithFaction: [unit factionTemplate]]	// don't display if friendly!
			   && ((targetID > 0) || [unit isFleeing] )                         // if it has SOMETHING targeted or is fleeing
			   && (   (targetID == [player GUID])								// if it has us targeted
				   || ([player hasPet] && (targetID == [player petGUID])))      // ... or our pet
			   ) {
				
				// Only add it if the unit isn't already in here!
				if ( ![_unitsAttackingMe containsObject: unit] ){
					[_unitsAttackingMe addObject: unit];
				}
			}
			// Remove the unit if it's in the array!
			else if ( [_unitsAttackingMe containsObject: unit] ){
				[_unitsAttackingMe removeObject:unit];
			}
		}
	}
}
@end
