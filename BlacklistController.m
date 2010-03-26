//
//  BlacklistController.m
//  Pocket Gnome
//
//  Created by Josh on 12/13/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "BlacklistController.h"
#import "MobController.h"
#import "PlayersController.h"
#import "CombatController.h"

#import "WoWObject.h"
#import "Unit.h"
#import "Player.h"
#import "Mob.h"

// how long should the object remain blacklisted?
#define BLACKLIST_TIME		45.0f
#define BLACKLIST_TIME_LOS		10.0f
// This should be just long enough to move and not instantly retarget the mob
#define BLACKLIST_TIME_NICA_15		2.0f
#define BLACKLIST_TIME_NICA_25		45.0f

@interface BlacklistController (Internal)

@end

@implementation BlacklistController

- (id) init{
    self = [super init];
    if (self != nil) {
		_blacklist = [[NSMutableDictionary alloc] init];
		_attemptList = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(unitDied:) 
                                                     name: UnitDiedNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc{
	[_blacklist release];
    [super dealloc];
}

#pragma mark Blacklisting

- (void)blacklistObject:(WoWObject *)obj withReason:(int)reason {
	
	log(LOG_BLACKLIST, @"Obj %@ with retain count %d", obj, [obj retainCount]);
	
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[obj cachedGUID]];
	NSMutableArray *infractions = [_blacklist objectForKey:guid];
	
	if ( [infractions count] == 0 ){
		infractions = [NSMutableArray array];
	}

	[infractions addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
							  [NSNumber numberWithInt:reason],			@"Reason",
							  [NSDate date],							@"Date", nil]];	
	
	[_blacklist setObject:infractions forKey:guid];
}

// simply add an object to our blacklist!
- (void)blacklistObject: (WoWObject*)obj{
	
	[self blacklistObject:obj withReason:Reason_None];
}

// remove old objects from the blacklist
- (void)refreshBlacklist{
	if ( ![_blacklist count] ) return;
	NSArray *allKeys = [_blacklist allKeys];
		
	for ( NSNumber *guid in allKeys ) {
		
		NSArray *infractions = [_blacklist objectForKey:guid];
		NSMutableArray *infractionsToKeep = [NSMutableArray array];
			
		// Count the Infractions
		for ( NSDictionary *infraction in infractions ){
				
			int reason		= [[infraction objectForKey:@"Reason"] intValue];
			NSDate *date	= [infraction objectForKey:@"Date"];
			float timeSinceBlacklisted = [date timeIntervalSinceNow] * -1.0f;
				
			// length varies based on reason
			if ( reason == Reason_NotInCombatAfter15) {
				if ( timeSinceBlacklisted < BLACKLIST_TIME_NICA_15 ) {
					[infractionsToKeep addObject:infraction];
				} else {
					log(LOG_BLACKLIST, @"Expired: %@", infraction);
				}
			} else
			if ( reason == Reason_NotInCombatAfter25) {
				if ( timeSinceBlacklisted < BLACKLIST_TIME_NICA_25 ) {
					[infractionsToKeep addObject:infraction];
				} else {
					log(LOG_BLACKLIST, @"Expired: %@", infraction);
				}
			} else
			if ( reason == Reason_NotInLoS) {
					if ( timeSinceBlacklisted < BLACKLIST_TIME_LOS ) {
						[infractionsToKeep addObject:infraction];
					} else {
						log(LOG_BLACKLIST, @"Expired: %@", infraction);
					}
			} else {
					if ( timeSinceBlacklisted < BLACKLIST_TIME ) {
						[infractionsToKeep addObject:infraction];
					} else {
						log(LOG_BLACKLIST, @"Expired: %@", infraction);
					}
				}
			}
			
			// Either unblacklist or update the number of infractions
		if ([infractionsToKeep count]) {
			[_blacklist setObject:infractionsToKeep forKey:guid];
		} else {
			log(LOG_BLACKLIST, @"Removing %@", (Unit*)guid);
			[_blacklist removeObjectForKey:guid];
		}
	}
}

