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

- (void)blacklistObject:(WoWObject *)obj withReason:(int)reason{
	
	PGLog(@"[Blacklist] Obj %@ with retain count %d", obj, [obj retainCount]);
	
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
	
	if ( [_blacklist count] ){
		NSArray *allKeys = [_blacklist allKeys];
		
		for ( NSNumber *guid in allKeys ){
		
			NSArray *infractions = [_blacklist objectForKey:guid];
			NSMutableArray *infractionsToKeep = [NSMutableArray array];
			
			for ( NSDictionary *infraction in infractions ){
				
				//int reason		= [[infraction objectForKey:@"Reason"] intValue];
				NSDate *date	= [infraction objectForKey:@"Date"];
				
				// length varies based on reason
				
				float timeSinceBlacklisted = [date timeIntervalSinceNow] * -1.0f;
				
				if ( timeSinceBlacklisted < BLACKLIST_TIME ){
					[infractionsToKeep addObject:infraction];
				}
				else{
					PGLog(@"[Blacklist] Infraction expired: %@", infraction);
				}
				
				// should we check for dead or alive if they are a player/NPC?  I say NO!
			}
			
			[_blacklist setObject:infractionsToKeep forKey:guid];
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
		
		if ( reason == Reason_None ){
			totalNone++;
		}
		else if ( reason == Reason_NotInLoS ){
			float timeSinceBlacklisted = [date timeIntervalSinceNow] * -1.0f;
			
			// only blacklisted for 5 seconds, since we'll now move, and could potentially get out of LOS?
			if ( timeSinceBlacklisted <= 5.0f ){
				PGLog(@"[Blacklist] LOS , has only been %0.2f seconds", timeSinceBlacklisted);
				totalLos++;
			}
		}
		// fucker made me fall and almost die? Yea, psh, your ass is blacklisted
		else if ( reason == Reason_NodeMadeMeFall ){
			PGLog(@"[Blacklist] Blacklisted %@ for making us fall!", obj);
			return YES;
		}
		else if ( reason == Reason_CantReachObject ){
			totalFailedToReach++;
		}
		else if ( reason == Reason_NotInCombatAfter10 ){
			return YES;
		}
	}
	
	// general blacklisting
	if ( totalNone >= 3 ){
		PGLog(@"[Blacklist] Unit %@ blacklisted for total count!", obj);
		return YES;
	}
	else if ( totalFailedToReach >= 3 ){
		PGLog(@"[Blacklist] Object %@ blacklisted because we couldn't reach it!", obj);
		return YES;
	}
	else if ( totalLos >= 3 ){
	PGLog(@"[Blacklist] Object %@ blacklisted due to LOS!", obj);
		return YES;
	}
	
	PGLog(@"[Blacklist] Not blacklisted but %d infractions", [infractions count]);

    return NO;
}

- (void)clearAll{
	[_blacklist removeAllObjects];
	[_attemptList removeAllObjects];	
}

- (void)removeAllUnits{
	PGLog(@"[Blacklist] Removing all units...");
	
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
	
	PGLog(@"[Blacklist] Removed %d objects of type Unit/Mob/Player", removedObjects);
}

#pragma mark Notifications

- (void)unitDied: (NSNotification*)notification{
	Unit *unit = [notification object];
	
	// remove the object from the blacklist!
	if ( unit ){
		NSNumber *guid = [NSNumber numberWithUnsignedLongLong:[unit GUID]];
	
		if ( [_blacklist objectForKey:guid] )
			[_blacklist removeObjectForKey:guid];
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
	
	PGLog(@"[Blacklist] Incremented to %@ for %@", count, obj);
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