- (BOOL)isBlacklisted: (WoWObject*)obj {
	
	// refresh the blacklist (we could do this on a timer to be more "efficient"
	[self refreshBlacklist];
	
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[obj cachedGUID]];
	
	// get the total infractions for this unit!
	NSArray *infractions = [_blacklist objectForKey:guid];
	if ( [infractions count] == 0 ){
		return NO;
	}
	
	// check each infraction, based on the reason we may not care!
	//  making the assumption that ALL infractions are w/in the time frame since we refreshed above
	int totalNone = 0;
	int totalFailedToReach = 0;
	int totalLos = 0;
	for ( NSDictionary *infraction in infractions ){
		
		int reason		= [[infraction objectForKey:@"Reason"] intValue];
		NSDate *date	= [infraction objectForKey:@"Date"];
		float timeSinceBlacklisted = [date timeIntervalSinceNow] * -1.0f;
		
		if ( reason == Reason_NotInLoS && timeSinceBlacklisted <= 5.0f ){
			log(LOG_BLACKLIST, @"%@ was blacklisted for not being in LOS", obj, timeSinceBlacklisted);
			totalLos++;
		}
		// fucker made me fall and almost die? Yea, psh, your ass is blacklisted
		else if ( reason == Reason_NodeMadeMeFall ){
			log(LOG_BLACKLIST, @"%@ was blacklisted for making us fall!", obj);
			return YES;
		}
		else if ( reason == Reason_CantReachObject ){
			totalFailedToReach++;
		}
		else if ( reason == Reason_NotInCombatAfter15 ){
			return YES;
		}
		else if ( reason == Reason_NotInCombatAfter25 ){
			return YES;
		}		
		else{
			totalNone++;
		}
	}
	
	// general blacklisting
	if ( totalNone >= 3 ) {
		log(LOG_BLACKLIST, @"Unit %@ blacklisted for total count!", obj);
		return YES;
	}
	else if ( totalFailedToReach >= 3 ){
		log(LOG_BLACKLIST, @"%@ was blacklisted because we couldn't reach it!", obj);
		return YES;
	}
	/*else if ( totalLos >= 2 ){
		log(LOG_BLACKLIST, @"[Blacklist] Blacklisted due to LOS");
		return YES;
	}*/
	
	log(LOG_BLACKLIST, @"Not blacklisted but %d infractions", [infractions count]);

    return NO;
}

- (void)clearAll{
	[_blacklist removeAllObjects];
	[_attemptList removeAllObjects];
}

- (void)removeAllUnits{
	if ( ![_blacklist count] ) return;
	
	log(LOG_BLACKLIST, @"Removing all units from the blacklist.");
	
	// only remove objects of type Player/Mob/Unit
	NSArray *allKeys = [_blacklist allKeys];
	int removedObjects = 0;
	for ( NSNumber *num in allKeys ){
		
		Mob *mob = [mobController mobWithGUID:[num unsignedLongLongValue]];
		if ( mob ){
			[_blacklist removeObjectForKey:num];
			continue;
		}
		
		Player *player = [playersController playerWithGUID:[num unsignedLongLongValue]];
		if ( player ){
			[_blacklist removeObjectForKey:num];
		}
	}
	
	log(LOG_BLACKLIST, @"Removed %d units.", removedObjects);
}

- (void)removeUnit: (Unit*)unit{
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit GUID]];

	if ( [_blacklist objectForKey:guid] ) {
		log(LOG_BLACKLIST, @"Removing %@ from blacklist.", unit);
		[_blacklist removeObjectForKey:guid];
	}
}

#pragma mark Notifications

- (void)unitDied: (NSNotification*)notification{
	Unit *unit = [notification object];
	
	// remove the object from the blacklist!
	if ( unit ){
		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit GUID]];
		if ( [_blacklist objectForKey:guid] ) {
			log(LOG_BLACKLIST, @"%@ died, removing from blacklist.", unit);
			[_blacklist removeObjectForKey:guid];
		}
	}
}

#pragma mark Attempts

- (int)attemptsForObject:(WoWObject*)obj{
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[obj cachedGUID]];
	NSNumber *count = [_attemptList objectForKey:guid];
	if ( count ){
		return [count intValue];
	}
	
	return 0;
}

- (void)incrementAttemptForObject:(WoWObject*)obj{
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[obj cachedGUID]];
	NSNumber *count = [_attemptList objectForKey:guid];
	if ( count ){
		count = [NSNumber numberWithInt:[count intValue] + 1];
	}
	else{
		count = [NSNumber numberWithInt:1];
	}
	
	log(LOG_BLACKLIST, @"Incremented to %@ for %@", count, obj);
	[_attemptList setObject:count forKey:guid];
}

- (void)clearAttemptsForObject:(WoWObject*)obj{
	NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[obj cachedGUID]];
	[_attemptList removeObjectForKey:guid];
}

- (void)clearAttempts{
	[_attemptList removeAllObjects];
}

@end
